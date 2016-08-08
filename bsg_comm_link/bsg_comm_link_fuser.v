//------------------------------------------------------------
// University of California, San Diego - Bespoke Systems Group
//------------------------------------------------------------
// File: bsg_comm_link_fuser.v
//
// Authors: Michael Taylor - mbtaylor@ucsd.edu
//          Luis Vega - lvgutierrez@eng.ucsd.edu
//
// this module is based on:
// - bsg_sbox
// - bsg_popcount
// - bsg_assembler_out
// - bsg_assembler_in
//
// function:
// - fuse io-channels into one-core-channel (for core usage)
// - unfuse one-core-channel into io-channels (for io usage)
// - sbox schedules io-channel data in a round-robin fashion.
//   Also, sbox uses core_active_channels_i for handling
//   cases where one or more io-channel are down and replacing
//   it with active-io-channel data.
//------------------------------------------------------------

module bsg_comm_link_fuser #
  (parameter channel_width_p = "inv"
  ,parameter core_channels_p = "inv"
  ,parameter link_channels_p = "inv"
  ,parameter sbox_pipeline_in_p  = "inv"
  ,parameter sbox_pipeline_out_p = "inv"
  ,parameter channel_mask_p = "inv"
  ,parameter fuser_width_p = channel_width_p*core_channels_p)
  (input clk_i
  ,input reset_i

  // ctrl
  ,input                       core_calib_done_r_i
  ,input [link_channels_p-1:0] core_active_channels_i

  // unfused in
  ,input  [link_channels_p-1:0] unfused_valid_i
  ,input  [channel_width_p-1:0] unfused_data_i [link_channels_p-1:0]
  ,output [link_channels_p-1:0] unfused_yumi_o

  // unfused out
  ,output [link_channels_p-1:0] unfused_valid_o
  ,output [channel_width_p-1:0] unfused_data_o [link_channels_p-1:0]
  ,input  [link_channels_p-1:0] unfused_ready_i

  // fused in
  ,input                     fused_valid_i
  ,input [fuser_width_p-1:0] fused_data_i
  ,output                    fused_ready_o

  // fused out
  ,output                     fused_valid_o
  ,output [fuser_width_p-1:0] fused_data_o
  ,input                      fused_yumi_i);

  // sbox

  logic [link_channels_p-1:0] bao_valid_lo;
  logic [channel_width_p-1:0] bao_data_lo [link_channels_p-1:0];
  logic [link_channels_p-1:0] sbox_ready_lo;

  logic [link_channels_p-1:0] sbox_valid_lo;
  logic [channel_width_p-1:0] sbox_data_lo [link_channels_p-1:0];
  logic [link_channels_p-1:0] bai_yumi_lo;

  bsg_sbox #
    (.num_channels_p(link_channels_p)
    ,.channel_width_p(channel_width_p)
    ,.pipeline_indir_p(sbox_pipeline_in_p)
    ,.pipeline_outdir_p(sbox_pipeline_out_p))
  sbox
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    // ctrl
    ,.calibration_done_i(core_calib_done_r_i)
    ,.channel_active_i(core_active_channels_i)
    // sbox in
    ,.in_v_i(unfused_valid_i)
    ,.in_data_i(unfused_data_i)
    ,.in_yumi_o(unfused_yumi_o)
    // sbox out
    ,.out_me_v_o(unfused_valid_o)
    ,.out_me_data_o(unfused_data_o)
    ,.out_me_ready_i(unfused_ready_i)
    // asm in
    ,.out_me_v_i(bao_valid_lo)
    ,.out_me_data_i(bao_data_lo)
    ,.out_me_ready_o(sbox_ready_lo)
    // asm out
    ,.in_v_o(sbox_valid_lo)
    ,.in_data_o(sbox_data_lo)
    ,.in_yumi_i(bai_yumi_lo));

  // assembler

  logic [`BSG_MAX(0,$clog2(link_channels_p+1)-1):0] core_active_channel_count_lo;

  bsg_popcount #
    (.width_p(link_channels_p))
  bp
    (.i(core_active_channels_i)
    ,.o(core_active_channel_count_lo));

  logic [`BSG_MAX(0,$clog2(link_channels_p)-1):0] top_active_channel_r;

  always_ff @(posedge clk_i)
    top_active_channel_r <= (| core_active_channels_i)?
                            (core_active_channel_count_lo-1) : '0;

  typedef logic [`BSG_MAX($clog2(core_channels_p),1)-1:0] bsg_comm_link_active_t;

  localparam bsg_comm_link_active_t top_asm_channel_lp = bsg_comm_link_active_t ' (core_channels_p)-1;

  bsg_assembler_out #
    (.width_p(channel_width_p)
    ,.num_in_p(core_channels_p)
    ,.num_out_p(link_channels_p)
    ,.out_channel_count_mask_p(channel_mask_p))
  bao
    (.clk(clk_i)
    ,.reset(reset_i)
    // ctrl
    ,.calibration_done_i(core_calib_done_r_i)
    ,.in_top_channel_i(top_asm_channel_lp)
    ,.out_top_channel_i(top_active_channel_r)
    // in
    ,.valid_i(fused_valid_i)
    ,.data_i(fused_data_i)
    ,.ready_o(fused_ready_o)
    // out
    ,.valid_o(bao_valid_lo)
    ,.data_o(bao_data_lo)
    ,.ready_i(sbox_ready_lo));

  bsg_assembler_in #
    (.width_p(channel_width_p)
    ,.num_in_p(link_channels_p)
    ,.num_out_p(core_channels_p)
    ,.in_channel_count_mask_p(channel_mask_p))
  bai
    (.clk(clk_i)
    ,.reset(reset_i)
    // ctrl
    ,.calibration_done_i(core_calib_done_r_i)
    ,.in_top_channel_i(top_active_channel_r)
    ,.out_top_channel_i(top_asm_channel_lp)
    // in
    ,.valid_i(sbox_valid_lo)
    ,.data_i(sbox_data_lo)
    ,.yumi_o(bai_yumi_lo)
    // out
    ,.valid_o(fused_valid_o)
    ,.data_o(fused_data_o)
    ,.yumi_i(fused_yumi_i));

endmodule
