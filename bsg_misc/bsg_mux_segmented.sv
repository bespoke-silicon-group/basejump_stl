/**
 *  bsg_mux_segmented.sv
 *  @param segments_p number of segments.
 *  @param segment_width_p width of each segment.
 */

`include "bsg_defines.sv"

module bsg_mux_segmented #(parameter `BSG_INV_PARAM(segments_p)
                          ,parameter `BSG_INV_PARAM(segment_width_p)
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

`BSG_ABSTRACT_MODULE(bsg_mux_segmented)
