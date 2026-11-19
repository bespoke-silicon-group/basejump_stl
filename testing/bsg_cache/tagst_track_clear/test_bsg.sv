`include "bsg_defines.sv"
`include "bsg_cache.svh"

// TAGST must clear the track bits of the way it writes: a line set up with
// TAGST has no word present yet, as after a store-miss allocation. Each case
// puts known data in memory, leaves a way holding a fully tracked line, and
// reuses that way with TAGST. A1: a load fills from memory. A2: a full-word
// store and AFLINV write back only that word. A3: a byte store merges with
// memory, and AFLINV keeps the other words. Needs word tracking; run with
// response backpressure. A load that misses returns the word straight from
// the refill, so A1 reads again to check the copy the cache kept. No store is
// issued just before a TAGST: TAGST does not wait for the store and track
// buffers, so a buffered store to the same line could re-mark its word.
module test_bsg;
  import bsg_cache_pkg::*;

  localparam addr_width_lp = 10;
  localparam data_width_lp = 32;
  localparam block_words_lp = 8;
  localparam sets_lp = 2;
  localparam ways_lp = 4;
  localparam mem_words_lp = 256;
  localparam block_offset_lp = $clog2(block_words_lp * (data_width_lp/8));
  localparam way_offset_lp = block_offset_lp + $clog2(sets_lp);
  localparam max_requests_lp = 64;

  bit clk;
  bit reset = 1;
  bsg_nonsynth_clock_gen #(.cycle_time_p(10)) clock_gen (.o(clk));

  `declare_bsg_cache_pkt_s(addr_width_lp, data_width_lp);
  `declare_bsg_cache_dma_pkt_s(addr_width_lp, block_words_lp);

  bsg_cache_pkt_s cache_pkt = '0;
  logic v_li = 0, yumi_lo, v_lo, yumi_li;
  logic [data_width_lp-1:0] data_lo;
  bsg_cache_dma_pkt_s dma_pkt;
  logic dma_pkt_v, dma_pkt_yumi;
  logic dma_data_v_li, dma_data_ready, dma_data_v_lo, dma_data_yumi;
  logic [data_width_lp-1:0] dma_data_li, dma_data_lo;

  bsg_cache #(.addr_width_p(addr_width_lp)
              ,.data_width_p(data_width_lp)
              ,.block_size_in_words_p(block_words_lp)
              ,.sets_p(sets_lp)
              ,.ways_p(ways_lp)
              ,.word_tracking_p(`WORD_TRACKING_P)
              ) dut
    (.clk_i(clk)
     ,.reset_i(reset)
     ,.cache_pkt_i(cache_pkt)
     ,.v_i(v_li)
     ,.yumi_o(yumi_lo)
     ,.data_o(data_lo)
     ,.v_o(v_lo)
     ,.yumi_i(yumi_li)
     ,.dma_pkt_o(dma_pkt)
     ,.dma_pkt_v_o(dma_pkt_v)
     ,.dma_pkt_yumi_i(dma_pkt_yumi)
     ,.dma_data_i(dma_data_li)
     ,.dma_data_v_i(dma_data_v_li)
     ,.dma_data_ready_and_o(dma_data_ready)
     ,.dma_data_o(dma_data_lo)
     ,.dma_data_v_o(dma_data_v_lo)
     ,.dma_data_yumi_i(dma_data_yumi)
     ,.v_we_o()
     );

  bsg_nonsynth_dma_model #(.addr_width_p(addr_width_lp)
                           ,.data_width_p(data_width_lp)
                           ,.mask_width_p(block_words_lp)
                           ,.block_size_in_words_p(block_words_lp)
                           ,.els_p(mem_words_lp)
                           ) dma
    (.clk_i(clk)
     ,.reset_i(reset)
     ,.dma_pkt_i(dma_pkt)
     ,.dma_pkt_v_i(dma_pkt_v)
     ,.dma_pkt_yumi_o(dma_pkt_yumi)
     ,.dma_data_o(dma_data_li)
     ,.dma_data_v_o(dma_data_v_li)
     ,.dma_data_ready_i(dma_data_ready)
     ,.dma_data_i(dma_data_lo)
     ,.dma_data_v_i(dma_data_v_lo)
     ,.dma_data_yumi_o(dma_data_yumi)
     );

  bsg_cache_pkt_s requests [max_requests_lp];
  bit check_response [max_requests_lp];
  logic [data_width_lp-1:0] expected [max_requests_lp];
  string descriptions [max_requests_lp];
  int request_count = 0, sent = 0, received = 0, checked = 0, errors = 0;
  int cycles = 0;
  bit started = 0;

  task automatic add(input bsg_cache_opcode_e op
                     , input logic [addr_width_lp-1:0] addr
                     , input logic [data_width_lp-1:0] data = '0
                     , input logic [data_width_lp/8-1:0] mask = '0
                     , input bit check_value = 0
                     , input logic [data_width_lp-1:0] expected_value = '0
                     , input string description = ""
                     );
    if (request_count == max_requests_lp)
      $fatal(1, "%m: request table is full");
    requests[request_count] = {op, addr, data, mask};
    check_response[request_count] = check_value;
    expected[request_count] = expected_value;
    descriptions[request_count] = description;
    request_count++;
  endtask

  // TAGST address: the way sits above the set and block-offset bits.
  function automatic logic [addr_width_lp-1:0] tagst_addr(input int way, input int set);
    return addr_width_lp'((way << way_offset_lp) | (set << block_offset_lp));
  endfunction

  assign yumi_li = v_lo & ((cycles % `RESPONSE_INTERVAL_P) == 0);

  always @(posedge clk) begin
    cycles <= cycles + 1;
    if (reset) begin
      v_li <= 0;
      started <= 0;
    end
    else begin
      if (!started) begin
        started <= 1;
        cache_pkt <= requests[0];
        v_li <= 1;
      end
      else if (v_li && yumi_lo) begin
        sent++;
        if (sent < request_count)
          cache_pkt <= requests[sent];
        else
          v_li <= 0;
      end

      if (v_lo && yumi_li) begin
        if (received >= sent)
          $fatal(1, "%m: response without a pending request");
        if (check_response[received]) begin
          checked++;
          if (data_lo !== expected[received]) begin
            errors++;
            $display("[BSG_ERROR] %s: got %h, expected %h",
                     descriptions[received], data_lo, expected[received]);
          end
        end
        received++;
      end
    end
  end

  initial begin
    // Clear every tag: invalid, unlocked, clean.
    for (int i = 0; i < ways_lp * sets_lp; i++)
      add(TAGST, tagst_addr(i / sets_lp, i % sets_lp));

    if (`WORD_TRACKING_P == 0)
      $fatal(1, "%m: this test needs word tracking");

    // Known data in memory for the lines TAGST will set up. Each store
    // allocates a way, and AFLINV writes the stored words back and frees it.
    add(SW,     10'h104, 32'h11110001);                  // A1: 0x100, tag 4, set 0
    add(AFLINV, 10'h100);
    add(SW,     10'h140, 32'h22220000);                  // A3: 0x140, tag 5, set 0
    add(SW,     10'h15c, 32'h22220007);
    add(AFLINV, 10'h140);
    add(SW,     10'h184, 32'h33330001);                  // A2: 0x180, tag 6, set 0
    add(AFLINV, 10'h180);

    // Fully tracked lines of zeros from memory in set 0, ways 0-2 (empty ways
    // fill lowest first). TAGST discards them below.
    add(LW,     10'h000, '0, '0, 1, '0, "fill way 0");
    add(LW,     10'h040, '0, '0, 1, '0, "fill way 1");
    add(LW,     10'h080, '0, '0, 1, '0, "fill way 2");

    // A1: way 0 becomes 0x100. A load must fill from memory.
    add(TAGST,  tagst_addr(0, 0), 32'h80000004);         // valid, tag 4
    add(LW,     10'h104, '0, '0, 1, 32'h11110001, "A1 load fills from memory");
    add(LW,     10'h104, '0, '0, 1, 32'h11110001, "A1 cached word matches memory");

    // A3: way 1 becomes 0x140. A byte store merges with memory's word.
    add(TAGST,  tagst_addr(1, 0), 32'h80000005);         // valid, tag 5
    add(SB,     10'h141, 32'h000000ee);
    add(AFLINV, 10'h140);
    add(LW,     10'h140, '0, '0, 1, 32'h2222ee00, "A3 byte store merges with memory");
    add(LW,     10'h15c, '0, '0, 1, 32'h22220007, "A3 write-back keeps memory's words");

    // A2: way 2 becomes 0x180. A full-word store writes back only that word.
    add(TAGST,  tagst_addr(2, 0), 32'h80000006);         // valid, tag 6
    add(SW,     10'h180, 32'h33ff0000);
    add(AFLINV, 10'h180);
    add(LW,     10'h184, '0, '0, 1, 32'h33330001, "A2 write-back keeps memory's words");
    add(LW,     10'h180, '0, '0, 1, 32'h33ff0000, "A2 stored word written back");

    if (`RESPONSE_INTERVAL_P < 1)
      $fatal(1, "%m: response interval must be positive");
    repeat (10) @(posedge clk);
    #1 reset = 0;
    wait (received == request_count);
    // A repeated request would answer again; the response check above
    // then fails with no pending request.
    repeat (200) @(posedge clk);
    if (errors != 0)
      $fatal(1, "%m: %0d incorrect results with word tracking=%0d response interval=%0d",
             errors, `WORD_TRACKING_P, `RESPONSE_INTERVAL_P);
    $display("[BSG_FINISH] %0d requests, %0d values checked; word tracking=%0d response interval=%0d",
             received, checked, `WORD_TRACKING_P, `RESPONSE_INTERVAL_P);
    $finish;
  end

  initial begin
    repeat (100000) @(posedge clk);
    $fatal(1, "%m: timeout: %0d requests sent, %0d responses received", sent, received);
  end
endmodule
