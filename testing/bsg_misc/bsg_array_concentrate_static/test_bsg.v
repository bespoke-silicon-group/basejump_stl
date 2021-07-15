module test_bsg
#(parameter width_p=-1,
  parameter pattern_els_p=-1,
  parameter sim_clk_period=10,
  parameter reset_cycles_lo_p=-1,
  parameter reset_cycles_hi_p=-1,
  dense_els_lp=$bits(pattern_els_p),
  sparse_els_lp=`BSG_COUNTONES_SYNTH(pattern_els_p)
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

  wire [dense_els_lp-1:0][width_p-1:0] i;
  wire [sparse_els_lp-1:0][width_p-1:0] o;

  bsg_array_concentrate_static #(
    .width_p(width_p),
    .pattern_els_p(pattern_els_p)) 
    DUT (
    .i(i),
    .o(o)
  );

endmodule
