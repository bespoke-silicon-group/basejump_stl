module test_bsg
#(parameter max_val_p=-1,
  parameter init_val_p= -1,
  parameter ptr_width_lp = `BSG_SAFE_CLOG2(max_val_p),
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
  wire en_i;
  wire [ptr_width_lp-1:0] count_o;
  wire overflow_o;

  bsg_counter_overflow_en #(
    .max_val_p(max_val_p),
    .init_val_p(init_val_p),
    .ptr_width_lp(ptr_width_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .en_i(en_i),
    .count_o(count_o),
    .overflow_o(overflow_o)
  );

endmodule
