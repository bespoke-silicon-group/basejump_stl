`include "bsg_defines.sv"
`include "bsg_cache.svh"

// During a miss, the tl stage cannot accept a TAGST. When the miss completes,
// the tv stage takes the tl stage's request, so the tl stage must be emptied
// even though it accepts nothing new; otherwise that request runs through tv
// twice, returning an extra response and applying an atomic twice. Case A puts
// AMOADD_W behind a store miss with a TAGST next in line; case B does the same
// with a load. After the last response, the test watches for extra responses.
// Run with word tracking off/on and response backpressure.
module test_bsg;
  `include "bsg_nonsynth_cache_directed_test.svh"

  initial begin
    clear_tags();

    // A: AMOADD_W waits in tl behind a store miss; the TAGST is next in line.
    add(SW,        10'h000, 32'h00000010);
    add(AMOADD_W,  10'h040, 32'h00000001, '0, 1, '0, "add returns the old value once");
    add(TAGST,     tagst_addr(3, 1));              // unused way: invalidate
    add(LW,        10'h040, '0, '0, 1, 32'h00000001, "add applied once");
    add(LW,        10'h000, '0, '0, 1, 32'h00000010, "store before the add");

    // B: a load waits in tl behind a store miss; the TAGST is next in line.
    add(SW,        10'h080, 32'h00000020);
    add(LW,        10'h000, '0, '0, 1, 32'h00000010, "load behind the miss");
    add(TAGST,     tagst_addr(3, 1));
    add(LW,        10'h080, '0, '0, 1, 32'h00000020, "store before the load");
    add(AMOADD_W,  10'h040, 32'h00000001, '0, 1, 32'h00000001, "second add sees one add");

    run_requests();
    finish_test();
  end
endmodule
