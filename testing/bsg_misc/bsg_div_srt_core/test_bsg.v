// -------------------------------------------------------
// -- Testbench for bsg_div_srt_core
// -------------------------------------------------------
// 1. Test Rationale
//   6000 random 32bit test
//   With signed and unsigned
// 2. Parameterization
//    width_p = 8 and 32
// This test file is used for 60000 random 32bit test.
// -------------------------------------------------------

module test_bsg;
  localparam logic signed_test = 1;
  localparam integer width_p = 8;
  localparam once = 0;
  localparam logic [2*width_p-1:0] dividend_given = 16'b1011111110010100;
  localparam logic [width_p-1:0] divisor_given = 8'b10000100;

  logic clk_i;
  logic reset_i;

  logic ready_o;
  logic v_i;

  logic signed [2*width_p-1:0] dividend_i;
  logic signed [width_p-1:0] divisor_i;

  logic signed_i;

  logic [width_p:0] quotient_o;
  logic [width_p-1:0] remainder_o;

  wire [width_p:0] sys_quo = dividend_i / divisor_i;
  wire [width_p-1:0] sys_rem = dividend_i % divisor_i;

  logic v_o;

  logic yumi_i;


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

  bsg_div_srt_core #(
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


    ,.yumi_i(yumi_i)
  );
  integer i = 0;
  logic divisor_sign = 0;
  integer success = 0, overflow = 0;
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      v_i <= 1'b1;
      if(once) begin
        dividend_i <= dividend_given;
        divisor_i <= divisor_given;
      end
      else begin
        if(signed_test) begin
          dividend_i <= $random;
          divisor_sign = $random;
          divisor_i <= {divisor_sign, ~divisor_sign,(width_p-2)'($random)};
        end
        else begin
          dividend_i <= $random;
          divisor_i <= {1'b1,(width_p-1)'($random)};
        end
      end
      signed_i <= signed_test;
      yumi_i <= 1'b1;
    end
    else if(v_o) begin
      
      $display("Turn %d",i);
      
      if(sys_quo == quotient_o && sys_rem == remainder_o) begin
        if(once)
          $finish;
        if(signed_test) begin
          dividend_i <= $random;
          divisor_sign = $random;
          divisor_i <= {divisor_sign, ~divisor_sign,(width_p-2)'($random)};
        end
        else begin
          dividend_i <= $random;
          divisor_i <= {1'b1,(width_p-1)'($random)};
        end
        i = i + 1;
      end
      else begin
        $display("Result Error!");
        $display("%b / %b\n sys_q:%b, sys_r:%b\n selfq:%b, selfr:%b",dividend_i,divisor_i,sys_quo,sys_rem,quotient_o,remainder_o);
        $display("Success:%d, Overflow:%d",success,overflow);
        $finish;
      end
    end
    if(i == 60000) begin
      $display("All passed!");
      $display("Success:%d, Overflow:%d",success,overflow);
      $finish;
    end
  end
endmodule
