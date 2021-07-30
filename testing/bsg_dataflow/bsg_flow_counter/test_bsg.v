module test_bsg
#(parameter els_p=4,
  parameter count_free_p=0,
  parameter ready_THEN_valid_p=0,
  parameter ptr_width_lp=`BSG_WIDTH(els_p),
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
  wire ready_i;
  wire yumi_i;
  wire [ptr_width_lp-1:0] count_o;

  bsg_flow_counter #(
    .els_p(els_p),
    .count_free_p(count_free_p),
    .ready_THEN_valid_p(ready_THEN_valid_p),
    .ptr_width_lp(ptr_width_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .v_i(v_i),
    .ready_i(ready_i),
    .yumi_i(yumi_i),
    .count_o(count_o)
  );

endmodule
