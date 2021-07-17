module test_bsg
#(parameter pattern_els_p=-1,
  parameter width_lp=$bits(pattern_els_p),
  parameter set_els_lp=`BSG_COUNTONES_SYNTH(pattern_els_p),
  parameter sim_clk_period=10,
  parameter reset_cycles_lo_p=-1,
  parameter reset_cycles_hi_p=-1
  );

  wire clk_lo;
  logic reset;

  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
   #(.cycle_time_p(sim_clk_period))
   clock_gen
    (.o(clk_lo));

  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk_lo) 
                           , .async_reset_o(reset)
                          );

  initial begin
    $display("[BSG_PASS] Empty testbench");
    $finish();
  end

  wire [width_lp-1:0] i;
  wire [set_els_lp-1:0] o;

  bsg_concentrate_static #(
    .pattern_els_p(pattern_els_p),
    .width_lp(width_lp),
    .set_els_lp(set_els_lp))
    DUT (
    .i(i),
    .o(o)
  );

endmodule
