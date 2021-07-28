module test_bsg
#(parameter lg_size_p=4,
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

  wire w_clk_i;
  wire w_reset_i;
  wire w_inc_i;
  wire r_clk_i;
  wire  [lg_size_p-1:0] w_ptr_binary_r_o;
  wire  [lg_size_p-1:0] w_ptr_gray_r_o;
  wire  [lg_size_p-1:0] w_ptr_gray_r_rsync_o;

  bsg_async_ptr_gray #(
    .lg_size_p(lg_size_p),
    .use_negedge_for_launch_p(use_negedge_for_launch_p),
    .use_async_reset_p(use_async_reset_p))
    DUT (
    .w_clk_i(w_clk_i),
    .w_reset_i(w_reset_i),
    .w_inc_i(w_inc_i),
    .r_clk_i(r_clk_i),
    .w_ptr_binary_r_o(w_ptr_binary_r_o),
    .w_ptr_gray_r_o(w_ptr_gray_r_o),
    .w_ptr_gray_r_rsync_o(w_ptr_gray_r_rsync_o)
  );

endmodule
