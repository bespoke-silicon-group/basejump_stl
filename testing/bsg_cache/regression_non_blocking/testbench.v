/**
 *  testbench.v
 */


module testbench();
  import bsg_cache_non_blocking_pkg::*;

  // parameters
  //
  parameter id_width_p = 30;
  parameter addr_width_p = 32;
  parameter data_width_p = 32;
  parameter block_size_in_words_p = 8;
  parameter sets_p = 128;
  parameter ways_p = 8;
  parameter miss_fifo_els_p = `MISS_FIFO_ELS_P;
  parameter data_mask_width_lp=(data_width_p>>3);
  parameter mem_size_p = 2**15;

  parameter dma_read_delay_p  = `DMA_READ_DELAY_P;
  parameter dma_write_delay_p = `DMA_WRITE_DELAY_P;
  parameter dma_data_delay_p  = `DMA_DATA_DELAY_P;
  parameter dma_req_delay_p   = `DMA_REQ_DELAY_P;
  parameter yumi_max_delay_p  = `YUMI_MAX_DELAY_P;
  parameter yumi_min_delay_p  = `YUMI_MIN_DELAY_P;

  localparam lg_ways_lp = `BSG_SAFE_CLOG2(ways_p);
  localparam lg_sets_lp = `BSG_SAFE_CLOG2(sets_p);
  localparam lg_block_size_in_words_lp = `BSG_SAFE_CLOG2(block_size_in_words_p);
  localparam byte_sel_width_lp = `BSG_SAFE_CLOG2(data_width_p>>3);
  localparam tag_width_lp = (addr_width_p-lg_sets_lp-lg_block_size_in_words_lp-byte_sel_width_lp);
  localparam block_offset_width_lp = lg_block_size_in_words_lp+byte_sel_width_lp;

  // synopsys translate_off
  integer status;
  integer wave;
  string checker;

  initial begin
    status = $value$plusargs("wave=%d",wave);
    status = $value$plusargs("checker=%s",checker);
    if (wave) $vcdpluson;
  end


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
    ,.reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(8)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );
  // synopsys translate_on


  // non-blocking cache
  //
  `declare_bsg_cache_non_blocking_pkt_s(id_width_p,addr_width_p,data_width_p);
  bsg_cache_non_blocking_pkt_s cache_pkt;

  logic cache_v_li;
  logic cache_ready_lo;

  logic [id_width_p-1:0] cache_id_lo;
  logic [data_width_p-1:0] cache_data_lo;
  logic cache_v_lo;
  logic cache_yumi_li;

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
  );

  // synopsys translate_off

  // random yumi generator
  //
  bsg_nonsynth_random_yumi_gen #(
    .yumi_min_delay_p(yumi_min_delay_p)
    ,.yumi_max_delay_p(yumi_max_delay_p)
  ) yumi_gen (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.v_i(cache_v_lo)
    ,.yumi_o(cache_yumi_li)
  ); 

  // dma model
  //
  bsg_nonsynth_non_blocking_dma_model #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.els_p(4*ways_p*sets_p*block_size_in_words_p)
    ,.read_delay_p(dma_read_delay_p)
    ,.write_delay_p(dma_write_delay_p)
    ,.dma_data_delay_p(dma_data_delay_p)
    ,.dma_req_delay_p(dma_req_delay_p)
  ) dma_model (
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


  // trace replay
  //
  localparam rom_addr_width_lp = 26; 
  localparam ring_width_lp =
    `bsg_cache_non_blocking_pkt_width(id_width_p,addr_width_p,data_width_p);

  logic [rom_addr_width_lp-1:0] trace_rom_addr;
  logic [ring_width_lp+4-1:0] trace_rom_data;
  
  logic tr_v_lo;
  logic [ring_width_lp-1:0] tr_data_lo;
  logic tr_yumi_li;
  logic done;

  bsg_fsb_node_trace_replay #(
    .ring_width_p(ring_width_lp)
    ,.rom_addr_width_p(rom_addr_width_lp)
  ) trace_replay (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.en_i(1'b1)

    ,.v_i(1'b0)
    ,.data_i('0)
    ,.ready_o()

    ,.v_o(tr_v_lo)
    ,.data_o(tr_data_lo)
    ,.yumi_i(tr_yumi_li)

    ,.rom_addr_o(trace_rom_addr)
    ,.rom_data_i(trace_rom_data)

    ,.done_o(done)
    ,.error_o()
  );

  bsg_nonsynth_test_rom #(
    .filename_p("trace.tr")
    ,.data_width_p(ring_width_lp+4)
    ,.addr_width_p(rom_addr_width_lp)
  ) test_rom (
    .addr_i(trace_rom_addr)
    ,.data_o(trace_rom_data)
  );


  assign cache_pkt = tr_data_lo;
  assign cache_v_li = tr_v_lo;
  assign tr_yumi_li = tr_v_lo & cache_ready_lo;


  bind bsg_cache_non_blocking basic_checker #(
    .data_width_p(data_width_p)
    ,.id_width_p(id_width_p)
    ,.addr_width_p(addr_width_p)
    ,.cache_pkt_width_lp(cache_pkt_width_lp)
    ,.mem_size_p($root.testbench.mem_size_p)
  ) bc (
    .*
    ,.en_i($root.testbench.checker == "basic")
  );


  bind bsg_cache_non_blocking tag_checker #(
    .data_width_p(data_width_p)
    ,.id_width_p(id_width_p)
    ,.addr_width_p(addr_width_p)
    ,.tag_width_lp(tag_width_lp)
    ,.ways_p(ways_p)
    ,.sets_p(sets_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.cache_pkt_width_lp(cache_pkt_width_lp)
  ) tc (
    .*
    ,.en_i($root.testbench.checker == "tag")
  );

  bind bsg_cache_non_blocking ainv_checker #(
    .data_width_p(data_width_p)
  ) ac (
    .*
    ,.en_i($root.testbench.checker == "ainv")
  );

  bind bsg_cache_non_blocking block_ld_checker #(
    .data_width_p(data_width_p)
    ,.id_width_p(id_width_p)
    ,.addr_width_p(addr_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.cache_pkt_width_lp(cache_pkt_width_lp)
    ,.mem_size_p($root.testbench.mem_size_p)
  ) blc (
    .*
    ,.en_i($root.testbench.checker == "block_ld")
  );


  //                        //
  //  FUNCTIONAL COVERAGE   //
  //                        //

  bind bsg_cache_non_blocking cov_top _cov_top (.*);
  bind bsg_cache_non_blocking_tl_stage cov_tl_stage _cov_tl_stage (.*);
  bind bsg_cache_non_blocking_mhu cov_mhu _cov_mhu (.*);
  bind bsg_cache_non_blocking_miss_fifo cov_miss_fifo _cov_miss_fifo (.*);



  // waiting for all responses to be received.
  //
  integer sent_r, recv_r;

  always_ff @ (posedge clk) begin
    if (reset) begin
      sent_r <= '0;
      recv_r <= '0;
    end
    else begin

      if (cache_v_li & cache_ready_lo)
        if (cache_pkt.opcode == BLOCK_LD)
          sent_r <= sent_r + block_size_in_words_p;
        else 
          sent_r <= sent_r + 1;

      if (cache_v_lo & cache_yumi_li)
        recv_r <= recv_r + 1;

    end
  end



  initial begin
    wait(done & (sent_r == recv_r));
    $display("[BSG_FINISH] Test Successful.");
    //for (integer i = 0; i < 1000000; i++)
    //  @(posedge clk);
    #500;
    $finish;
  end

  // synopsys translate_on

endmodule
