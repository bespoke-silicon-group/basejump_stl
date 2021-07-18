module test_bsg
#(parameter width_p=-1,
  parameter init_val_p='0,
  parameter set_and_down_exclusive_p=0,
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
  
  wire [width_p-1:0] a_i;
  wire [`BSG_SAFE_CLOG2(width_p)-1:0] num_zero_o;

  bsg_counting_leading_zeros #(
    .width_p(width_p))
    DUT (
    .a_i(a_i),
    .num_zero_o(num_zero_o)
  );

endmodule
