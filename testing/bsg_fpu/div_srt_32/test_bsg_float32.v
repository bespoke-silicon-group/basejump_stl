/*
TEST RATIONALE

1. STATE SPACE
1000 groups of random float32 numbers.
Zero, Nan, Inf and Invalid statement

2. PARAMETERIZATION
IEEE 754 float32.

*/

module test_bsg;

import "DPI-C" function int float32Representation(input shortreal f);
import "DPI-C" function shortreal float32Encode(input int x);

logic clk_i;
logic reset_i;

logic fp32_ready_o;
logic fp32_v_i;
logic [31:0] fp32_dividend_i;
logic [31:0] fp32_divisor_i;
logic [31:0] fp32_result_o;
logic fp32_v_o;
logic fp32_subnormal, fp32_invalid, fp32_overflow, fp32_underflow;

bsg_fpu_div_n #(
  .e_p(8)
  ,.m_p(23)
  ,.debug_p(0)
) fp32_div (
  .clk_i(clk_i)
  ,.reset_i(reset_i)

  ,.ready_o(fp32_ready_o)
  ,.dividend_i(fp32_dividend_i)
  ,.divisor_i(fp32_divisor_i)
  ,.v_i(fp32_v_i)

  ,.result_o(fp32_result_o)
  ,.v_o(fp32_v_o)
  ,.yumi_i(1'b1)

  ,.unimplemented_o(fp32_subnormal)
  ,.invalid_o(fp32_invalid)
  ,.overflow_o(fp32_overflow)
  ,.underflow_o(fp32_underflow)
);

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

integer i = 0;

shortreal res_module;
shortreal res_vcs;

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    fp32_v_i <= 1'b1;
    fp32_dividend_i <= '0;
    fp32_divisor_i <= float32Encode(1);
  end
  else if(fp32_v_o) begin
    //$display("========= TEST ===========");
    if(fp32_subnormal) begin
      $display("Subnormal condition occurs.");  
    end
    else if(fp32_overflow) begin
      $display("Overflow condition occurs.");
    end
    else if(fp32_underflow) begin
      $display("Underflow condition occurs.");
    end
    else if(fp32_invalid) begin
      $display("Invalid condition occurs.");
    end
    else begin
      res_module = float32Encode(fp32_result_o);
      res_vcs = float32Encode(fp32_dividend_i)/float32Encode(fp32_divisor_i);
      if(res_module - res_vcs > 0.000001 ||res_module - res_vcs  < -0.000001) begin
        $display("================ Turn %d===================",i);
        $error("Error occur!");
        $display("dividend:%10.5f", float32Encode(fp32_dividend_i));
        $display("divisor:%10.5f", float32Encode(fp32_divisor_i));
        $display("result_o:%10.5f", res_module);
        $display("Result in VCS: %10.5f",res_vcs);
        $display("Distance : %.10f", res_module - res_vcs);
      end
    end
    i = i + 1;
    if(i == 5) $finish;
    if(i == 0) begin // Testing 0/0(invalid)
      fp32_dividend_i <= '0;
      fp32_divisor_i <= '0;
    end
    else if(i == 1) begin // Testing Zero
      fp32_dividend_i <= '0;
      fp32_divisor_i <= float32Representation(10);
    end
    else if(i == 2) begin // Testing Overflow
      // 9.444733E37
      fp32_dividend_i <= 32'b01111110100011100001101111001010;
      // 1.3050609E-38
      fp32_divisor_i <= 32'b00000000100011100001101111001010;
    end
    else if(i == 3) begin // Testing Underflow
      fp32_dividend_i <= 32'b00000000100011100001101111001010;
      fp32_divisor_i <= 32'b01111110100011100001101111001010;
    end
    else begin // Random Test
      fp32_dividend_i <= float32Representation($random);
      fp32_divisor_i <= float32Representation($random);
    end
  end
  else begin
    //$display("dividend:%10.5f", float32Encode(fp32_dividend_i));
    //$display("divisor:%10.5f", float32Encode(fp32_divisor_i));
  end
end


endmodule
