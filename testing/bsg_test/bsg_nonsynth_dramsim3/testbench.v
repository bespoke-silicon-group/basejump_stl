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
  
  logic [num_channels_p-1:0]                            dramsim3_v_li;
  logic [num_channels_p-1:0]                            dramsim3_write_not_read_li;
  logic [num_channels_p-1:0] [channel_addr_width_p-1:0] dramsim3_ch_addr_li;
  logic [num_channels_p-1:0]                            dramsim3_yumi_lo;

  logic [num_channels_p-1:0]                            dramsim3_data_v_li;
  logic [num_channels_p-1:0] [data_width_p-1:0]         dramsim3_data_li;
  logic [num_channels_p-1:0]                            dramsim3_data_yumi_lo;

  logic [num_channels_p-1:0]                            dramsim3_data_v_lo;
  logic [num_channels_p-1:0] [data_width_p-1:0]         dramsim3_data_lo;

  `dram_pkg::dram_ch_addr_s dramsim3_ch_addr_li_cast;
  assign dramsim3_ch_addr_li_cast = dramsim3_ch_addr_li[0];

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

       ,.v_i(dramsim3_v_li)
       ,.write_not_read_i(dramsim3_write_not_read_li)
       ,.ch_addr_i(dramsim3_ch_addr_li)
       ,.yumi_o(dramsim3_yumi_lo)

       ,.data_v_i(dramsim3_data_v_li)
       ,.data_i(dramsim3_data_li)
       ,.mask_i('0)
       ,.data_yumi_o(dramsim3_data_yumi_lo)
      
       ,.data_v_o(dramsim3_data_v_lo)
       ,.data_o(dramsim3_data_lo)
       ,.read_done_ch_addr_o()

       ,.write_done_o()
       ,.write_done_ch_addr_o()
       );

  // trace replay
  //
  typedef struct packed {
    logic write_not_read;
    logic [channel_addr_width_p-1:0] ch_addr;
  } dramsim3_trace_s;

  localparam ring_width_p = $bits(dramsim3_trace_s);
  localparam rom_addr_width_p=20;

  dramsim3_trace_s [num_channels_p-1:0] tr_data_lo;
  logic [num_channels_p-1:0] tr_v_lo;
  logic [num_channels_p-1:0] tr_yumi_li;

  logic [num_channels_p-1:0][4+ring_width_p-1:0] rom_data;
  logic [num_channels_p-1:0][rom_addr_width_p-1:0] rom_addr;

  logic [num_channels_p-1:0] ch_done;

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

      ,.v_o(tr_v_lo[i])
      ,.data_o(tr_data_lo[i])
      ,.yumi_i(tr_yumi_li[i])

      ,.rom_addr_o(rom_addr[i])
      ,.rom_data_i(rom_data[i])

      ,.done_o(ch_done[i])
      ,.error_o()
    );

    bsg_nonsynth_test_rom #(
      .data_width_p(ring_width_p+4)
      ,.addr_width_p(rom_addr_width_p)
      ,.filename_p(`BSG_STRINGIFY(`rom_file))
    ) rom0 (
      .addr_i(rom_addr[i])
      ,.data_o(rom_data[i]) 
    );

    assign dramsim3_write_not_read_li[i] = tr_data_lo[i].write_not_read;
    assign dramsim3_ch_addr_li[i] = tr_data_lo[i].ch_addr;
    assign dramsim3_v_li[i] = tr_v_lo[i];
    assign tr_yumi_li[i] = dramsim3_yumi_lo[i];

  end

  
   logic done;

   bsg_reduce #(
     .width_p(num_channels_p)
     ,.and_p(1)
   ) reduce_done (
     .i(ch_done)
     ,.o(done)
   );

  initial begin
    # 10000000 $finish;
  end
  
  always_ff @(posedge clk) begin
    if (~reset & dramsim3_v_li[0]) begin
      if (dramsim3_write_not_read_li[0])
        $display("write: 0x%08x {ro: %d, ba: %d, bg: %d, co: %d, byte: %d}",
                 dramsim3_ch_addr_li[0],
                 dramsim3_ch_addr_li_cast.ro,
                 dramsim3_ch_addr_li_cast.ba,
                 dramsim3_ch_addr_li_cast.bg,
                 dramsim3_ch_addr_li_cast.co,
                 dramsim3_ch_addr_li_cast.byte_offset);
      else
        $display("read: 0x%08x {ro: %d, ba: %d, bg: %d, co: %d, byte: %d}",
                 dramsim3_ch_addr_li[0],
                 dramsim3_ch_addr_li_cast.ro,
                 dramsim3_ch_addr_li_cast.ba,
                 dramsim3_ch_addr_li_cast.bg,
                 dramsim3_ch_addr_li_cast.co,
                 dramsim3_ch_addr_li_cast.byte_offset);
    end    
  end
  
endmodule
