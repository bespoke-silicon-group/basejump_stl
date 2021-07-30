module test_bsg
#(parameter credit_initial_p=4,
  parameter credit_max_val_p=4,
  parameter decimation_p=1,
  parameter ptr_width_lp=`BSG_WIDTH(credit_max_val_p),
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
  wire v_i;
  wire ready_o;
  wire v_o;
  wire credit_i;

  bsg_ready_to_credit_flow_converter #(
    .credit_initial_p(credit_initial_p),
    .credit_max_val_p(credit_max_val_p),
    .decimation_p(decimation_p),
    .ptr_width_lp(ptr_width_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .v_i(v_i),
    .ready_o(ready_o),
    .v_o(v_o),
    .credit_i(credit_i)
  );

endmodule
