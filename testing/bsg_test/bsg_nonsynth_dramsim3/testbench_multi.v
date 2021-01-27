`include "bsg_nonsynth_dramsim3.svh"

`ifndef dram_pkg
  `define dram_pkg bsg_nonsynth_dramsim3_hbm2_8gb_x128_pkg
`endif

module testbench ();

  // clock
  logic clk;

  bsg_nonsynth_clock_gen
    #(.cycle_time_p(`dram_pkg::tck_ps))
  clkgen
    (.o(clk));

  // reset
  logic reset;

  bsg_nonsynth_reset_gen
    #(.reset_cycles_lo_p(0)
      ,.reset_cycles_hi_p(20))
  resetgen
    (.clk_i(clk)
     ,.async_reset_o(reset));

  // dramsim3
  import `dram_pkg::*;

  parameter int num_dramsim3_p = 2;

  logic [num_channels_p-1:0]                            dramsim3_v_li              [num_dramsim3_p-1:0];
  logic [num_channels_p-1:0]                            dramsim3_write_not_read_li [num_dramsim3_p-1:0];
  logic [num_channels_p-1:0] [channel_addr_width_p-1:0] dramsim3_ch_addr_li        [num_dramsim3_p-1:0];
  logic [num_channels_p-1:0]                            dramsim3_yumi_lo           [num_dramsim3_p-1:0];

  logic [num_channels_p-1:0]                            dramsim3_data_v_li         [num_dramsim3_p-1:0];
  logic [num_channels_p-1:0] [data_width_p-1:0]         dramsim3_data_li           [num_dramsim3_p-1:0];
  logic [num_channels_p-1:0]                            dramsim3_data_yumi_lo      [num_dramsim3_p-1:0];

  logic [num_channels_p-1:0]                            dramsim3_data_v_lo         [num_dramsim3_p-1:0];
  logic [num_channels_p-1:0] [data_width_p-1:0]         dramsim3_data_lo           [num_dramsim3_p-1:0];

  `dram_pkg::dram_ch_addr_s dramsim3_ch_addr_li_cast [num_dramsim3_p-1:0];

  for (genvar dramsim_i = 0; dramsim_i < num_dramsim3_p;  dramsim_i++) begin
    assign dramsim3_ch_addr_li_cast[dramsim_i] = dramsim3_ch_addr_li[dramsim_i][0];

    bsg_nonsynth_dramsim3
      #(.channel_addr_width_p(`dram_pkg::channel_addr_width_p)
        ,.data_width_p(`dram_pkg::data_width_p)
        ,.num_channels_p(`dram_pkg::num_channels_p)
        ,.num_columns_p(`dram_pkg::num_columns_p)
        ,.num_rows_p(`dram_pkg::num_rows_p)
        ,.num_ba_p(`dram_pkg::num_ba_p)
        ,.num_bg_p(`dram_pkg::num_bg_p)
        ,.num_ranks_p(`dram_pkg::num_ranks_p)
        ,.size_in_bits_p(`dram_pkg::size_in_bits_p)
        ,.address_mapping_p(`dram_pkg::address_mapping_p)
        ,.config_p(`dram_pkg::config_p)
        ,.masked_p(0)
        ,.trace_file_p(`BSG_STRINGIFY(`trace_file))
        ,.debug_p(1))
    mem
      (.clk_i(clk)
       ,.reset_i(reset)

       ,.v_i(dramsim3_v_li[dramsim_i])
       ,.write_not_read_i(dramsim3_write_not_read_li[dramsim_i])
       ,.ch_addr_i(dramsim3_ch_addr_li[dramsim_i])
       ,.yumi_o(dramsim3_yumi_lo[dramsim_i])

       ,.data_v_i(dramsim3_data_v_li[dramsim_i])
       ,.data_i(dramsim3_data_li[dramsim_i])
       ,.mask_i('0)
       ,.data_yumi_o(dramsim3_data_yumi_lo[dramsim_i])

       ,.data_v_o(dramsim3_data_v_lo[dramsim_i])
       ,.data_o(dramsim3_data_lo[dramsim_i])
       ,.read_done_ch_addr_o()

       ,.write_done_o()
       ,.write_done_ch_addr_o()
       );
  end

  // trace replay
  //
  typedef struct packed {
    logic write_not_read;
    logic [channel_addr_width_p-1:0] ch_addr;
  } dramsim3_trace_s;

  localparam ring_width_p = $bits(dramsim3_trace_s);
  localparam rom_addr_width_p=20;

  dramsim3_trace_s [num_channels_p-1:0] tr_data_lo          [num_dramsim3_p-1:0];
  logic [num_channels_p-1:0] tr_v_lo                        [num_dramsim3_p-1:0];
  logic [num_channels_p-1:0] tr_yumi_li                     [num_dramsim3_p-1:0];

  logic [num_channels_p-1:0][4+ring_width_p-1:0] rom_data   [num_dramsim3_p-1:0];
  logic [num_channels_p-1:0][rom_addr_width_p-1:0] rom_addr [num_dramsim3_p-1:0];

  logic [num_channels_p-1:0] ch_done                        [num_dramsim3_p-1:0];

  for (genvar dramsim_i = 0; dramsim_i < num_dramsim3_p; dramsim_i++) begin
    for (genvar i = 0; i < num_channels_p; i++) begin

      bsg_fsb_node_trace_replay #(
                                  .ring_width_p(ring_width_p)
                                  ,.rom_addr_width_p(rom_addr_width_p)
                                  ) tr (
                                        .clk_i(clk)
                                        ,.reset_i(reset)
                                        ,.en_i(1'b1)
                                        //,.en_i(i == '0)

                                        ,.v_i(1'b0)
                                        ,.data_i('0)
                                        ,.ready_o()

                                        ,.v_o(tr_v_lo[dramsim_i][i])
                                        ,.data_o(tr_data_lo[dramsim_i][i])
                                        ,.yumi_i(tr_yumi_li[dramsim_i][i])

                                        ,.rom_addr_o(rom_addr[dramsim_i][i])
                                        ,.rom_data_i(rom_data[dramsim_i][i])

                                        ,.done_o(ch_done[dramsim_i][i])
                                        ,.error_o()
                                        );

      assign dramsim3_write_not_read_li[dramsim_i][i] = tr_data_lo[dramsim_i][i].write_not_read;
      assign dramsim3_ch_addr_li[dramsim_i][i] = tr_data_lo[dramsim_i][i].ch_addr;
      assign dramsim3_v_li[dramsim_i][i] = tr_v_lo[dramsim_i][i];
      assign tr_yumi_li[dramsim_i][i] = dramsim3_yumi_lo[dramsim_i][i];

    end // for (genvar i = 0; i < num_channels_p; i++)
  end // for (genvar dramsim_i = 0; dramsim_i < num_dramsim3_p; dramsim_i++)


  for (genvar i = 0; i < num_channels_p; i++) begin
    bsg_nonsynth_test_rom #(.data_width_p(ring_width_p+4)
                            ,.addr_width_p(rom_addr_width_p)
                            ,.filename_p(`BSG_STRINGIFY(`rom_file))
                            ) rom0 (
                                    .addr_i(rom_addr[0][i])
                                    ,.data_o(rom_data[0][i])
                                    );

    bsg_nonsynth_test_rom #(.data_width_p(ring_width_p+4)
                            ,.addr_width_p(rom_addr_width_p)
                            ,.filename_p(`BSG_STRINGIFY(`rom_file_1))
                            ) rom1 (
                                    .addr_i(rom_addr[1][i])
                                    ,.data_o(rom_data[1][i])
                                    );
  end // for (genvar i = 0; i < num_channels_p; i++)



  initial begin
    # 10000000 $finish;
  end

  // always_ff @(posedge clk) begin
  //   if (~reset & dramsim3_v_li[0][0]) begin
  //     if (dramsim3_write_not_read_li[0][0])
  //       $display("write: 0x%08x {ro: %d, ba: %d, bg: %d, co: %d, byte: %d}",
  //                dramsim3_ch_addr_li[0][0],
  //                dramsim3_ch_addr_li_cast[0].ro,
  //                dramsim3_ch_addr_li_cast[0].ba,
  //                dramsim3_ch_addr_li_cast[0].bg,
  //                dramsim3_ch_addr_li_cast[0].co,
  //                dramsim3_ch_addr_li_cast[0].byte_offset);
  //     else
  //       $display("read: 0x%08x {ro: %d, ba: %d, bg: %d, co: %d, byte: %d}",
  //                dramsim3_ch_addr_li[0][0],
  //                dramsim3_ch_addr_li_cast[0].ro,
  //                dramsim3_ch_addr_li_cast[0].ba,
  //                dramsim3_ch_addr_li_cast[0].bg,
  //                dramsim3_ch_addr_li_cast[0].co,
  //                dramsim3_ch_addr_li_cast[0].byte_offset);
  //   end
  // end

endmodule
