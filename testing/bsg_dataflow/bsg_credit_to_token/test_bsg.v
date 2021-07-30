module test_bsg
#(parameter decimation_p=4,
  parameter max_val_p=3,
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

  wire clk_i;
  wire reset_i;
  wire credit_i;
  wire ready_i;
  wire token_o;

  bsg_credit_to_token #(
    .decimation_p(decimation_p),
    .max_val_p(max_val_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .credit_i(credit_i),
    .ready_i(ready_i),
    .token_o(token_o)
  );

endmodule
