// -------------------------------------------------------
// --  bsg_fpu_div.v
// 
// sqlin16@fudan.edu.cn  05/07/2019
// -------------------------------------------------------
// This is a parameterized floating point divider, using integer SRT divider to perform division.


module bsg_fpu_div #(
  parameter integer e_p = "inv"
  ,parameter integer m_p = "inv"
  ,localparam integer width_lp = e_p + m_p + 1
  ,parameter bit debug_p = 1
)(
  input clk_i
  ,input reset_i
  ,output ready_o
  
  ,input [width_lp-1:0] dividend_i
  ,input [width_lp-1:0] divisor_i
  ,input v_i

  ,output logic [width_lp-1:0] result_o
  ,output v_o
  ,input yumi_i

  // result information
  ,output logic unimplemented_o // subnormal floating point number.
  ,output logic invalid_o
  ,output logic overflow_o
  ,output logic underflow_o
  ,output logic divisor_is_zero_o
);

typedef enum {eIdle, eCal, eRound, eJudge, eDone} state_e;
typedef enum {eNormal, eINF, eNan, eSubnormal, eUnderflow, eZero, eOverflow, eInvalid, eDivisorZero} exception_e;

localparam integer e_bias_lp = (1 << (e_p-1)) - 1;

state_e state_r, state_n;
exception_e exception_n, exception_r;

logic inf_occur; // result is inf
logic nan_occur; // result is nan
logic subnormal_occur; // one of operands is subnormal
logic underflow_occur; // Result is zero because of negative exponents
logic zero_occur; // result is zero
logic invalid_op_occur;
logic overflow_occur;
logic div_srt_error;

wire reset_internal = reset_i | (state_r == eDone & yumi_i);
wire div_v_o; // SRT divider is ready

always_comb unique case(state_r)
  eIdle: begin
    if(v_i) state_n = eCal;
    else state_n = eIdle;
  end
  eJudge: begin
    state_n = eDone;
  end
  eCal: begin
    if(div_v_o) state_n = eRound;
    else state_n = eCal;
  end
  eRound: begin
    state_n = eJudge;
  end
  eDone: begin
    state_n = eDone;
  end
endcase

always_ff @(posedge clk_i) begin
  if(reset_internal) state_r <= eIdle;
  else state_r <= (exception_r == eNormal & !div_srt_error) ? state_n : eDone;
end

logic divisor_is_zero;

// Exception propagation
always_comb begin
  if(invalid_op_occur) exception_n = eInvalid;
  else if(divisor_is_zero) exception_n = eDivisorZero;
  else if(inf_occur) exception_n = eINF;
  else if(nan_occur) exception_n = eNan;
  else if(subnormal_occur) exception_n = eSubnormal;
  else if(underflow_occur & state_r == eRound) exception_n = eUnderflow;
  else if(zero_occur) exception_n = eZero;
  else if(overflow_occur & state_r == eRound) exception_n = eOverflow;
  else exception_n = eNormal;
end 

always_ff @(posedge clk_i) begin
  if(reset_internal) exception_r <= eNormal;
  else if(state_r == eIdle & v_i || state_r == eRound) exception_r <= exception_n;
end

// prefix s denotes dividend and prefix d marks divisor.

wire s_sign, d_sign;
wire s_denor, d_denor; 
wire s_inf, d_inf;
wire s_nan, d_nan;
wire s_zero, d_zero;
wire [e_p-1:0] dividend_exponent_n;
wire [e_p-1:0] divisor_exponent_n;
wire [m_p-1:0] dividend_mantissa_n;
wire [m_p-1:0] divisor_mantissa_n;

bsg_fpu_preprocess #( 
  .e_p(e_p)
  ,.m_p(m_p)
)
pre_dividend
(
  .a_i(dividend_i)
  ,.zero_o(s_zero)
  ,.nan_o(s_nan)
  ,.sig_nan_o()
  ,.infty_o(s_inf)
  ,.exp_zero_o()
  ,.man_zero_o()
  ,.denormal_o(s_denor)
  ,.sign_o(s_sign)
  ,.exp_o(dividend_exponent_n)
  ,.man_o(dividend_mantissa_n)
);

bsg_fpu_preprocess #(
  .e_p(e_p)
  ,.m_p(m_p)
)
pre_divisor
(
  .a_i(divisor_i)
  ,.zero_o(d_zero)
  ,.nan_o(d_nan)
  ,.sig_nan_o()
  ,.infty_o(d_inf)
  ,.exp_zero_o()
  ,.man_zero_o()
  ,.denormal_o(d_denor)
  ,.sign_o(d_sign)
  ,.exp_o(divisor_exponent_n)
  ,.man_o(divisor_mantissa_n)
);


localparam integer divider_width_lp = m_p[0] & 1'b1 ? m_p + 5 : m_p + 4; // width of srt divider must be even.

reg [e_p+1:0] result_exponent_r;
reg [divider_width_lp:0] result_mantissa_r;
reg           result_sign_r;


logic[e_p+1:0] result_exponent_acc_op;
wire [e_p+1:0] result_exponent_n = result_exponent_r + result_exponent_acc_op;



// output of srt divider
wire [divider_width_lp+2:0] div_quotient_li;
wire [m_p:0] round_out;


always_comb begin
  if(state_r == eIdle & v_i)
    result_exponent_acc_op = dividend_exponent_n - divisor_exponent_n;
  else if(state_r == eCal & div_v_o & ~div_quotient_li[divider_width_lp])
    result_exponent_acc_op = '1;
  else 
    result_exponent_acc_op = '0;
end

always_ff @(posedge clk_i) begin
  if(reset_internal) begin
    result_exponent_r <= (e_p+2)'(e_bias_lp);
    result_mantissa_r <= '0;
    result_sign_r <= '0;
  end
  else if(state_r == eIdle & v_i) begin
    result_sign_r <= s_sign ^ d_sign;
    result_exponent_r <= result_exponent_n;
  end
  else if(state_r == eCal & div_v_o) begin
    result_mantissa_r <= div_quotient_li[divider_width_lp:0];
    result_exponent_r <= result_exponent_n; 
  end
  else if(state_r == eRound) begin
    result_mantissa_r[divider_width_lp-:m_p] <= round_out[m_p-1:0];
    if(debug_p)
      if(round_out[m_p] != 1'b1) $warning("Quotient is not correct as expected! If overflow/underflow occurs, please ignore this message.");
  end
end


always_comb unique case(exception_r)
  eNormal:
    result_o = {result_sign_r, result_exponent_r[e_p-1:0], result_mantissa_r[divider_width_lp-:m_p]};
  eINF:
    result_o = `BSG_FPU_INFTY(result_sign_r, e_p, m_p);
  eUnderflow:
    result_o = `BSG_FPU_ZERO(result_sign_r, e_p, m_p);
  eInvalid:
    result_o = `BSG_FPU_SIGNAN(e_p, m_p);
  eOverflow:
    result_o = `BSG_FPU_INFTY(result_sign_r, e_p, m_p);
  eZero:
    result_o = `BSG_FPU_ZERO(result_sign_r, e_p, m_p);
  eNan:
    result_o = `BSG_FPU_QUIETNAN(e_p, m_p);
  eSubnormal:
    result_o = `BSG_FPU_QUIETNAN(e_p, m_p);
  default:
    result_o = `BSG_FPU_QUIETNAN(e_p, m_p);
endcase

assign unimplemented_o = exception_r == eSubnormal;
assign overflow_o = exception_r == eOverflow;
assign underflow_o = exception_r == eUnderflow;
assign invalid_o = exception_r == eInvalid;

// exception signal
assign inf_occur =  s_inf & ~d_inf & ~d_nan | // dividend is inf, divisor is not inf
                    d_zero & ~ s_nan; // dividend is non-zero, divisor is zero.
assign nan_occur =  s_inf & d_inf | s_zero & d_zero | s_nan | d_nan;
assign subnormal_occur = s_denor | d_denor;
// Condition when exponent of result is all zero means a subnormal operand get involved or the result is a subnormal number.
// We treat it as underflow/overflow until subnormal number can be handled.
assign underflow_occur = result_exponent_r[e_p+1] | result_exponent_r == '0; 
assign overflow_occur = result_exponent_r[e_p] | result_exponent_r[e_p-1:0] == '1;

assign invalid_op_occur = s_inf & d_inf | s_zero & d_zero;
assign divisor_is_zero = d_zero;

assign zero_occur = s_zero & ~ d_zero;

wire div_v_li = state_r == eIdle & v_i;

wire [2*divider_width_lp+3:0] div_dividend_li = {3'b001, dividend_mantissa_n,{2*divider_width_lp + 1 - m_p{1'b0}}};
wire [divider_width_lp+1:0]  div_divisor_li = {1'b1, divisor_mantissa_n,{divider_width_lp + 1 - m_p{1'b0}}};

bsg_div_srt #(
  .width_p(divider_width_lp+2)
  ,.for_floating_point_p(1)
  ,.debug_p(debug_p)
) srt_div (
  .clk_i(clk_i)
  ,.reset_i(reset_i | state_r == eDone)
  ,.ready_o()
  ,.v_i(div_v_li)

  ,.dividend_i(div_dividend_li)
  ,.divisor_i(div_divisor_li)

  ,.signed_i(1'b0)

  ,.quotient_o(div_quotient_li)
  ,.remainder_o()
  ,.v_o(div_v_o)

  ,.error_o(div_srt_error)
  ,.error_type_o()

  ,.yumi_i()
  ,.yumi_error_i()
);

wire [divider_width_lp:0] round_input = result_mantissa_r[divider_width_lp] ? result_mantissa_r : {result_mantissa_r[divider_width_lp-1:0], result_mantissa_r[0]}; // sticky bit

bsg_fpu_round #(
  .width_i_p(divider_width_lp+1)
  ,.width_o_p(m_p+1)
) rounder (
  .type_i(bsg_fpu_pkg::eRtne)
  ,.mantissa_i(round_input)
  ,.sign_i(result_sign_r)
  ,.mantissa_o(round_out)
);

assign ready_o = state_r == eIdle;
assign v_o = state_r == eDone;
assign divisor_is_zero_o = state_r == eDivisorZero;

if(debug_p)
  always_ff @(posedge clk_i) begin
    $display("=========== BSG FPU DIV ===========");
    $display("dividend:%b",dividend_i);
    $display("dividend exp:%b",dividend_exponent_n);
    $display("dividend mantissa :%b",dividend_mantissa_n);

    $display("divisor:%b",divisor_i);
    $display("divisor exp:%b",divisor_exponent_n);
    $display("divisor mantissa :%b",divisor_mantissa_n);

    $display("state_r:%s",state_r.name());
    $display("exception:%s",exception_r.name());
    $display("exception_n:%s",exception_n.name());

    $display("Result sign:%b",result_sign_r);
    $display("Result sign should be:%b", d_sign ^ s_sign);
    $display("Result Mantissa:%b",result_mantissa_r);
    $display("Result Exponent:%b",result_exponent_r);
    $display("reset_internal:%b",reset_i);
    $display("div_quotient_li:%b",div_quotient_li);
    $display("div_srt_error:%b",div_srt_error);
  end

endmodule
