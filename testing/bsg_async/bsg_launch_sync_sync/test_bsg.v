module test_bsg
#(parameter width_p=4,
  parameter use_negedge_for_launch_p=0,
  parameter use_async_reset_p=0,
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

  wire iclk_i;
  wire iclk_reset_i;
  wire oclk_i;
  wire [width_p-1:0] iclk_data_i;
  wire [width_p-1:0] iclk_data_o;
  wire [width_p-1:0] oclk_data_o;

  bsg_launch_sync_sync #(
    .width_p(width_p),
    .use_negedge_for_launch_p(use_negedge_for_launch_p),
    .use_async_reset_p(use_async_reset_p))
    DUT (
    .iclk_i(iclk_i),
    .iclk_reset_i(iclk_reset_i),
    .oclk_i(oclk_i),
    .iclk_data_i(iclk_data_i),
    .iclk_data_o(iclk_data_o),
    .oclk_data_o(oclk_data_o)
  );

endmodule
