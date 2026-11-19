`include "bsg_defines.sv"
`include "bsg_cache.svh"

// TAGST writes a tag directly as it enters the pipeline, outside the miss
// handler, so the cache must hold it until the requests ahead of it are done.
// A: a load miss just ahead of a TAGST to the way the miss will fill; TAGLA
// must read back the tag TAGST wrote, not the filled line's. B: the same with
// a store miss. C (word tracking off): a store hit just ahead of a TAGST that
// renames its line; the renamed line must hold the stored word. D: an AFLINV
// of a dirty line just ahead of a TAGST to its way; the flush must still write
// the line back, and must not clear the valid bit the TAGST sets. After the
// last response, the test watches for extra responses. TAGSTs may still follow
// each other back to back: with every response taken at once, the initial tag
// sweep must be accepted one TAGST per cycle.
// Run with word tracking off/on and response backpressure.
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
  int accept_cycle [max_requests_lp];
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
        accept_cycle[sent] = cycles;
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

    // A: load miss to set 1 (fills way 0, the lowest invalid), then a TAGST to
    // way 0 with tag 7 (address 0x1e0). TAGLA must return the TAGST's tag.
    add(LW,    10'h060, '0, '0, 1, '0, "load miss ahead of the TAGST");
    add(TAGST, tagst_addr(0, 1), 32'h80000007);          // valid, tag 7
    add(TAGLA, tagst_addr(0, 1), '0, '0, 1, 32'h000001e0, "TAGST after an older load miss");

    // B: store miss to set 1 (allocates way 1), then a TAGST to way 1 with
    // tag 8 (address 0x220).
    add(SW,    10'h0a0, 32'h12345678);
    add(TAGST, tagst_addr(1, 1), 32'h80000008);          // valid, tag 8
    add(TAGLA, tagst_addr(1, 1), '0, '0, 1, 32'h00000220, "TAGST after an older store miss");

    // C (word tracking off): load 0x100 into set 0, way 0; store to it; rename
    // way 0 to tag 5 (address 0x140). The renamed line must hold the stored word.
    if (`WORD_TRACKING_P == 0) begin
      add(LW,    10'h100, '0, '0, 1, '0, "load before the store");
      add(SW,    10'h100, 32'h66660000);
      add(TAGST, tagst_addr(0, 0), 32'h80000005);        // valid, tag 5
      add(LW,    10'h140, '0, '0, 1, 32'h66660000, "store lands before the rename");
    end

    // D: a dirty line in set 1, way 2 (a store miss, then a load that hits),
    // then AFLINV of the line just ahead of a TAGST that gives way 2 to tag 9
    // (address 0x260). The flush must still write the line back, and must not
    // clear the valid bit the TAGST sets.
    add(SW,     10'h2e4, 32'h77770001);
    add(LW,     10'h2e4, '0, '0, 1, 32'h77770001, "load hit ahead of the flush");
    add(AFLINV, 10'h2e0);
    add(TAGST,  tagst_addr(2, 1), 32'h80000009);         // valid, tag 9
    add(TAGLV,  tagst_addr(2, 1), '0, '0, 1, 32'h00000001, "TAGST after an older AFLINV");
    add(LW,     10'h2e4, '0, '0, 1, 32'h77770001, "flush ahead of the TAGST wrote the line back");

    if (`RESPONSE_INTERVAL_P < 1)
      $fatal(1, "%m: response interval must be positive");
    repeat (10) @(posedge clk);
    #1 reset = 0;
    wait (received == request_count);
    // A repeated request would answer again; the response check above
    // then fails with no pending request.
    repeat (200) @(posedge clk);
    // The initial tag sweep streams when every response is taken at once.
    if (`RESPONSE_INTERVAL_P == 1)
      for (int i = 1; i < ways_lp * sets_lp; i++)
        if (accept_cycle[i] != accept_cycle[i-1] + 1) begin
          errors++;
          $display("[BSG_ERROR] TAGST %0d of the tag sweep accepted %0d cycles after the previous one",
                   i, accept_cycle[i] - accept_cycle[i-1]);
        end
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
