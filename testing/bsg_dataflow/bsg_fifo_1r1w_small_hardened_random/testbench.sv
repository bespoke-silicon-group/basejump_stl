module testbench();

  parameter width_p = 32;  
  parameter els_p = 4;
  parameter test_els_p = 4500;

  // clock and reset
  bit clk, reset;
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg (
    .o(clk)
  );
  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(8)
    ,.reset_cycles_hi_p(8)
  ) rg (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );


  // DUT
  logic v_li, ready_lo;
  logic [width_p-1:0] data_li, data_lo;
  logic v_lo, yumi_li;

  bsg_fifo_1r1w_small_hardened #(
    .width_p(width_p)
    ,.els_p(els_p)
  ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)
    
    ,.v_i(v_li)
    ,.ready_param_o(ready_lo)
    ,.data_i(data_li)

    ,.v_o(v_lo)
    ,.data_o(data_lo)
    ,.yumi_i(yumi_li)
  );

  // could use hierarchical bind in order to do more whitebox internal testing
  bind bsg_fifo_1r1w_small_hardened bsg_fifo_1r1w_small_hardened_cov
 #(.els_p(els_p)
  ) pc_cov
  (.*
  );


  // Input side tester
  input_side_tester #(
    .width_p(width_p)
    ,.test_els_p(test_els_p)
  ) in0 (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.v_o(v_li)
    ,.ready_i(ready_lo)
    ,.data_o(data_li)
  );

  // Output side tester
  output_side_tester #(
    .width_p(width_p)
    ,.test_els_p(test_els_p)
  ) out0 (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.v_i(v_lo)
    ,.yumi_o(yumi_li)
    ,.data_i(data_lo)
  );

endmodule
