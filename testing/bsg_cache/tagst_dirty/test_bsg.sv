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
  `include "bsg_nonsynth_cache_directed_test.svh"

  initial begin
    clear_tags();

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

    run_requests();
    finish_test();
  end
endmodule
