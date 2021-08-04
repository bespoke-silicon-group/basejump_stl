module test_bsg
#(parameter width_p=4,
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

  wire [width_p-1:0] v0_data_i;
  wire               v1_en_i;
  wire [width_p-1:0] v1_data_o;

  bsg_level_shift_up_down_sink #(
    .width_p(width_p))
    DUT (
    .v0_data_i(v0_data_i),
    .v1_en_i(v1_en_i),
    .v1_data_o(v1_data_o)
  );

endmodule
