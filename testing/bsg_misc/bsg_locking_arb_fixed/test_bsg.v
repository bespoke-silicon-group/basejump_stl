module test_bsg
#(parameter inputs_p=4,
  parameter lo_to_hi_p=1,
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

  wire clk;
  wire ready_i;
  wire unlock_i;
  wire [width_p-1:0] reqs_i;
  wire [width_p-1:0] grants_o;

  bsg_locking_arb_fixed #(
    .inputs_p(inputs_p),
    .lo_to_hi_p(lo_to_hi_p))
    DUT (
    .clk(clk),
    .ready_i(ready_i),
    .unlock_i(unlock_i),
    .reqs_i(reqs_i),
    .grants_o(grants_o)
  );

endmodule
