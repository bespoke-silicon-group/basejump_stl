// mbt 2-12-16
//
// this goes in silicon
// 
//

`include "bsg_defines.v"

module bsg_chip_rocket #(
                         parameter num_channels_p              = 4
                         , parameter channel_width_p           = 8
                         , parameter enabled_at_start_vec_p    = 0
                         , parameter master_p                  = 0
                         , parameter master_to_slave_speedup_p = 100
                         , parameter master_bypass_test_p      = 5'b00000
                         , parameter nodes_lp                  = 2
                         , parameter uniqueness_p              = 0
                         )
   (
    input core_clk_i
    , input async_reset_i
    , input io_master_clk_i

    // input from i/o
    , input  [num_channels_p-1:0]  io_clk_tline_i       // clk
    , input  [num_channels_p-1:0]  io_valid_tline_i
    , input  [channel_width_p-1:0] io_data_tline_i  [num_channels_p-1:0]
    , output [num_channels_p-1:0]  io_token_clk_tline_o // clk

    // out to i/o
    , output [num_channels_p-1:0]  im_clk_tline_o       // clk
    , output [num_channels_p-1:0]  im_valid_tline_o
    , output [channel_width_p-1:0] im_data_tline_o  [num_channels_p-1:0]
    , input  [num_channels_p-1:0]  token_clk_tline_i    // clk

    // this signal is the post-calibration reset signal
    // synchronous to the core clock
    , output core_reset_o
    );

  // size of RingPacketType, in bytes
   localparam ring_bytes_lp  = 10;
   localparam ring_width_lp  = ring_bytes_lp*channel_width_p;

   // into nodes (fsb interface)
   wire [nodes_lp-1:0]       core_node_v_A;
   wire [ring_width_lp-1:0]  core_node_data_A   [nodes_lp-1:0];
   wire [nodes_lp-1:0]       core_node_ready_A;

    // into nodes (control)
   wire [nodes_lp-1:0]      core_node_en_r_lo;
   wire [nodes_lp-1:0]      core_node_reset_r_lo;

    // out of nodes (fsb interface)
   wire [nodes_lp-1:0]       core_node_v_B;
   wire [ring_width_lp-1:0]  core_node_data_B   [nodes_lp-1:0];
   wire [nodes_lp-1:0]       core_node_yumi_B;

   wire [nodes_lp-1:0]       core_node_reset_lo;

   bsg_rocket_core_fsb #(.nasti_destid_p(1)
                         .htif_destid_p(0)
                         ) core
     (.clk_i    (core_clk_i            )

      // the rocket core uses two ports on the FSB
      // we say, it is in reset if either port is in
      // reset; and that it is in enable only if both ports
      // are in enable.

      ,.reset_i (|core_node_en_r_lo    )
      ,.enable_i(&core_node_reset_r_lo )

      ,.v_i    (core_node_v_A    )
      ,.data_i (core_node_data_A )
      ,.ready_o(core_node_ready_A)

      ,.v_o    (core_node_v_B    )
      ..data_o (core_node_data_B )
      ,.yumi_i (core_node_yumi_B )

      );

   bsg_comm_link #(.channel_width_p   (channel_width_p)
                   , .core_channels_p (ring_bytes_lp   )
                   , .link_channels_p (num_channels_p  )
                   , .nodes_p         (nodes_lp)
                   , .master_p        (0)
                   ) comm_link
     (.core_clk_i           (core_clk_i       )
      , .async_reset_i      (async_reset_i    )

      , .io_master_clk_i    (io_master_clk_i  )

      // into nodes (control)
      , .core_node_reset_r_o(core_node_reset_lo)
      , .core_node_en_r_o   (core_node_en_r_lo )

      // into nodes (fsb interface)
      , .core_node_v_o      (core_node_v_A    )
      , .core_node_data_o   (core_node_data_A )
      , .core_node_ready_i  (core_node_ready_A)

      // out of nodes (fsb interface)
      , .core_node_v_i   (core_node_v_B   )
      , .core_node_data_i(core_node_data_B)
      , .core_node_yumi_o(core_node_yumi_B)

      // in from i/o
      , .io_valid_tline_i    (io_valid_tline_i    )
      , .io_data_tline_i     (io_data_tline_i     )
      , .io_clk_tline_i      (io_clk_tline_i      )  // clk
      , .io_token_clk_tline_o(io_token_clk_tline_o)  // clk

      // out to i/o
      , .im_valid_tline_o(im_valid_tline_o)
      , .im_data_tline_o ( im_data_tline_o)
      , .im_clk_tline_o  (  im_clk_tline_o)        // clk

      , .im_slave_reset_tline_r_o ()  // unused by slave comm link

      , .token_clk_tline_i        (token_clk_tline_i       ) // clk

      ,.core_calib_reset_r_o(core_reset_o)

      // don't use
      , .core_async_reset_danger_o()
      );

endmodule
