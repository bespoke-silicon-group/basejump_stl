`include "bsg_defines.sv"
`include "bsg_cache.svh"

// A full-word store allocates a partially tracked line, and ALOCK locks it.
// A load, an atomic or a partial store to an untracked word of that line is a
// tracking miss: the cache fetches the words it does not hold. The line must
// still be locked afterwards. Cases A to C check the lock bit with TAGLV, and
// case D checks what the lock is for: locked lines are not replaced. Case E
// holds the controls. Run with word tracking off/on and response backpressure.
// The DMA model is the common, unmodified one.
module test_bsg;
  `include "bsg_nonsynth_cache_directed_test.svh"

  initial begin
    clear_tags();

    // A: load of an untracked word. Memory first gets a value for word 1, so
    // that the tracking miss has something to fetch. Empty ways fill lowest
    // first, so the line is in way 0 of set 0.
    add(SW,     10'h004, 32'haaaa0001);
    add(AFLINV, 10'h000);
    add(SW,     10'h000, 32'haaaa0000);
    add(ALOCK,  10'h000);
    add(TAGLV,  tagst_addr(0, 0), '0, '0, 1, 32'h3, "A: line locked");
    add(LW,     10'h004, '0, '0, 1, 32'haaaa0001, "A: load of an untracked word");
    add(TAGLV,  tagst_addr(0, 0), '0, '0, 1, 32'h3, "A: lock after a load tracking miss");
    add(LW,     10'h000, '0, '0, 1, 32'haaaa0000, "A: tracked word");

    // B: atomic to an untracked word, in way 1.
    add(SW,        10'h040, 32'hbbbb0000);
    add(ALOCK,     10'h040);
    add(TAGLV,     tagst_addr(1, 0), '0, '0, 1, 32'h3, "B: line locked");
    add(AMOSWAP_W, 10'h048, 32'hbbbb0002, '0, 1, '0, "B: atomic old value");
    add(TAGLV,     tagst_addr(1, 0), '0, '0, 1, 32'h3, "B: lock after an atomic tracking miss");
    add(LW,        10'h048, '0, '0, 1, 32'hbbbb0002, "B: atomic update");

    // C: byte store to an untracked word, in way 2.
    add(SW,     10'h080, 32'hcccc0000);
    add(ALOCK,  10'h080);
    add(TAGLV,  tagst_addr(2, 0), '0, '0, 1, 32'h3, "C: line locked");
    add(SB,     10'h089, 32'h000000cd);
    add(TAGLV,  tagst_addr(2, 0), '0, '0, 1, 32'h3, "C: lock after a store tracking miss");
    add(LW,     10'h088, '0, '0, 1, 32'h0000cd00, "C: byte store");

    // D: ways 0 to 2 of set 0 are locked, so three more lines of the set all
    // have to go through way 3, and the locked lines stay where they are.
    add(LW,     10'h0c0, '0, '0, 1, '0, "D: fourth line of the set");
    add(LW,     10'h100, '0, '0, 1, '0, "D: fifth line of the set");
    add(LW,     10'h140, '0, '0, 1, '0, "D: sixth line of the set");
    add(TAGLA,  tagst_addr(0, 0), '0, '0, 1, 32'h000, "D: line in way 0");
    add(TAGLA,  tagst_addr(1, 0), '0, '0, 1, 32'h040, "D: line in way 1");
    add(TAGLA,  tagst_addr(2, 0), '0, '0, 1, 32'h080, "D: line in way 2");
    add(TAGLA,  tagst_addr(3, 0), '0, '0, 1, 32'h140, "D: line in way 3");

    // E: controls, in set 1. ALOCK of a line that is not in the cache locks
    // it as it is filled, and AUNLOCK unlocks it. A tracking miss of a line
    // that is not locked leaves it unlocked.
    add(ALOCK,   10'h020);
    add(TAGLV,   tagst_addr(0, 1), '0, '0, 1, 32'h3, "E: ALOCK of a line that is not in the cache");
    add(AUNLOCK, 10'h020);
    add(TAGLV,   tagst_addr(0, 1), '0, '0, 1, 32'h1, "E: AUNLOCK");
    add(SW,      10'h060, 32'heeee0000);
    add(LW,      10'h064, '0, '0, 1, '0, "E: load of an untracked word, line not locked");
    add(TAGLV,   tagst_addr(1, 1), '0, '0, 1, 32'h1, "E: line that was not locked");

    run_requests();
    finish_test();
  end
endmodule
