/**
 *  bsg_mux_segmented_hetero.v
 *  @param segments_p number of segments.
 *  @param segment_width_p width of each segment.
 */

`include "bsg_defines.v"

module bsg_mux_segmented_hetero #(parameter segments_p=1
                                 ,parameter width_p = 1
                                 ,parameter integer agg_segment_widths_p [segments_p:0] = '{1, 0})
(
  input [width_p-1:0] data0_i
  ,input [width_p-1:0] data1_i
  ,input [segments_p-1:0] sel_i
  ,output logic [width_p-1:0] data_o
);


  for (genvar i = 1; i < segments_p; i++) begin
    assign data_o[agg_segment_widths_p[i-1]+:agg_segment_widths_p[i]] = sel_i[i]
      ? data1_i[agg_segment_widths_p[i-1]+:agg_segment_widths_p[i]]
      : data0_i[agg_segment_widths_p[i-1]+:agg_segment_widths_p[i]];
  end

endmodule
