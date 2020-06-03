module testbench();

  import bsg_cache_pkg::*;

  // clock/reset
  bit clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(20)
  ) cg (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(10)
  ) rg (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );


  // parameters
  localparam addr_width_p = 30;
  localparam data_width_p = 32;
  localparam block_size_in_words_p = 8;
  localparam sets_p = 128;
  localparam ways_p = 8;
  localparam mem_size_p = block_size_in_words_p*sets_p*ways_p*4;


  integer status;
  integer wave;
  string checker;
  initial begin
    status = $value$plusargs("wave=%d",wave);
    status = $value$plusargs("checker=%s",checker);
    $display("checker=%s", checker);
    if (wave) $vcdpluson;
  end



  `declare_bsg_cache_pkt_s(addr_width_p,data_width_p);
  `declare_bsg_cache_dma_pkt_s(addr_width_p);

  bsg_cache_pkt_s cache_pkt;
  logic v_li;
  logic ready_lo;

  logic [data_width_p-1:0] cache_data_lo;
  logic v_lo;
  logic yumi_li;

  bsg_cache_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo;
  logic dma_pkt_yumi_li;

  logic [data_width_p-1:0] dma_data_li;
  logic dma_data_v_li;
  logic dma_data_ready_lo;

  logic [data_width_p-1:0] dma_data_lo;
  logic dma_data_v_lo;
  logic dma_data_yumi_li;

  // DUT
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
    ,.v_i(v_li)
    ,.ready_o(ready_lo)

    ,.data_o(cache_data_lo)
    ,.v_o(v_lo)
    ,.yumi_i(yumi_li)

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

  // random yumi generator
  bsg_nonsynth_random_yumi_gen #(
    .yumi_min_delay_p(`YUMI_MIN_DELAY_P)
    ,.yumi_max_delay_p(`YUMI_MAX_DELAY_P)
  ) yumi_gen (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.v_i(v_lo)
    ,.yumi_o(yumi_li)
  );

  // DMA model
  bsg_nonsynth_dma_model #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.els_p(mem_size_p)

    ,.read_delay_p(`DMA_READ_DELAY_P)
    ,.write_delay_p(`DMA_WRITE_DELAY_P)
    ,.dma_req_delay_p(`DMA_REQ_DELAY_P)
    ,.dma_data_delay_p(`DMA_DATA_DELAY_P)

  ) dma0 (
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
  localparam rom_addr_width_lp = 26;
  localparam ring_width_lp = `bsg_cache_pkt_width(addr_width_p,data_width_p);

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
  ) trom (
    .addr_i(trace_rom_addr)
    ,.data_o(trace_rom_data)
  );
  
  assign cache_pkt = tr_data_lo;
  assign v_li = tr_v_lo;
  assign tr_yumi_li = tr_v_lo & ready_lo;

  bind bsg_cache basic_checker #(
    .data_width_p(data_width_p)
    ,.addr_width_p(addr_width_p)
    ,.mem_size_p($root.testbench.mem_size_p)
  ) bc (
    .*
    ,.en_i($root.testbench.checker == "basic")
  );

  // wait for all responses to be received.
  integer sent_r, recv_r;

  always_ff @ (posedge clk) begin
    if (reset) begin
      sent_r <= '0;
      recv_r <= '0;
    end
    else begin
      if (v_li & ready_lo)
        sent_r <= sent_r + 1;

      if (v_lo & yumi_li)
        recv_r <= recv_r + 1;
    end
  end

  initial begin
    wait(done & (sent_r == recv_r));
    $display("[BSG_FINISH] Test Successful.");
    #500;
    $finish;
  end

endmodule
