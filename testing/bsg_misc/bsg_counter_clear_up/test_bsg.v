module test_bsg
#(parameter max_val_p=-1,
  parameter init_val_p   = `BSG_UNDEFINED_IN_SIM('0),
  parameter ptr_width_lp =`BSG_SAFE_CLOG2(max_val_p+1),
  parameter disable_overflow_warning_p = 0
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

  wire clk_i;
  wire reset_i;
  wire clear_i;
  wire up_i;
  wire [ptr_width_lp-1:0] count_o;

  bsg_counter_clear_up #(
    .max_val_p(max_val_p),
    .init_val_p(init_val_p),
    .ptr_width_lp(ptr_width_lp),
    .disable_overflow_warning_p(disable_overflow_warning_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .clear_i(clear_i),
    .up_i(up_i),
    .count_r_o(count_o)
  );

endmodule
