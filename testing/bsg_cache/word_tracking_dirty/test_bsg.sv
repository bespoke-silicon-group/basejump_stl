`include "bsg_defines.sv"
`include "bsg_cache.svh"

// A full-word store allocates a partially tracked line. AFL writes it back but
// leaves its tag valid. A partial store or atomic to an untracked word must
// mark that clean line dirty, so AFLINV followed by a reload retains the update.
// Controls cover no intervening AFL, the original full-word store, and a load
// tracking miss that must preserve an already dirty line. Run with word tracking
// off/on and response backpressure. The DMA model is the common, unmodified one.
module test_bsg;
  `include "bsg_nonsynth_cache_directed_test.svh"

  initial begin
    clear_tags();

    // A: word 6 is tracked; masked store to untracked word 3 after AFL.
    add(SW,     10'h278, 32'h11112222);
    add(AFL,    10'h260);
    add(SM,     10'h26c, 32'h7d98b65f, 4'b1110);
    add(AFLINV, 10'h260);
    add(LW,     10'h26c, '0, '0, 1, 32'h7d98b600, "masked store after AFL");
    add(LW,     10'h278, '0, '0, 1, 32'h11112222, "original full-word store");

    // B: byte store to an untracked word after AFL.
    add(SW,     10'h118, 32'h33334444);
    add(AFL,    10'h100);
    add(SB,     10'h105, 32'h000000ab);
    add(AFLINV, 10'h100);
    add(LW,     10'h104, '0, '0, 1, 32'h0000ab00, "byte store after AFL");

    // C: the atomic must return the old value and write back its new value.
    add(SW,        10'h1b8, 32'h55556666);
    add(AFL,       10'h1a0);
    add(AMOSWAP_W, 10'h1a4, 32'hcafe0001, '0, 1, '0, "atomic old value");
    add(AFLINV,    10'h1a0);
    add(LW,        10'h1a4, '0, '0, 1, 32'hcafe0001, "atomic update after AFL");

    // D: control with no AFL; the line is already dirty at the tracking miss.
    add(SW,     10'h0d8, 32'h77778888);
    add(SM,     10'h0cc, 32'h7d98b65f, 4'b1110);
    add(AFLINV, 10'h0c0);
    add(LW,     10'h0cc, '0, '0, 1, 32'h7d98b600, "masked store without AFL");

    // E: filling an untracked word for a load must not clear the dirty bit.
    add(SW,     10'h218, 32'h12345678);
    add(LW,     10'h204, '0, '0, 1, '0, "load of untracked word");
    add(AFLINV, 10'h200);
    add(LW,     10'h218, '0, '0, 1, 32'h12345678, "load preserves dirty line");

    run_requests();
    finish_test();
  end
endmodule
