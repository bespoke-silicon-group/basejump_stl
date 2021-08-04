module test_bsg
#(parameter max_val_p=-1,
  parameter lg_max_val_lp=`BSG_WIDTH(max_val_p),
  parameter reset_val_p=0,
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
  wire set_i;
  wire [lg_max_val_lp-1:0] val_i;
  wire [lg_max_val_lp-1:0] count_o;

  bsg_counter_set_en #(
    .max_val_p(max_val_p),
    .lg_max_val_lp(lg_max_val_lp),
    .reset_val_p(reset_val_p))
    DUT (
    .clk_i(clk_i),
    .set_i(set_i),
    .en_i(en_i),
    .reset_i(reset_i),
    .val_i(val_i),
    .count_o(count_o)
  );

endmodule
