/*
TEST RATIONALE

1. STATE SPACE
60000 groups of random float32 numbers.
Zero, Nan, Inf and Invalid statement

2. PARAMETERIZATION
IEEE 754 float32.

*/

module test_bsg;

import "DPI-C" function int float32Representation(input shortreal f);
import "DPI-C" function shortreal float32Encode(input int x);

localparam once = 1;
localparam real dividend_given = 777537856.00000;
localparam real divisor_given = -561108800.00000;

logic clk_i;
logic reset_i;

logic fp32_ready_o;
logic fp32_v_i;
logic [31:0] fp32_dividend_i;
logic [31:0] fp32_divisor_i;
logic [31:0] fp32_result_o;
logic fp32_v_o;
logic fp32_subnormal, fp32_invalid, fp32_overflow, fp32_underflow, fp32divisor_zero;

bsg_fpu_div #(
  .e_p(8)
  ,.m_p(23)
  ,.debug_p(once)
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
  ,.divisor_is_zero_o(fp32divisor_zero)
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
integer cyc = 0;

shortreal res_module;
shortreal res_vcs;
logic [31:0] res_vcs_rep;

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    fp32_v_i <= 1'b1;
    fp32_dividend_i <= '0;
    fp32_divisor_i <= float32Encode(1);
    cyc <= '0;
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
      res_vcs = float32Encode(fp32_dividend_i) / float32Encode(fp32_divisor_i);
      res_vcs_rep = float32Representation(res_vcs);
      if(res_module != res_vcs) begin
        $display("================ Turn %d===================",i);
        $error("Error occur!");
        $display("dividend:%10.5f", float32Encode(fp32_dividend_i));
        $display("divisor:%10.5f", float32Encode(fp32_divisor_i));
        $display("result_o:%10.5f", res_module);
        $display("Result in VCS: %10.5f",res_vcs);
        $display("result_o(bits)    :%b", fp32_result_o);
        $display("Result in VCS(bit):%b",res_vcs_rep);
        $display("Distance : %.10f", res_module - res_vcs);
        if(fp32_result_o[31:1] != res_vcs_rep[31:1]) begin
          $finish;
        end 
        else begin
          $display("Turn %d: Only last bit is different.", i);
        end
      end
    end
    i = i + 1;
    if(i == 5 & once | i == 60000) $finish;
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
      fp32_dividend_i <= float32Representation(once ? dividend_given : $random);
      fp32_divisor_i <= float32Representation(once ? divisor_given : $random);
    end
  end
  else begin
    //$display("dividend:%10.5f", float32Encode(fp32_dividend_i));
    //$display("divisor:%10.5f", float32Encode(fp32_divisor_i));
  end
  cyc += 1;
end


endmodule
