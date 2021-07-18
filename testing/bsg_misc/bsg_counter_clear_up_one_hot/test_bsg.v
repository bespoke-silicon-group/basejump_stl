module test_bsg
#(parameter max_val_p=-1,
  parameter width_lp=max_val_p+1,
  parameter init_val_p=(width_lp) ' (1),
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
  wire clear_i;
  wire up_i;
  wire [width_lp-1:0] count_r_o;

  bsg_counter_clear_up_one_hot #(
    .max_val_p(max_val_p),
    .width_lp(width_lp),
    .init_val_p(init_val_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .clear_i(clear_i),
    .up_i(up_i),
    .count_r_o(count_r_o)
  );

endmodule
