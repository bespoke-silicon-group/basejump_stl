module test_bsg
#(parameter width_p=-1,
  parameter clear_over_set_p=0,
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
  wire [width_p-1:0] set_i;
  wire [width_p-1:0] clear_i;
  wire [width_p-1:0] data_o;

  bsg_dff_reset_set_clear #(
    .width_p(width_p),
    .clear_over_set_p(clear_over_set_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .en_i(en_i),
    .data_i(data_i),
    .data_o(data_o)
  );

endmodule
