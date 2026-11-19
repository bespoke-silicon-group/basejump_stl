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
  `include "bsg_nonsynth_cache_directed_test.svh"

  initial begin
    clear_tags();

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

    run_requests();
    // The initial tag sweep streams when every response is taken at once.
    if (`RESPONSE_INTERVAL_P == 1)
      for (int i = 1; i < ways_lp * sets_lp; i++)
        if (accept_cycle[i] != accept_cycle[i-1] + 1) begin
          errors++;
          $display("[BSG_ERROR] TAGST %0d of the tag sweep accepted %0d cycles after the previous one",
                   i, accept_cycle[i] - accept_cycle[i-1]);
        end
    finish_test();
  end
endmodule
