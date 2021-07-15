module test_bsg
#(parameter inputs_p=-1,
  parameter lo_to_hi_p=-1,
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

  wire [inputs_p-1:0] reqs_i;
  wire [inputs_p-1:0] grants_o;
  wire ready_i;

  bsg_arb_fixed #(
    .inputs_p(inputs_p),
    .lo_to_hi_p(lo_to_hi_p)) 
    DUT (
    .reqs_i(reqs_i),
    .grants_o(grants_o),
    .ready_i(ready_i)
  );

endmodule
