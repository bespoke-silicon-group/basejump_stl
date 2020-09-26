/**
 *  bsg_mux_bitwise.v
 *  @param width_p width of data
 */

`include "bsg_defines.v"

module bsg_mux_bitwise #(parameter width_p="inv")
(
  input [width_p-1:0] data0_i
  ,input [width_p-1:0] data1_i
  ,input [width_p-1:0] sel_i
  ,output logic [width_p-1:0] data_o
);

  bsg_mux_segmented #(
    .segments_p(width_p)
    ,.segment_width_p(1)
  ) mux_segmented (
    .data0_i(data0_i)
    ,.data1_i(data1_i)
    ,.sel_i(sel_i)
    ,.data_o(data_o)
  );

endmodule
