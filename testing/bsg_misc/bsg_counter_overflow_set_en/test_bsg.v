module test_bsg
#(parameter max_val_p=-1,
  parameter lg_max_val_lp = `BSG_SAFE_CLOG2(max_val_p+1),
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
  wire en_i;
  wire set_i;
  wire [lg_max_val_lp-1:0] val_i;
  wire [lg_max_val_lp-1:0] count_o;
  wire overflow_o;

  bsg_counter_overflow_set_en #(
    .max_val_p(max_val_p),
    .lg_max_val_lp(lg_max_val_lp))
    DUT (
    .clk_i(clk_i),
    .set_i(set_i),
    .en_i(en_i),
    .val_i(val_i),
    .count_o(count_o),
    .overflow_o(overflow_o)
  );

endmodule
