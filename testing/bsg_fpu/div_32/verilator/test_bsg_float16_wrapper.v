// -------------------------------------------------------
// -- test_bsg_float16_wrapper.v
// -- This fils is used for Verilator who cannot specify the parameter in C++ test bench.
// -------------------------------------------------------

module bsg_fpu_div_float16(
  input clk_i
  ,input reset_i
  ,output ready_o
  
  ,input [16-1:0] dividend_i
  ,input [16-1:0] divisor_i
  ,input v_i

  ,output logic [16-1:0] result_o
  ,output v_o
  ,input yumi_i

  // result information
  ,output logic unimplemented_o // subnormal floating point number.
  ,output logic invalid_o
  ,output logic overflow_o
  ,output logic underflow_o
  ,output logic divisor_is_zero_o
);

bsg_fpu_div #(
  .e_p(5)
  ,.m_p(10)
  ,.debug_p(0)
) divisor (.*);

endmodule
