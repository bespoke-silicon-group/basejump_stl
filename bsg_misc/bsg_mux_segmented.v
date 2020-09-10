/**
 *  bsg_mux_segmented.v
 *  @param segments_p number of segments.
 *  @param segment_width_p width of each segment.
 */

`include "bsg_defines.v"

module bsg_mux_segmented #(parameter segments_p="inv"
                          ,parameter segment_width_p="inv"
                          ,parameter data_width_lp=segments_p*segment_width_p)
(
  input [data_width_lp-1:0] data0_i
  ,input [data_width_lp-1:0] data1_i
  ,input [segments_p-1:0] sel_i
  ,output logic [data_width_lp-1:0] data_o
);

  genvar i;
  for (i = 0; i < segments_p; i++) begin
    assign data_o[i*segment_width_p+:segment_width_p] = sel_i[i]
      ? data1_i[i*segment_width_p+:segment_width_p]
      : data0_i[i*segment_width_p+:segment_width_p];
  end

endmodule
