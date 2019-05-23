/*
======================
bsg_div_srt.v
04/16/2019 sqlin16@fudan.edu.cn
=====================
A radix-4 SRT divider using carry save addition to store intermittent remainder.

Latency = 5 + (width_p / 2) (cycle)
Throughput = 1 / (6 + (width_p / 2)) (cycle^-1)

*/

module bsg_div_srt #(
  parameter integer width_p = "inv"
  ,parameter bit debug_p = 0
)(

  input clk_i
  ,input reset_i
  
  //handshake signal
  ,output ready_o
  ,input v_i

  ,input [2*width_p-1:0] dividend_i
  ,input [width_p-1:0] divisor_i
  ,input signed_i

  ,output [width_p-1:0] quotient_o
  ,output [width_p-1:0] remainder_o

  ,output v_o

  ,output error_o
  ,output error_type_o // 0: divisor is zero, 1: result is overflow

  ,input yumi_i       // accept result and error
);

typedef enum logic [1:0]  {eIDLE, eSHIFT, eDONE, eERROR} state_e;

state_e state_r;
reg error_type_r;
wire divisor_sign_bit = signed_i & divisor_i[width_p-1];
wire dividend_sign_bit = signed_i * dividend_i[2*width_p-1];

logic [`BSG_SAFE_CLOG2(width_p):0] divisor_leading_zero;
reg [`BSG_SAFE_CLOG2(width_p):0] divisor_leading_zero_r;
logic [`BSG_SAFE_CLOG2(width_p):0] dividend_leading_zero;

// whether div_srt_core is ready for data input.
logic core_is_ready;
logic core_is_done;
// output quotient
logic [width_p:0] quotient_lo;

reg signed_r;

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    state_r <= eIDLE;
    error_type_r <= '0;
    signed_r <= '0;
    divisor_leading_zero_r <= '0;
  end
  else unique case(state_r) 
    eIDLE: if(v_i & core_is_ready) begin
      if(divisor_i[width_p-2:0] == '0 & !divisor_i[width_p-1:0]) begin // divisor is zero
        state_r <= eERROR;
        error_type_r <= '0;
      end
      else if(divisor_leading_zero > dividend_leading_zero) begin // overflow
        state_r <= eERROR;
        error_type_r <= '1;
      end
      else begin
        state_r <= eSHIFT;
        signed_r <= signed_i;
        error_type_r <= '0;
        divisor_leading_zero_r <= divisor_leading_zero;
      end
    end
    eSHIFT: if(core_is_done) begin
      if(quotient_lo[width_p] != quotient_lo[width_p-1] & signed_r | ~signed_r & ~quotient_lo[width_p]) begin // overflow!
        state_r <= eERROR;
        error_type_r <= '1;
      end
      else
        state_r <= eDONE; // Finished!
    end
    // eDONE and eERROR
    default: begin
      if(yumi_i) state_r <= eIDLE;
    end
  endcase
end

wire [`BSG_SAFE_CLOG2(width_p)-1:0] divisor_clz_out;

bsg_counting_leading_zeros #(
  .width_p(width_p)
) clz_divisor (
  .a_i(divisor_i ^ {width_p{divisor_sign_bit}})
  ,.num_zero_o(divisor_clz_out)
);

wire [`BSG_SAFE_CLOG2(width_p)-1:0] dividend_clz_out;

bsg_counting_leading_zeros #(
  .width_p(width_p)
) clz_dividend (
  .a_i(dividend_i[2*width_p-1:width_p] ^ {width_p{dividend_sign_bit}})
  ,.num_zero_o(dividend_clz_out)
);
/*
  Leading Zero Counting process.
  1. For unsigned number, if divisor's leading zero is greater than dividend, overflow error occurs.
  2. For signed number, preprocessing depends on the divisor/dividend:
    '0: overflow error
    {1'b,'0}: leading zero is zero
    {1'b, '1}: leading zero is (width_p-1)
*/

// determine of divisor leading zero
always_comb begin
  if(divisor_sign_bit) begin
    if(divisor_i[width_p-2:0] == '1)
      divisor_leading_zero = width_p-1;
    else if(dividend_i[width_p-2:0] == '0)
      divisor_leading_zero = '0;
    else
      divisor_leading_zero = divisor_clz_out;
  end
  else 
    divisor_leading_zero = divisor_clz_out;
end

// determine of dividend leading zero, which is same:

always_comb begin
  if(dividend_sign_bit) begin
    if(dividend_i[2*width_p-2:width_p] == '1)
      dividend_leading_zero = width_p;
    else if(dividend_i[2*width_p-2:width_p] == '0)
      dividend_leading_zero = '0;
    else
      dividend_leading_zero = dividend_clz_out;
  end
  else
    if(dividend_i[2*width_p-2:width_p] == '0 & ~dividend_i[2*width_p-1])
      dividend_leading_zero = width_p;
    else
      dividend_leading_zero= dividend_clz_out;
end

logic [width_p-1:0] remainder_lo;
wire remainder_sign_bit = signed_r & remainder_lo[width_p-1];

bsg_div_srt_core #(
  .width_p(width_p)
  ,.debug_p(debug_p)
) srt_core (
  .clk_i(clk_i)
  ,.reset_i(reset_i)
  ,.ready_o(core_is_ready)
  ,.v_i(v_i)

  ,.dividend_i(dividend_i << (divisor_leading_zero-1))
  ,.divisor_i(divisor_i << (divisor_leading_zero))
  ,.signed_i(signed_i)

  ,.quotient_o(quotient_lo)
  ,.remainder_o(remainder_lo)

  ,.v_o(core_is_done)

  ,.yumi_i(yumi_i)

);

assign quotient_o = quotient_lo[width_p-1:0];

reg [width_p-1:0] remainder_r;
// update remainder
always_ff @(posedge clk_i) begin
  if(reset_i) remainder_r <= '0;
  else if(state_r == eSHIFT & core_is_done) begin
    remainder_r <= {remainder_lo >> (divisor_leading_zero_r-1)} | {width_p{remainder_sign_bit}} << (width_p-divisor_leading_zero_r + 1);
  end
end

assign remainder_o = remainder_r;
assign error_o = state_r == eERROR;
assign v_o = state_r == eDONE;
assign error_type_o = error_type_r;
assign ready_o = state_r == eIDLE;

if(debug_p) 
  always_ff @(posedge clk_i) begin
    $display("======== FROM DIV SRT ========");
    $display("divisor_leading_zero:%d",divisor_leading_zero);
    $display("dividend_leading_zero:%d",dividend_leading_zero);
    $display("divisor_li:%b",divisor_i << (divisor_leading_zero));
    $display("dividend_li:%b",dividend_i << (divisor_leading_zero));
    $display("remainder_lo:%b",remainder_lo);
    $display("remainder_sign_bit:%b",remainder_sign_bit);
    $display("signed_r:%b",signed_r);
  end

endmodule

