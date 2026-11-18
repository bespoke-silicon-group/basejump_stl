`include "bsg_defines.sv"
`include "bsg_cache.svh"

// TAGST rewrites the tag of one way, chosen by the address bits above the set
// index. It must clear only that way's dirty bit: the other ways in the set may
// hold lines that are not yet written back. Case A fills a set with dirty lines,
// invalidates one way with TAGST, then flushes and reloads the other three.
// Case B is a control: retagging a dirty way must still clean that way, so its
// old data is never written to the new address. Run with word tracking off/on
// and response backpressure. The DMA model is the common, unmodified one.
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

    // A: four dirty lines in set 0 fill ways 0-3 (empty ways fill lowest first).
    // Invalidating way 2 with TAGST must leave ways 0, 1 and 3 dirty.
    add(SW,     10'h000, 32'ha0a0a0a0);
    add(SW,     10'h040, 32'ha1a1a1a1);
    add(SW,     10'h080, 32'ha2a2a2a2);
    add(SW,     10'h0c0, 32'ha3a3a3a3);
    add(TAGST,  tagst_addr(2, 0));                 // data 0: invalid
    add(AFLINV, 10'h000);
    add(AFLINV, 10'h040);
    add(AFLINV, 10'h0c0);
    add(LW,     10'h000, '0, '0, 1, 32'ha0a0a0a0, "way 0 kept after TAGST to way 2");
    add(LW,     10'h040, '0, '0, 1, 32'ha1a1a1a1, "way 1 kept after TAGST to way 2");
    add(LW,     10'h0c0, '0, '0, 1, 32'ha3a3a3a3, "way 3 kept after TAGST to way 2");
    add(LW,     10'h080, '0, '0, 1, '0,           "way 2 discarded by its TAGST");

    // B: retag a dirty way (set 1, way 0) as valid with tag 4 (address 0x120).
    // Its dirty bit must be cleared, so AFLINV writes nothing to 0x120.
    add(SW,     10'h020, 32'hb0b0b0b0);
    add(TAGST,  tagst_addr(0, 1), 32'h80000004);   // valid, unlocked, tag 4
    add(AFLINV, 10'h120);
    add(LW,     10'h120, '0, '0, 1, '0, "retagged way not written back");
    add(LW,     10'h020, '0, '0, 1, '0, "store discarded with the retagged line");

    if (`RESPONSE_INTERVAL_P < 1)
      $fatal(1, "%m: response interval must be positive");
    repeat (10) @(posedge clk);
    #1 reset = 0;
    wait (received == request_count);
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
