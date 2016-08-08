//--------------------------------------------------------------------------
// University of California, San Diego - Bespoke Systems Group
//--------------------------------------------------------------------------
// File: bsg_comm_link.v
//
// Authors: Michael Taylor - mbtaylor@ucsd.edu
//          Luis Vega - lvgutierrez@eng.ucsd.edu
//
// Revision history:
// * [08-27-2014] Michael Taylor created bsg_comm_link
// * [06-07-2016] Luis Vega refactored bsg_comm_link
//
// clocks:
//
// There are many clocks in this module, and synchronizer conventions must
// be obeyed when mixing signals in different domains. Moreover, they need
// to be generated as clocks in physical design.
//
// We use the following conventions for signals:
//
// core_  : synchronous to core_clk_i domain
// im_    : synchronous to io_master_clk_i
// io_    : synchronous to one of N input channel clocks, each potentially
//          with a different freq/phase
// token_ : synchronous to one of N incoming token clocks
//--------------------------------------------------------------------------

module bsg_comm_link #
  (parameter channel_width_p = "inv"
  ,parameter core_channels_p = "inv"
  ,parameter link_channels_p = "inv"

  // enable this if comm_link appears on the critical path
  // adds one core cycle of latency in or out
  // and two channel_width_p*link_channels fifos.
  ,parameter sbox_pipeline_in_p  = 1'b1
  ,parameter sbox_pipeline_out_p = 1'b1

  // e.g if you have four channels, and you wanted any
  // subset of them to be supported, you would
  // provide 1111. if you only want all four channels
  // to be supported, then you provide 1000.
  //
  // any combination of channels
  ,parameter channel_mask_p = (1 << (link_channels_p)) - 1

  // 1 = FPGA, 0 = ASIC
  ,parameter master_p = "inv"

  // in testing, use this to disable tests
  ,parameter master_bypass_test_p = 5'b00000

  // NB: master_  parameters only apply to the master
  // this is the maximum ratio between master io frequency
  // and the min of: slave io frequency
  //                 slave core frequency
  //                 master core frequency
  //
  // that we want to support.
  // Used only by master.
  ,parameter master_to_slave_speedup_p = 100

  // for DDR at 500 mbps, we make token go at / 8 = 66 mbps
  // this will keep the token clock nice and slow
  // careful: values other than 3 have not been tested.
  ,parameter lg_credit_to_token_decimation_p = 3

  // across all frequency combinations, we need a little over 20 fifo slots
  // so we round up to 32, to allow for delay in the FPGA
  ,parameter lg_input_fifo_depth_p = 5

  // core (for fuser) width
  ,parameter width_p=core_channels_p*channel_width_p)

  (input core_clk_i
  ,input io_master_clk_i
  ,input async_reset_i

  // core ctrl
  ,output core_calib_done_r_o

  // core in
  ,input               core_valid_i
  ,input [width_p-1:0] core_data_i
  ,output              core_ready_o

  // core out
  ,output               core_valid_o
  ,output [width_p-1:0] core_data_o
  ,input                core_yumi_i

  // io in
  ,input  [link_channels_p-1:0] io_clk_tline_i
  ,input  [link_channels_p-1:0] io_valid_tline_i
  ,input  [channel_width_p-1:0] io_data_tline_i [link_channels_p-1:0]
  ,output [link_channels_p-1:0] io_token_clk_tline_o

  // im out
  ,output [link_channels_p-1:0] im_clk_tline_o
  ,output [link_channels_p-1:0] im_valid_tline_o
  ,output [channel_width_p-1:0] im_data_tline_o [link_channels_p-1:0]

  // im slave reset for ASIC
  ,output im_slave_reset_tline_r_o

  // token in
  ,input [link_channels_p-1:0] token_clk_tline_i);

  // fuser

  logic                       core_kernel_calib_done_lo;
  logic [link_channels_p-1:0] core_kernel_active_channels_lo;

  logic [link_channels_p-1:0] core_kernel_valid_lo;
  logic [channel_width_p-1:0] core_kernel_data_lo [link_channels_p-1:0];
  logic [link_channels_p-1:0] core_fuser_yumi_lo;

  logic [link_channels_p-1:0] core_fuser_valid_lo;
  logic [channel_width_p-1:0] core_fuser_data_lo [link_channels_p-1:0];
  logic [link_channels_p-1:0] core_kernel_ready_lo;

  bsg_comm_link_fuser #
    (.channel_width_p(channel_width_p)
    ,.core_channels_p(core_channels_p)
    ,.link_channels_p(link_channels_p)
    ,.sbox_pipeline_in_p(sbox_pipeline_in_p)
    ,.sbox_pipeline_out_p(sbox_pipeline_out_p)
    ,.channel_mask_p(channel_mask_p))
  fuser
    (.clk_i(core_clk_i)
    ,.reset_i(~core_kernel_calib_done_lo)
    // ctrl
    ,.core_calib_done_r_i(core_kernel_calib_done_lo)
    ,.core_active_channels_i(core_kernel_active_channels_lo)
    // fused in
    ,.fused_valid_i(core_valid_i)
    ,.fused_data_i(core_data_i)
    ,.fused_ready_o(core_ready_o)
    // fused out
    ,.fused_valid_o(core_valid_o)
    ,.fused_data_o(core_data_o)
    ,.fused_yumi_i(core_yumi_i)
    // unfused in
    ,.unfused_valid_i(core_kernel_valid_lo)
    ,.unfused_data_i(core_kernel_data_lo)
    ,.unfused_yumi_o(core_fuser_yumi_lo)
    // unfused out
    ,.unfused_valid_o(core_fuser_valid_lo)
    ,.unfused_data_o(core_fuser_data_lo)
    ,.unfused_ready_i(core_kernel_ready_lo));

  // kernel

  bsg_comm_link_kernel #
    (.channel_width_p(channel_width_p)
    ,.core_channels_p(core_channels_p)
    ,.link_channels_p(link_channels_p)
    ,.master_p(master_p)
    ,.master_bypass_test_p(master_bypass_test_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ,.lg_input_fifo_depth_p(lg_input_fifo_depth_p))
  kernel
    (.core_clk_i(core_clk_i)
    ,.io_master_clk_i(io_master_clk_i)
    ,.async_reset_i(async_reset_i)
    // core ctrl
    ,.core_calib_done_r_o(core_kernel_calib_done_lo)
    ,.core_active_channels_o(core_kernel_active_channels_lo)
    ,.core_async_reset_danger_o()
    // core in
    ,.core_valid_i(core_fuser_valid_lo)
    ,.core_data_i(core_fuser_data_lo)
    ,.core_ready_o(core_kernel_ready_lo)
    // core out
    ,.core_valid_o(core_kernel_valid_lo)
    ,.core_data_o(core_kernel_data_lo)
    ,.core_yumi_i(core_fuser_yumi_lo)
    // io in
    ,.io_clk_tline_i(io_clk_tline_i)
    ,.io_valid_tline_i(io_valid_tline_i)
    ,.io_data_tline_i(io_data_tline_i)
    ,.io_token_clk_tline_o(io_token_clk_tline_o)
    // im out
    ,.im_clk_tline_o(im_clk_tline_o)
    ,.im_valid_tline_o(im_valid_tline_o)
    ,.im_data_tline_o(im_data_tline_o)
    // im ctrl
    ,.im_slave_reset_tline_r_o(im_slave_reset_tline_r_o)
    // token in
    ,.token_clk_tline_i(token_clk_tline_i));

  assign core_calib_done_r_o = core_kernel_calib_done_lo;

endmodule
