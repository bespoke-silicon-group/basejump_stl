`include "bsg_defines.sv"
`include "bsg_cache.svh"

// TAGST must clear the track bits of the way it writes: a line set up with
// TAGST has no word present yet, as after a store-miss allocation. Each case
// puts known data in memory, leaves a way holding a fully tracked line with
// other data, and reuses that way with TAGST. A1: a load fills from memory.
// A2: a full-word store and AFLINV write back only that word. A3: a byte store
// merges with memory, and AFLINV keeps the other words. B: a store just ahead
// of a TAGST that renames its line must not leave its track bit in the renamed
// line (this also needs TAGST to wait for the requests ahead of it). Needs
// word tracking; run with response backpressure. A load that misses returns
// the word straight from the refill, so A1 and B read again to check the copy
// the cache kept.
module test_bsg;
  `include "bsg_nonsynth_cache_directed_test.svh"

  initial begin
    clear_tags();

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
    add(SW,     10'h120, 32'h55550000);                  // B: 0x120, tag 4, set 1
    add(AFLINV, 10'h120);

    // Fully tracked lines with other data in set 0, ways 0-2 (empty ways
    // fill lowest first). TAGST discards them below.
    add(LW,     10'h000, '0, '0, 1, '0, "fill way 0");
    add(LW,     10'h040, '0, '0, 1, '0, "fill way 1");
    add(LW,     10'h080, '0, '0, 1, '0, "fill way 2");
    add(SW,     10'h004, 32'hdead0001);
    add(SW,     10'h05c, 32'hdead0007);
    add(SW,     10'h084, 32'hdead0011);

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

    // B: a store hit just ahead of a TAGST that renames its line (set 1,
    // way 0, to 0x120). The renamed line must not see the store's track bit.
    add(LW,     10'h020, '0, '0, 1, '0, "fill set 1 way 0");
    add(SW,     10'h020, 32'h44440001);
    add(TAGST,  tagst_addr(0, 1), 32'h80000004);         // valid, tag 4
    add(LW,     10'h120, '0, '0, 1, 32'h55550000, "B renamed line fills from memory");
    add(LW,     10'h120, '0, '0, 1, 32'h55550000, "B cached word matches memory");

    run_requests();
    finish_test();
  end
endmodule
