/**
 *  testbench.v
 */


module testbench();
  import bsg_cache_non_blocking_pkg::*;

  // parameters
  //
  parameter id_width_p = 16;
  parameter addr_width_p = 32;
  parameter data_width_p = 32;
  parameter block_size_in_words_p = 8;
  parameter sets_p = 128;
  parameter ways_p = 8;
  parameter miss_fifo_els_p = 23;


  // clock and reset
  //
  logic clk;
  logic reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(100)
  ) clock_gen (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(1)
    ,.reset_cycles_hi_p(100)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  // non-blocking cache
  //
  `declare_bsg_cache_non_blocking_pkt_s(id_width_p,addr_width_p,data_width_p);
  bsg_cache_non_blocking_pkt_s cache_pkt;

  logic cache_v_li;
  logic cache_ready_lo;

  logic [id_width_p-1:0] cache_id_lo;
  logic [data_width_p-1:0] cache_data_lo;
  logic cache_v_lo;

  `declare_bsg_cache_non_blocking_dma_pkt_s(addr_width_p);
  bsg_cache_non_blocking_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo;
  logic dma_pkt_yumi_li;

  logic [data_width_p-1:0] dma_data_li;
  logic dma_data_v_li;
  logic dma_data_ready_lo;

  logic [data_width_p-1:0] dma_data_lo;
  logic dma_data_v_lo;
  logic dma_data_yumi_li;

  bsg_cache_non_blocking #(
    .id_width_p(id_width_p)
    ,.addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
    ,.miss_fifo_els_p(miss_fifo_els_p)
  ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.cache_pkt_i(cache_pkt)
    ,.v_i(cache_v_li)
    ,.ready_o(cache_ready_lo)

    ,.data_o(cache_data_lo)
    ,.id_o(cache_id_lo)
    ,.v_o(cache_v_lo)

    ,.dma_pkt_o(dma_pkt)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)
  
    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_o(dma_data_ready_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)
  );

  assign cache_pkt = '0;
  assign cache_v_li = 1'b0;

  assign dma_pkt_yumi_li = 1'b0;
   
  assign dma_data_v_li = 1'b0;
  assign dma_data_li = '0;

  assign dma_data_yumi_li = 1'b0;



  initial begin
    #100;
    $finish;
  end

endmodule
