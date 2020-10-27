// bsg_fsb_node_level_shift_node_domain
//
// This module is design to level shift all signals that connect the FSB to a
// node. This allows FSB nodes to exist in different power domains than the FSB.
// There are 2 types of level shifters:
//
//    1) Source - level shifting cell must be in the same power domain as the
//                signal's source
//    2) Sink   - level shifting cell must be in the same power doamin as the
//                signal's destination
// 
// This is 1 of 4 modules that shift all the signals between the FSB and
// a node. Each of the modules has a different strategy about which power
// domain the level-shifters should be in:
//
//    1) bsg_fsb_node_level_shift_all_sink
//          -- All level shifters in same power domain as the input pin
//    2) bsg_fsb_node_level_shift_all_source
//          -- All level shifters in same power domain as the output pin
//    3) bsg_fsb_node_level_shift_fsb_domain
//          -- All level shifters in same power domain as the fsb module
//  * 4) bsg_fsb_node_level_shift_node_domain
//          -- All level shifters in same power domain as the node module
//
`include "bsg_defines.v"

module bsg_fsb_node_level_shift_node_domain #(parameter ring_width_p = "inv")
(
  input  en_ls_i,

  input  clk_i,
  input  reset_i,

  output clk_o,
  output reset_o,

  //----- ATTACHED TO FSB -----//
  output                    fsb_v_i_o,
  output [ring_width_p-1:0] fsb_data_i_o,
  input                     fsb_yumi_o_i,

  input                     fsb_v_o_i,
  input  [ring_width_p-1:0] fsb_data_o_i,
  output                    fsb_ready_i_o,

  //----- ATTACHED TO NODE -----//
  output                    node_v_i_o,
  output [ring_width_p-1:0] node_data_i_o,
  input                     node_ready_o_i,

  input                     node_v_o_i,
  input  [ring_width_p-1:0] node_data_o_i,
  output                    node_yumi_i_o
);

// Level Shift Clock
bsg_level_shift_up_down_sink #(.width_p(1)) clk_ls_inst
(
  .v1_en_i(1'b1),
  .v0_data_i(clk_i),
  .v1_data_o(clk_o)
);

// Level Shift Reset
bsg_level_shift_up_down_sink #(.width_p(1)) reset_ls_inst
(
  .v1_en_i(1'b1),
  .v0_data_i(reset_i),
  .v1_data_o(reset_o)
);

// NODE v_o --> FSB v_i
bsg_level_shift_up_down_source #(.width_p(1)) n2f_v_ls_inst
(
  .v0_en_i(en_ls_i),
  .v0_data_i(node_v_o_i),
  .v1_data_o(fsb_v_i_o)
);

// NODE data_o --> FSB data_i
bsg_level_shift_up_down_source #(.width_p(ring_width_p)) n2f_data_ls_inst
(
  .v0_en_i(en_ls_i),
  .v0_data_i(node_data_o_i),
  .v1_data_o(fsb_data_i_o)
);

// FSB yumi_o --> NODE yumi_i
bsg_level_shift_up_down_sink #(.width_p(1)) f2n_yumi_ls_inst
(
  .v1_en_i(en_ls_i),
  .v0_data_i(fsb_yumi_o_i),
  .v1_data_o(node_yumi_i_o)
);

// FSB v_o --> NODE v_i
bsg_level_shift_up_down_sink #(.width_p(1)) f2n_v_ls_inst
(
  .v1_en_i(en_ls_i),
  .v0_data_i(fsb_v_o_i),
  .v1_data_o(node_v_i_o)
);

// FSB data_o --> NODE data_i
bsg_level_shift_up_down_sink #(.width_p(ring_width_p)) f2n_data_ls_inst
(
  .v1_en_i(en_ls_i),
  .v0_data_i(fsb_data_o_i),
  .v1_data_o(node_data_i_o)
);

// NODE ready_o --> FSB ready_i
bsg_level_shift_up_down_source #(.width_p(1)) n2f_ready_ls_inst
(
  .v0_en_i(en_ls_i),
  .v0_data_i(node_ready_o_i),
  .v1_data_o(fsb_ready_i_o)
);

endmodule
