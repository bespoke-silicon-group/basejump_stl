module test_bsg
#(parameter lg_size_p=4,
  parameter width_p=4,
  parameter control_width_p=0,
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

  wire w_clk_i;
  wire w_reset_i;
  wire w_enq_i;
  wire [width_p-1:0] w_data_i;
  wire w_full_o;
  wire r_clk_i;
  wire r_reset_i;
  wire r_deq_i;
  wire [width_p-1:0] r_data_o;
  wire r_valid_o;

  bsg_async_fifo #(
    .lg_size_p(lg_size_p),
    .width_p(width_p),
    .control_width_p(control_width_p))
    DUT (
    .w_clk_i(w_clk_i),
    .w_reset_i(w_reset_i),
    .w_enq_i(w_enq_i),
    .w_data_i(w_data_i),
    .w_full_o(w_full_o),
    .r_clk_i(r_clk_i),
    .r_reset_i(r_reset_i),
    .r_deq_i(r_deq_i),
    .r_data_o(r_data_o),
    .r_valid_o(r_valid_o)
  );

endmodule
