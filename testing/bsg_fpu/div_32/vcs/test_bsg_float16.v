/*
TEST RATIONALE

1. STATE SPACE
  - exhaustive test with half-precision number. subnormal condition is ignored.
2. PARAMETERIZATION
  - e_p = 5, m_p = 11

This testing file is for VCS.
*/


module bsg_fpu_div_half;

import "DPI-C" function int performFloat16Division(input shortint dividend, input shortint divisor, input shortint result, input int unimplemented, input int overflow, input int underflow, input int invalid, input int divisor_is_zero);

import "DPI-C" function void pause();

import "DPI-C" function shortint getDivisionResult(input shortint div_in, input shortint divisor_in);

localparam bit once = 0;
localparam logic [15:0] dividend_given = 0;
localparam logic [15:0] divisor_given = 32768;

logic clk_i, reset_i, ready_o, v_i, v_o, unimplemented_o, invalid_o, overflow_o, underflow_o, divisor_is_zero_o;

logic [15:0] dividend_i;
logic [15:0] divisor_i;
logic [15:0] result_o;

bsg_nonsynth_clock_gen #(
  .cycle_time_p(50)
)clk_gen(
  .o(clk_i)
);

bsg_nonsynth_reset_gen #(
  .reset_cycles_lo_p(1)
  ,.reset_cycles_hi_p(5)
) rst_gen (
  .clk_i(clk_i)
  ,.async_reset_o(reset_i)
);

bsg_fpu_div #(
  .e_p(5)
  ,.m_p(10)
  ,.debug_p(once)
  ,.rounding_p(bsg_fpu_pkg::eInward)
) fp32_div (
  .clk_i(clk_i)
  ,.reset_i(reset_i)

  ,.ready_o(ready_o)
  ,.dividend_i(dividend_i)
  ,.divisor_i(divisor_i)
  ,.v_i(v_i)

  ,.result_o(result_o)
  ,.v_o(v_o)
  ,.yumi_i(1'b1)

  ,.unimplemented_o(unimplemented_o)
  ,.invalid_o(invalid_o)
  ,.overflow_o(overflow_o)
  ,.underflow_o(underflow_o)
  ,.divisor_is_zero_o(divisor_is_zero_o)
);

integer i = 60102;
integer j = 0;

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    if(once) begin
      dividend_i <= dividend_given;
      divisor_i <= divisor_given;
    end
    else begin
      dividend_i <= '0;
      divisor_i <= '0;
    end
    v_i <= '1;
  end 
  else begin
    if(v_o) begin
      // do compare
      if(performFloat16Division(dividend_i, divisor_i, result_o, unimplemented_o, overflow_o, underflow_o, invalid_o, divisor_is_zero_o)) begin
        // pass
        //$display("dividend = %d, divisor = %d passed!",dividend_i, divisor_i);
        dividend_i <= i;
        divisor_i <= j;
        if(j == 65535) begin
          j = 0;
          i = i + 1;
          $display("Test i = %d is done.",i);
          if(i == 0) $finish;
        end
        else
          j = j + 1;
      end
      else begin
        $error("Error occurs for dividend = %d, divisor = %d",dividend_i, divisor_i);
        $display("Result from C:%b",getDivisionResult(dividend_i, divisor_i));
        $display("Result from V:%b",result_o);
        $finish;
      end
      if(once) $finish;
    end
  end

end

endmodule
