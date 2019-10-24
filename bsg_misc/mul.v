// -------------------------------------------------------
// -- mul.v
// -------------------------------------------------------
// This is wrapper for Synopsys * operator in pipeline form.
// Remember to apply retiming on this module when synthesizing. 
// -------------------------------------------------------


module mul #(
  parameter integer width_p = "inv"
  ,parameter integer stage_p = "inv"
)(

  input clk_i
  ,input reset_i

  ,input [width_p-1:0] opA_i
  ,input [width_p-1:0] opB_i

  ,output [2*width_p-1:0] res_o
);
  wire [2*width_p-1:0] reset_i ? '0 : res_n;
  bsg_dff_chain #(
    .width_p(2*width_p)
    ,.num_stages_p(stage_p)
  ) chain (
    .clk_i(clk_i)
    ,.data_i(res_n)
    ,.data_o(res_o)
  );

endmodule
