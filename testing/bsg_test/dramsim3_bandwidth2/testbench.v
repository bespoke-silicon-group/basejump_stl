`include "bsg_nonsynth_dramsim3.svh"


`define dram_pkg bsg_dramsim3_hbm2_4gb_x128_pkg

module testbench();
  import bsg_cache_pkg::*;
  import `dram_pkg::*;
  
  // parameters
  parameter num_cache_p = `NUM_CACHE_P;
  parameter num_channels_p = `dram_pkg::num_channels_p;
  parameter channel_addr_width_p = `dram_pkg::channel_addr_width_p;
  parameter dram_data_width_p = `dram_pkg::data_width_p;

  // clock/reset
  bit dram_clk;
  bit core_clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg0 (
    .o(dram_clk)
  );

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg1 (
    .o(core_clk)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(2)
    ,.reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(4)
  ) rg0 (
    .clk_i({core_clk, dram_clk})
    ,.async_reset_o(reset)
  );


  // driver
  localparam cache_addr_width_lp = channel_addr_width_p;
  localparam data_width_p = 32;
  localparam dma_data_width_p = `DMA_DATA_WIDTH_P;
  localparam block_size_in_words_p = `BLOCK_SIZE_IN_WORDS_P;
  localparam sets_p = 128/(block_size_in_words_p/8);
  localparam ways_p = 8;
  
  
  logic [num_cache_p-1:0] cache_v_lo;

  `declare_bsg_cache_dma_pkt_s(cache_addr_width_lp);
  bsg_cache_dma_pkt_s [num_cache_p-1:0] dma_pkt_lo;
  logic [num_cache_p-1:0] dma_pkt_v_lo;
  logic [num_cache_p-1:0] dma_pkt_yumi_li;

  logic [num_cache_p-1:0][dma_data_width_p-1:0] dma_data_li;
  logic [num_cache_p-1:0] dma_data_v_li;
  logic [num_cache_p-1:0] dma_data_ready_lo;

  logic [num_cache_p-1:0][dma_data_width_p-1:0] dma_data_lo;
  logic [num_cache_p-1:0] dma_data_v_lo;
  logic [num_cache_p-1:0] dma_data_yumi_li;
  
  logic [num_cache_p-1:0] cache_done_lo;
  time first_access_time_lo [num_cache_p-1:0];
  integer load_count_lo [num_cache_p-1:0];
  integer store_count_lo [num_cache_p-1:0];

  for (genvar i = 0; i < num_cache_p; i++) begin

    if (1) begin
      // blocking
      vcache_blocking #(
        .id_p(i)
        ,.addr_width_p(cache_addr_width_lp)
        ,.data_width_p(data_width_p)
        ,.block_size_in_words_p(block_size_in_words_p)
        ,.sets_p(sets_p)
        ,.ways_p(ways_p)
        ,.dma_data_width_p(dma_data_width_p)
      ) vb (
        .clk_i(core_clk)
        ,.reset_i(reset)

        ,.cache_v_o(cache_v_lo[i])

        ,.dma_pkt_o(dma_pkt_lo[i])
        ,.dma_pkt_v_o(dma_pkt_v_lo[i])
        ,.dma_pkt_yumi_i(dma_pkt_yumi_li[i])

        ,.dma_data_i(dma_data_li[i])
        ,.dma_data_v_i(dma_data_v_li[i])
        ,.dma_data_ready_o(dma_data_ready_lo[i])

        ,.dma_data_o(dma_data_lo[i])
        ,.dma_data_v_o(dma_data_v_lo[i])
        ,.dma_data_yumi_i(dma_data_yumi_li[i])

        ,.done_o(cache_done_lo[i])
        ,.first_access_time_o(first_access_time_lo[i])
        ,.load_count_o(load_count_lo[i])
        ,.store_count_o(store_count_lo[i])
      );


    end
    else begin
      // TODO: non-blocking
    end
  end

  if (1) begin
    bind bsg_cache basic_checker #(
      .data_width_p(data_width_p)
      ,.addr_width_p(addr_width_p)
      ,.mem_size_p(2**27)
    ) bc (
      .*
      ,.en_i(1'b1)
    );
  end

  logic dram_req_v_lo;
  logic dram_write_not_read_lo;
  logic [channel_addr_width_p-1:0] dram_ch_addr_lo;
  logic dram_req_yumi_li;
  
  logic dram_data_v_lo;
  logic [dram_data_width_p-1:0] dram_data_lo;
  logic dram_data_yumi_li;

  logic dram_data_v_li;
  logic [dram_data_width_p-1:0] dram_data_li;
  logic [channel_addr_width_p-1:0] dram_ch_addr_li;

  
  bsg_cache_to_test_dram #(
    .num_cache_p(num_cache_p)
    ,.addr_width_p(cache_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.dma_data_width_p(dma_data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.cache_bank_addr_width_p(cache_addr_width_lp-$clog2(num_cache_p))

    ,.dram_channel_addr_width_p(channel_addr_width_p)
    ,.dram_data_width_p(dram_data_width_p)
  ) DUT (
    .core_clk_i(core_clk)
    ,.core_reset_i(reset)

    ,.dma_pkt_i(dma_pkt_lo)
    ,.dma_pkt_v_i(dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

    ,.dma_data_o(dma_data_li)
    ,.dma_data_v_o(dma_data_v_li)
    ,.dma_data_ready_i(dma_data_ready_lo)

    ,.dma_data_i(dma_data_lo)
    ,.dma_data_v_i(dma_data_v_lo)
    ,.dma_data_yumi_o(dma_data_yumi_li)

    ,.dram_clk_i(dram_clk)
    ,.dram_reset_i(reset)

    ,.dram_req_v_o(dram_req_v_lo)
    ,.dram_write_not_read_o(dram_write_not_read_lo)
    ,.dram_ch_addr_o(dram_ch_addr_lo)
    ,.dram_req_yumi_i(dram_req_yumi_li)

    ,.dram_data_v_o(dram_data_v_lo)
    ,.dram_data_o(dram_data_lo)
    ,.dram_data_yumi_i(dram_data_yumi_li)

    ,.dram_data_v_i(dram_data_v_li)
    ,.dram_data_i(dram_data_li)
    ,.dram_ch_addr_i(dram_ch_addr_li)
  );

  //  addr = 29
  typedef struct packed {
    logic [1:0] bg;
    logic [1:0] ba;
    logic [13:0] ro;
    logic [5:0] co;
    logic [4:0] byte_offset;
  } dram_ch_addr_s;

  dram_ch_addr_s dram_ch_addr_cast;
  assign dram_ch_addr_cast = dram_ch_addr_lo;


  // dramsim3
  //
  logic [num_channels_p-1:0] dramsim3_v_li;
  logic [num_channels_p-1:0] dramsim3_write_not_read_li;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] dramsim3_ch_addr_li;
  logic [num_channels_p-1:0] dramsim3_yumi_lo;

  logic [num_channels_p-1:0][dram_data_width_p-1:0] dramsim3_data_li;
  logic [num_channels_p-1:0] dramsim3_data_v_li;
  logic [num_channels_p-1:0] dramsim3_data_yumi_lo;

  logic [num_channels_p-1:0][dram_data_width_p-1:0] dramsim3_data_lo;
  logic [num_channels_p-1:0] dramsim3_data_v_lo;
  logic [num_channels_p-1:0][channel_addr_width_p-1:0] dramsim3_read_done_ch_addr_lo;


  bsg_nonsynth_dramsim3 #(
    .channel_addr_width_p(channel_addr_width_p)
    ,.data_width_p(dram_data_width_p)
    ,.num_channels_p(num_channels_p)

    ,.num_columns_p(`dram_pkg::num_columns_p)
    ,.num_rows_p(`dram_pkg::num_rows_p)
    ,.num_ba_p(`dram_pkg::num_ba_p)
    ,.num_bg_p(`dram_pkg::num_bg_p)
    ,.num_ranks_p(`dram_pkg::num_ranks_p)
    ,.size_in_bits_p(`dram_pkg::size_in_bits_p)
    ,.address_mapping_p(`dram_pkg::address_mapping_p)
    ,.config_p(`dram_pkg::config_p)
    ,.masked_p(0)
    ,.init_mem_p(1)

    ,.debug_p(1)
  ) dram0 (
    .clk_i(dram_clk)
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
    ,.read_done_ch_addr_o(dramsim3_read_done_ch_addr_lo)

    ,.write_done_o()
    ,.write_done_ch_addr_o()
  ); 

  typedef struct packed {
    logic [13:0] ro;
    logic [1:0] bg;
    logic [1:0] ba;
    logic [5:0] co;
    logic [4:0] byte_offset;
  } dram_ch_addr_rev_s;

  dram_ch_addr_rev_s dram_ch_addr_rev;
  assign dram_ch_addr_rev = dramsim3_read_done_ch_addr_lo[0];

  assign dramsim3_v_li[0] = dram_req_v_lo;
  assign dramsim3_write_not_read_li[0] = dram_write_not_read_lo;
  // remap
  assign dramsim3_ch_addr_li[0] = {
    dram_ch_addr_cast.ro,
    dram_ch_addr_cast.bg,
    dram_ch_addr_cast.ba,
    dram_ch_addr_cast.co,
    dram_ch_addr_cast.byte_offset
  };
  assign dram_req_yumi_li = dramsim3_yumi_lo[0];

  assign dramsim3_data_v_li[0] = dram_data_v_lo;
  assign dramsim3_data_li[0] = dram_data_lo;
  assign dram_data_yumi_li = dramsim3_data_yumi_lo[0];
  
  assign dram_data_v_li = dramsim3_data_v_lo[0];
  assign dram_data_li = dramsim3_data_lo[0];
  // remap
  assign dram_ch_addr_li = {
    dram_ch_addr_rev.bg,
    dram_ch_addr_rev.ba,
    dram_ch_addr_rev.ro,
    dram_ch_addr_rev.co,
    dram_ch_addr_rev.byte_offset
    
  };

  for (genvar i = 1; i < num_channels_p; i++) begin
    assign dramsim3_v_li[i] = 1'b0;
    assign dramsim3_write_not_read_li[i] = 1'b0;
    assign dramsim3_ch_addr_li[i] = '0;

    assign dramsim3_data_v_li[i] = 1'b0;
    assign dramsim3_data_li[i] = '0;
  end

  integer total_load_count;
  integer total_store_count;

  real bandwidth;
  real bandwidth_pct;

  initial begin
    wait(&cache_done_lo);
    total_load_count = 0;
    total_store_count = 0;
    for (integer i = 0; i < num_cache_p; i++) begin
      total_load_count += load_count_lo[i];
      total_store_count += store_count_lo[i];
    end


    $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    $display("all done.");
    $display("total_load_count = %d", total_load_count);
    $display("total_store_count = %d", total_store_count);
    $display("total time = %t (ps)", $time-first_access_time_lo[0]);
    bandwidth = (real'((total_load_count+total_store_count)*4))/($time-first_access_time_lo[0])*(10**12)/(10**9);
    bandwidth_pct = bandwidth / 32.0 * 100.0;
    $display("bandwidth = %f (GB/s) ( %f %%)", bandwidth, bandwidth_pct);
    $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    $display("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");


    #100000;
    $finish;
  end

  bind bsg_cache cache_miss_counter c0 (
    .*
  );

endmodule
