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

  wire oclk_i;
  wire [width_p-1:0] iclk_data_i;
  wire [width_p-1:0] oclk_data_o;

  bsg_sync_sync #(
    .width_p(width_p))
    DUT (
    .oclk_i(oclk_i),
    .iclk_data_i(iclk_data_i),
    .oclk_data_o(oclk_data_o)
  );

endmodule
