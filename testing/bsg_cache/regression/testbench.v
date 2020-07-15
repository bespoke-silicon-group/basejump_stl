/**
 *  testbench.v
 */


module testbench();
  import bsg_cache_pkg::*;

  // parameters
  //

  parameter addr_width_p = 32;
  parameter data_width_p = 32;
  parameter block_size_in_words_p = 8;
  parameter sets_p = 512;
  parameter ways_p = `WAYS_P;

  parameter ring_width_p = `bsg_cache_pkt_width(addr_width_p, data_width_p);
  parameter rom_addr_width_p = 32;

  // clock and reset
  //
  bit clk;
  bit reset;

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

  // cache
  //
  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);
  bsg_cache_pkt_s cache_pkt;

  logic cache_v_li;
  logic cache_ready_lo;

  logic [data_width_p-1:0] cache_data_lo;
  logic cache_v_lo;
  logic cache_yumi_li;

  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo;
  logic dma_pkt_yumi_li;

  logic [data_width_p-1:0] dma_data_li;
  logic dma_data_v_li;
  logic dma_data_ready_lo;

  logic [data_width_p-1:0] dma_data_lo;
  logic dma_data_v_lo;
  logic dma_data_yumi_li;

  bsg_cache #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
    ,.amo_support_p(amo_support_level_arithmetic_lp)
  ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.cache_pkt_i(cache_pkt)
    ,.v_i(cache_v_li)
    ,.ready_o(cache_ready_lo)

    ,.data_o(cache_data_lo)
    ,.v_o(cache_v_lo)
    ,.yumi_i(cache_yumi_li)

    ,.dma_pkt_o(dma_pkt)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)
  
    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_o(dma_data_ready_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)

    ,.v_we_o() 
  );

  // output fifo
  //
  logic fifo_ready_lo;
  logic fifo_v_lo;
  logic fifo_yumi_li;
  logic [data_width_p-1:0] fifo_data_lo;

  bsg_fifo_1r1w_large #(
    .width_p(data_width_p)
    ,.els_p(1024)
  ) output_fifo (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.data_i(cache_data_lo)
    ,.v_i(cache_v_lo)
    ,.ready_o(fifo_ready_lo)

    ,.v_o(fifo_v_lo)
    ,.data_o(fifo_data_lo)
    ,.yumi_i(fifo_yumi_li)
  );

  assign cache_yumi_li = cache_v_lo & fifo_ready_lo;

  // trace_replay
  //
  logic [rom_addr_width_p-1:0] trace_rom_addr;
  logic [ring_width_p+4-1:0] trace_rom_data;

  logic [ring_width_p-1:0] tr_data_lo;
  logic [ring_width_p-1:0] tr_data_li;
  logic tr_ready_lo;
  logic tr_yumi_li;
  logic done;

  bsg_fsb_node_trace_replay #(
    .ring_width_p(ring_width_p)
    ,.rom_addr_width_p(rom_addr_width_p)
  ) trace_replay (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.en_i(1'b1)

    ,.v_i(fifo_v_lo)
    ,.data_i(tr_data_li)
    ,.ready_o(tr_ready_lo)

    ,.v_o(cache_v_li)
    ,.data_o(tr_data_lo)
    ,.yumi_i(tr_yumi_li)

    ,.rom_addr_o(trace_rom_addr)
    ,.rom_data_i(trace_rom_data)

    ,.done_o(done)
    ,.error_o()
  ); 

  bsg_trace_master_rom #(
    .width_p(ring_width_p+4)
    ,.addr_width_p(rom_addr_width_p)
  ) trace_rom (
    .addr_i(trace_rom_addr)
    ,.data_o(trace_rom_data)
  );

  assign fifo_yumi_li = fifo_v_lo & tr_ready_lo;
  assign tr_yumi_li = cache_v_li & cache_ready_lo;
  
  assign tr_data_li = {{(ring_width_p-data_width_p){1'b0}}, fifo_data_lo};

  assign cache_pkt = tr_data_lo;
  //assign cache_pkt.mask = tr_data_lo[data_width_p+addr_width_p+5+:(data_width_p>>3)];
  //assign cache_pkt.opcode = bsg_cache_opcode_e'(tr_data_lo[data_width_p+addr_width_p+:5]);
  //assign cache_pkt.addr = tr_data_lo[data_width_p+:addr_width_p];
  //assign cache_pkt.data = tr_data_lo[0+:data_width_p];

  
  // mock_dma
  //
  bsg_nonsynth_dma_model #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.els_p(2**18)
  ) dma (
    .clk_i(clk)
    ,.reset_i(reset)
    
    ,.dma_pkt_i(dma_pkt)
    ,.dma_pkt_v_i(dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

    ,.dma_data_o(dma_data_li)
    ,.dma_data_v_o(dma_data_v_li)
    ,.dma_data_ready_i(dma_data_ready_lo)

    ,.dma_data_i(dma_data_lo)
    ,.dma_data_v_i(dma_data_v_lo)
    ,.dma_data_yumi_o(dma_data_yumi_li)
  );


  initial begin
    wait(done)
    //for (integer i = 0; i < 100000; i++) begin
    //  @(posedge clk);
    //end
    $display("[BSG_FINISH] Test Successful.");
    $finish;
  end

endmodule
