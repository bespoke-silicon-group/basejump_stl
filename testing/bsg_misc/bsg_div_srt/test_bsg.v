/*
TEST RATIONALE
1. STATE SPACE
1000 groups of random signed operands.
2.PARAMETERIZATION
width_p = 32
*/

module test_bsg;

  localparam integer width_p = 32;
  localparam once = 0;
  localparam logic [2*width_p-1:0] dividend_specific = 64'b1111111111111111111111111111111111100010111101111000010011000101;
  localparam logic [width_p-1:0] divisor_specific = 32'b11010101000100111101001010101010;

  logic clk_i;
  logic reset_i;

  logic ready_o;
  logic v_i;

  logic signed [2*width_p-1:0] dividend_i;
  logic signed [width_p-1:0] divisor_i;
  logic signed_i;

  logic [width_p-1:0] quotient_o;
  logic [width_p-1:0] remainder_o;

  wire [width_p-1:0] sys_quo = dividend_i / divisor_i;
  wire [width_p-1:0] sys_rem = dividend_i % divisor_i;

  logic v_o;

  logic error_o;
  logic error_type_o;

  logic yumi_i;

  logic yumi_error_i;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(50)
  )clk_gen(
    .o(clk_i)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(1)
    ,.reset_cycles_hi_p(5)
  )rst_gen(
    .clk_i(clk_i)
    ,.async_reset_o(reset_i)
  );

  bsg_div_srt #(
    .width_p(width_p)
    ,.debug_p(once)
  )div_srt(
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.ready_o(ready_o)
    ,.v_i(v_i)
    ,.dividend_i(dividend_i)
    ,.divisor_i(divisor_i)
    ,.signed_i(signed_i)

    ,.quotient_o(quotient_o)
    ,.remainder_o(remainder_o)

    ,.v_o(v_o)

    ,.error_o(error_o)
    ,.error_type_o(error_type_o)

    ,.yumi_i(yumi_i)
  );
  integer i = 0;
  integer success = 0, overflow = 0;
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      v_i <= 1'b1;
      if(once) begin
        dividend_i <= dividend_specific;
        divisor_i <= divisor_specific;
      end
      else begin
        dividend_i <= $random;
        divisor_i <= $random;
      end
      signed_i <= 1'b1;
      yumi_i <= 1'b1;
      yumi_error_i <= 1'b1;
    end
    else if(v_o) begin
      
      $display("Turn %d",i);
      
      if(sys_quo == quotient_o && sys_rem == remainder_o) begin
        i = i + 1;
        dividend_i <= ($random);
        divisor_i <= $random;
        success = success + 1;
        if(once) $finish;
      end
      else begin
        $display("Result Error!");
        $display("%b / %b\n sys_q:%b, sys_r:%b\n selfq:%b, selfr:%b",dividend_i,divisor_i,sys_quo,sys_rem,quotient_o,remainder_o);
        $finish;
      end
      
      //$display("%b / %b\n sys_q:%b, sys_r:%b\n selfq:%b, selfr:%b",dividend_i,divisor_i,sys_quo,sys_rem,quotient_o,remainder_o);
      //$finish;
    end
    else if(error_o) begin
      if(error_type_o) begin
        $display("%b / %b\n sys_q:%b, sys_r:%b\n selfq:%b, selfr:%b",dividend_i,divisor_i,sys_quo,sys_rem,quotient_o,remainder_o);
        $display("overflow!");
        overflow = overflow + 1;
        if (once) $finish;
        //$finish;
      end
      else begin
        $display("divisor is zero!");
        $display("%b / %b\n sys_q:%b, sys_r:%b\n selfq:%b, selfr:%b",dividend_i,divisor_i,sys_quo,sys_rem,quotient_o,remainder_o);
      end
      i = i + 1;
      dividend_i <= ($random);
      divisor_i <= $random;
    end
    if(i == 60000) begin
      $display("All passed!");
      $display("Success:%d, Overflow:%d",success,overflow);
      $finish;
    end
  end
endmodule
