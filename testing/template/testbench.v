/**
 *    template testbench
 */

module testbench();
  

  // clock and reset
  bit clk, reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg0 (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(8)
  ) rg0 (
    .clk_i(clk)
    ,.async_reset_o(reset)
  ); 

  // test
  integer expected;
  integer actual;

  initial begin
    wait(~reset);
  
    // retrieve define macro.
    expected = `EXPECTED_VAL;

    // retrieve plusarg param.
    $value$plusargs("actual_val=%d", actual);
  
    assert(expected == actual) else $error("[BSG_FAIL] test val does not match."); 

    $display("[BSG_FINISH] Test Successful!");
    $finish; 
  end

endmodule
