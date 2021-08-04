module test_bsg
#(parameter pattern_els_p=4,
  width_lp=`BSG_COUNTONES_SYNTH(pattern_els_p),
  unconnected_val_p=`BSG_DISCONNECTED_IN_SIM(1'b0)
  parameter cycle_time_p=10,
  parameter reset_cycles_lo_p=-1,
  parameter reset_cycles_hi_p=-1
  );

  wire clk;
  wire reset;

  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_p)
                          )  clock_gen
                          (  .o(clk)
                          );

  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk) 
                           , .async_reset_o(reset)
                          );

  initial begin
    $display("[BSG_PASS] Empty testbench");
    $finish();
  end

  wire [width_lp-1:0] i;
  wire [$bits(pattern_els_p)-1:0] o;

  bsg_unconcentrate_static #(
    .pattern_els_p(pattern_els_p),
    .width_lp(width_lp),
    .unconnected_val_p(unconnected_val_p))
    DUT (
    .i(i),
    .o(o)
  );

endmodule
