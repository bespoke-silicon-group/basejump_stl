//
// bsg_tag_lines_join
//
// This module takes as input a single tag clk + en wire as well as the op +
// param wires for multiple tag lines and joins them together into a collection
// of bsg_tag_s lines which share the same clk and en lines (just like all
// bsg_tag_s lines coming from the same bsg_tag_master).
//
// This module is useful in conjunction with bsg_tag_lines_disjoin in hierarchical
// design flows. Given a sub-block macro has multiple tag lines as input, then
// all 4 wires for each line will become a port on the block, even though the
// clk + en lines are identical across all tag lines driven by the same tag
// master. This leads to the tool doing a fanout of the clk + en wires right
// before the macro pins. Inside the block, each of these input clk wires are
// then treated as a separate clock objects which significantly increases the
// complexity of the block. By using bsg_tag_lines_disjoin before going into a
// hierarchical block, and then using bsg_tag_lines_join inside the block, we
// can maintain a single clock and en port into the hierarchical block while
// still using the normal bsg_tag_s 4-wire structure before the disjoin and
// after the join for connections to bsg_tag_master + bsg_tag_client instances.
//
// 4/28/2021
//
module bsg_tag_lines_join
  import bsg_tag_pkg::bsg_tag_s;

#( els_p = "inv" )

( input                  bsg_tag_clk_i
, input                  bsg_tag_en_i
, input [els_p-1:0][1:0] bsg_tag_op_param_i

, output bsg_tag_s [els_p-1:0] bsg_tag_o
);

  for (genvar i = 0; i < els_p; i++)
    begin: rof
      assign bsg_tag_o[i].clk   = bsg_tag_clk_i;
      assign bsg_tag_o[i].en    = bsg_tag_en_i;
      assign bsg_tag_o[i].op    = bsg_tag_op_param_i[i][1];
      assign bsg_tag_o[i].param = bsg_tag_op_param_i[i][0];
    end: rof

endmodule
