// -------------------------------------------------------
// -- bsg_fpu_sqrt_wrapper.v
// -------------------------------------------------------
// This is a wrapper for verilator to test bsg_fpu_sqrt.v
// -------------------------------------------------------
module bsg_fpu_sqrt_wrapper(
  input clk_i
  ,input reset_i

  ,input [31:0] opr_i
  ,input v_i
  ,output ready_o

  ,output logic [31:0] result_o
  ,output v_o
  ,input yumi_i
  // status
  ,output unimplemented_o
  ,output invalid_o
  ,output overflow_o
  ,output underflow_o
);

bsg_fpu_sqrt #(
  .e_p(8)
  ,.m_p(23)
  ,.debug_p(0)
) sqrt (.*);

endmodule


