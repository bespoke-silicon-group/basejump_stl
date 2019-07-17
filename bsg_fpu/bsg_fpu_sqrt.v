// -------------------------------------------------------
// -- bsg_fpu_sqrt.v
// sqlin16@fudan.edu.cn 07/10/2019
// -------------------------------------------------------
// This module performs square root on floating numbers with radix equals to 2.
// And at present subnormalized floating number is not supported. 

module bsg_fpu_sqrt 
  import bsg_fpu_pkg::*;
#(
  parameter integer e_p = "inv"
  ,parameter integer m_p = "inv"
  ,parameter bit debug_p = 0
  ,localparam integer width_lp = e_p + m_p + 1
)(
  input clk_i
  ,input reset_i

  ,input [width_lp-1:0] opr_i
  ,input v_i
  ,output ready_o

  ,output logic [width_lp-1:0] result_o
  ,output v_o
  ,input yumi_i
  // status
  ,output unimplemented_o
  ,output invalid_o
  ,output overflow_o
  ,output underflow_o
);

typedef enum {eIdle, ePrep, eCal, eAdj, eDone, eError} state_e;

state_e state_r;

logic error_occurs;
wire sqrt_v_o;
// FSM 
always_ff @ (posedge clk_i) begin
  if(reset_i) begin
    state_r <= eIdle;
  end
  else unique case(state_r)
    eIdle: if (v_i) state_r <= error_occurs ? eError : ePrep;
    ePrep: if(error_occurs) state_r <= eError; else state_r <= eCal;
    eCal: if(error_occurs) state_r <= eError;
      else if(sqrt_v_o) state_r <= eAdj; 
    eAdj: if(error_occurs) state_r <= eError; else state_r <= eDone;
    eDone: if(yumi_i) state_r <= eIdle; 
    eError: if(yumi_i) state_r <= eIdle;
    default: begin

    end
  endcase
end
// Preprocessing 
wire [width_lp-1:0] a_i = opr_i;
logic zero_o,nan_o,sig_nan_o,infty_o,exp_zero_o,man_zero_o,denormal_o, sign_o;
logic [e_p-1:0] exp_o;
logic [m_p-1:0] man_o;

bsg_fpu_preprocess #(
  .e_p(e_p)
  ,.m_p(m_p)
) ops_process (.*);

// Checking errors 

typedef enum {
  eSubnormal
  ,eNan
  ,eOverflow 
  ,eInvalid
  ,eZero
  ,eNone 
} error_e;

error_e error_r;

always_ff @ (posedge clk_i) begin
  if(reset_i) error_r <= eNone;
  else if(state_r == eIdle && v_i) begin
    if(zero_o) error_r <= eZero;
    else if(denormal_o) error_r <= eSubnormal;
    else if(nan_o) error_r <= eNan;
    else if(infty_o) error_r <= eOverflow;
    // and negative number can not be square rooted.
    else if(sign_o) error_r <= eInvalid;
    else error_r <= eNone;
  end
end

reg [e_p-1:0] exp_r;
reg [m_p+1:0] mant_r;

wire [m_p+1:0] sqrt_o;

localparam exp_bias_lp = (1 << (e_p - 1)) - 1;

always_ff @ (posedge clk_i) begin
  if(reset_i) begin
    exp_r <= '0;
    mant_r <= '0;
  end
  else unique case(state_r)
    eIdle: if (v_i) begin
      exp_r <= exp_o;
      mant_r <= {2'b01, man_o};
    end
    ePrep: 
      if(~exp_r[0]) begin
        exp_r <= (exp_r >> 1) + (exp_bias_lp >> 1); 
        mant_r <= mant_r << 1;
      end
      else begin
        exp_r <= (exp_r >> 1) + (exp_bias_lp >> 1) + 1; 
      end
    eCal: begin
      if(sqrt_v_o) begin
        mant_r <= sqrt_o;
      end
    end
    eAdj: begin // Rounding
      if(mant_r[0])  begin
        if(mant_r[m_p+1:1] == '1)
          exp_r <= exp_r + 1;
        mant_r[m_p+1:1] <= mant_r[m_p+1:1] + 1;
      end
    end
  endcase
end

logic core_kill = v_o;
wire [m_p+2:0] sqrt_ops = {mant_r, 1'b0};

bsg_sqrt_core #(
  .width_p(m_p+1)
  ,.debug_p(debug_p)
) core (
  .clk_i(clk_i)
  ,.reset_i(reset_i | core_kill)
  ,.op_i(sqrt_ops)
  ,.v_i(state_r == eCal)
  ,.ready_o()

  ,.sqrt_o(sqrt_o)
  ,.v_o(sqrt_v_o)
  ,.yumi_i(1'b1)
);

assign v_o = (state_r == eDone || state_r == eError); 
assign ready_o = state_r == eIdle;
always_comb unique case(error_r)
  eZero: result_o = `BSG_FPU_ZERO(1'b0, e_p,m_p);
  eInvalid: result_o = `BSG_FPU_QUIETNAN(e_p,m_p);
  eNan: result_o = `BSG_FPU_SIGNAN(e_p,m_p);
  eOverflow: result_o = `BSG_FPU_INFTY(1'b0, e_p, m_p);
  eSubnormal: result_o = `BSG_FPU_QUIETNAN(e_p,m_p);
  default: result_o = {1'b0, exp_r[e_p-1:0], mant_r[m_p:1]};
endcase

assign underflow_o = error_r == eSubnormal;
assign invalid_o = error_r == eInvalid;
assign overflow_o = error_r == eOverflow;
assign underflow_o = 1'b0;

if(debug_p)
  always_ff @ (posedge clk_i) begin
    $display("======== BSG FPU SQRT========");
    $display("state_r:%s",state_r.name());
    $display("mant_r:%b",mant_r);
    $display("exp_r:%b",exp_r);
  end

endmodule
