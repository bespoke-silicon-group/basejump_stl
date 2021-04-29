//
// bsg_tag_lines_disjoin
//
// This module takes as input a collection of bsg_tag_s lines (note: these
// lines should all be driven by the same bsg_tag_master). It will then forward
// the clk + en of the first tag line and the op + param of each tag line.
//
// This module is useful in conjunction with bsg_tag_lines_join in hierarchical
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
module bsg_tag_lines_disjoin
  import bsg_tag_pkg::bsg_tag_s;

#( els_p = "inv" )

( input bsg_tag_s [els_p-1:0] bsg_tag_i

, output logic                  bsg_tag_clk_o
, output logic                  bsg_tag_en_o
, output logic [els_p-1:0][1:0] bsg_tag_op_param_o
);

  assign bsg_tag_clk_o = bsg_tag_i[0].clk;
  assign bsg_tag_en_o  = bsg_tag_i[0].en;

  for (genvar i = 0; i < els_p; i++)
    begin: rof
      assign bsg_tag_op_param_o[i] = {bsg_tag_i[i].op, bsg_tag_i[i].param};
    end: rof

endmodule
