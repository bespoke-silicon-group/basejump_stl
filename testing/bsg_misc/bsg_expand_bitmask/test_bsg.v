module test_bsg
#(parameter in_width_p=4,
  parameter expand_p=0,
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

  wire [in_width_p-1:0] i;
  wire [(in_width_p*safe_expand_lp)-1:0] o;

  bsg_expand_bitmask #(
    .in_width_p(in_width_p),
    .expand_p(expand_p))
    DUT (
    .i(i),
    .o(o)
  );

endmodule
