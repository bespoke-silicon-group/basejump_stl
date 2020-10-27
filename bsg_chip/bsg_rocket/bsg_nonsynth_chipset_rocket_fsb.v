`include "bsg_defines.v"

module bsg_nonsynth_chipset_rocket
  #(parameter num_channels_p=4
    , parameter channel_width_p=8
    , parameter master_bypass_test_p=5'b11111

    // localparams
    , parameter htif_destid_p     = 0
    , parameter nasti_destid_p    = 1
    , parameter nodes_lp          = 3
    , parameter lg_rom_addr_lp    = 6
    , parameter ring_bytes_lp     = 10
    , parameter ring_width_lp     = ring_bytes_lp*channel_width_p
    , parameter rom_data_width_lp = ring_width_lp+4
    )
   (
    input core_clk_i
    , input async_reset_i
    , input io_master_clk_i

    // input from i/o
    , input  [num_channels_p  - 1:0]  io_clk_tline_i       // clk
    , input  [num_channels_p  - 1:0]  io_valid_tline_i
    , input  [channel_width_p - 1:0]  io_data_tline_i  [num_channels_p-1:0]
    , output [num_channels_p  - 1:0]  io_token_clk_tline_o // clk

    // out to i/o
    , output [num_channels_p  - 1:0]  im_clk_tline_o       // clk
    , output [num_channels_p  - 1:0]  im_valid_tline_o
    , output [channel_width_p - 1:0]  im_data_tline_o  [num_channels_p-1:0]
    , input  [num_channels_p  - 1:0]  token_clk_tline_i    // clk

    // note: generate by the master (FPGA) and sent to the slave (ASIC)
    // not used by slave (ASIC).
    , output reg im_slave_reset_tline_r_o

    // this signal is the post-calibration reset signal
    // synchronous to the core clock
    , output core_reset_o
    );

   localparam master_to_slave_speedup_lp = 100;
   localparam enabled_at_start_vec_lp    = 3'b111;
   localparam htif_width_lp              = 16;

   wire [nodes_lp-1:0] core_node_en_r_lo;
   wire [nodes_lp-1:0] core_node_reset_r_lo;

   wire                         trace_done;

   // into nodes (fsb interface)
   wire [nodes_lp-1:0]       core_node_v_A;
   wire [ring_width_lp-1:0]  core_node_data_A     [nodes_lp-1:0];
   wire [nodes_lp-1:0]       core_node_ready_A;

   // out of nodes (fsb interface)
   wire [nodes_lp-1:0]       core_node_v_B;
   wire [ring_width_lp-1:0]  core_node_data_B     [nodes_lp-1:0];
   wire [nodes_lp-1:0]       core_node_yumi_B;

   // NODE #0: NASTI slave

   bsg_nasti_addr_channel_s           ra, wa;
   bsg_nasti_write_data_channel_s     wd;
   bsg_nasti_read_data_channel_s      rd;
   bsg_nasti_write_response_channel_s wr;

   logic                     ra_ready, wa_ready, wd_ready, rd_ready, wr_ready;

   bsg_fsb_to_nasti_slave_connector
     #(.destid_p(nasti_destid_p)

     (.clk_i
      ,.reset_i

      ,.fsb_v_i    (core_node_v_A    [0])
      ,.fsb_data_i (core_node_data_A [0])
      ,.fsb_ready_o(core_node_ready_A[0])

      ,.fsb_v_o    (core_node_v_B    [0])
      ,.fsb_data_o (core_node_data_B [0])
      ,.fsb_yumi_i (core_node_yumi_B [0])

      ,.nasti_read_addr_ch_o        (ra)
      ,.nasti_read_addr_ch_ready_i  (ra_ready)

      ,.nasti_write_addr_ch_o       (wa)
      ,.nasti_write_addr_ch_ready_i (wa_ready)

      ,.nasti_write_data_ch_o       (wd)
      ,.nasti_write_data_ch_ready_i (wd_ready)

      ,.nasti_read_data_ch_i        (rd)
      ,.nasti_read_data_ch_ready_o  (rd_ready)

      ,.nasti_write_resp_ch_i       (wr)
      ,.nasti_write_resp_ch_ready_o (wr_ready)
      );

   reg [31:0]                channel_0 = 0;

   always @(posedge clk_i)
     begin
        if (~trace_done)
          begin
             ra_ready <= 1'b0;
             wa_ready <= 1'b0;
             wd_ready <= 1'b0;

             rd.v     <= 1'b0;
             wr.v     <= 1'b0;
          end
        else
          begin
             memory_tick (channel_0
                          , ra.v, ra_ready, ra.addr,  ra.id,   ra.size, ra.len
                          , wa.v, wa_ready, wa.addr,  wa.id,   wa.size, wa.len
                          , wd.v, wd_ready, wd.strb,  wd.data, wd.last
                          , rd.v, rd_ready, rd.resp,  rd.id,   rd.data, rd.last
                          , wr.v, wr_ready, wr.resp,  wr.id
                          );
     end

   // connect to PLI

   wire                      htif_v_li, htif_v_lo;
   logic [htif_width_lp-1:0] htif_data_li;
   logic [htif_width_lp-1:0] htif_data_lo;
   wire                      htif_ready_lo, htif_ready_li;
   logic [31:0]              exit = 0;

   // NODE #1: HTIF slave
   bsg_fsb_to_htif_connector
     #(.htif_width_p(htif_width_lp)
       ,.destid_p   (htif_destid_p)
       )
     (.clk_i
      ,.reset_i

      ,.fsb_v_i     (core_node_v_A    [1])
      ,.fsb_data_i  (core_node_data_A [1])
      ,.fsb_ready_o (core_node_ready_A[1])

      ,.fsb_v_o     (core_node_v_B    [1])
      ,.fsb_data_o  (core_node_data_B [1])
      ,.fsb_yumi_i  (core_node_yumi_B [1])

      ,.htif_v_i    (htif_v_li    )
      ,.htif_data_i (htif_data_li )
      ,.htif_ready_o(htif_ready_lo)

      ,.htif_v_o    (htif_v_lo    )
      ,.htif_data_o (htif_data_lo )
      ,.htif_ready_i(htif_ready_li)
      );

   // callout through PLI
   always @(posedge clk_i)
     begin
        if (~trace_done)
          begin
             htif_v_li     <= 0;
             htif_ready_lo <= 0;
             exit          <= 0;
          end
        else
          begin
             htif_tick (htif_v_li, htif_in_ready,  htif_data_li,
                        htif_v_lo, htif_out_ready, htif_data_lo,
                        exit);
          end
     end


   // NODE #2: TRACE REPLAY
   // add a trace replay node; this is used for booting the ASIC


   wire [lg_rom_addr_lp-1:0]    rom_addr_lo;
   wire [rom_data_width_lp-1:0] rom_data_lo;

   bsg_rom_boot_asic #(.width_p      (rom_data_width_lp)
                       ,.addr_width_p(lg_rom_addr_lp   )
                       )
   rom (.addr_i (rom_addr_lo)
        ,.data_o(rom_data_lo)
        );

   bsg_fsb_node_trace_replay #(.master_id_p      (nodes_lp-1    )
                               ,.slave_id_p      (nodes_lp-1    )
                               ,.rom_addr_width_p(lg_rom_addr_lp)
                               ) replay
     (.clk_i   (core_clk_i)
      ,.reset_i(core_node_reset_r_lo[nodes_lp-1])
      ,.en_i   (core_node_en_r_lo   [nodes_lp-1])

      ,.v_i    (core_node_v_A       [nodes_lp-1])
      ,.data_i (core_node_data_A    [nodes_lp-1])
      ,.ready_o(core_node_ready_A   [nodes_lp-1])

      ,.v_o    (core_node_v_B       [nodes_lp-1])
      ,.data_o (core_node_data_B    [nodes_lp-1])
      ,.yumi_i (core_node_yumi_B    [nodes_lp-1])

      ,.rom_addr_o(rom_addr_lo)
      ,.rom_data_i(rom_data_lo)
      ,.done_o    (trace_done)
      ,.error_o   ()
      );

   bsg_comm_link #(.channel_width_p   (channel_width_p)
                   , .core_channels_p (ring_bytes_lp  )
                   , .link_channels_p (num_channels_p )
                   , .nodes_p         (nodes_lp)
                   , .master_p        (1'b1)
                   // if master, enable at startup so that
                   // it can drive things
                   , .enabled_at_start_vec_p ( enabled_at_start_vec_lp )
                   , .master_bypass_test_p   ( master_bypass_test_p    )
                   ) comm_link
     (.core_clk_i           (core_clk_i       )
      , .async_reset_i      (async_reset_i    )

      , .io_master_clk_i    (io_master_clk_i  )

      // into nodes (control)
      , .core_node_reset_r_o(core_node_reset_r_lo)
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
      , .im_data_tline_o (im_data_tline_o )
      , .im_clk_tline_o  (im_clk_tline_o  )        // clk

      , .im_slave_reset_tline_r_o (im_slave_reset_tline_r_o)
      , .token_clk_tline_i        (token_clk_tline_i       ) // clk

      ,.core_calib_reset_r_o(core_reset_o)

      // don't use
      , .core_async_reset_danger_o()
      );

endmodule // bsg_nonsynth_chipset_rocket
