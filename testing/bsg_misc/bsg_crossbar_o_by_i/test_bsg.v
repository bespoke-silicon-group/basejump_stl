module test_bsg
#(parameter i_els_p = -1,
  parameter o_els_p = -1,
  parameter width_p = -1,
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
  
  wire [i_els_p-1:0][width_p-1:0] i;
  wire [o_els_p-1:0][i_els_p-1:0] sel_oi_one_hot_i;
  wire [o_els_p-1:0][width_p-1:0] o;

  bsg_crossbar_o_by_i #(
    .i_els_p(i_els_p),
    .o_els_p(o_els_p),
    .width_p(width_p))
    DUT (
    .i(i),
    .sel_oi_one_hot_i(sel_oi_one_hot_i),
    .o(o)
  );

endmodule
