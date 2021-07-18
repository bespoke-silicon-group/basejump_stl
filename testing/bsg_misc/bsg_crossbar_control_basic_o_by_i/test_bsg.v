module test_bsg
#(parameter i_els_p="inv",
  parameter o_els_p="inv",
  parameter lg_o_els_lp=`BSG_SAFE_CLOG2(o_els_p),
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
  wire reset_i;
  wire [i_els_p-1:0] valid_i;
  wire [i_els_p-1:0][lg_o_els_lp-1:0] sel_io_i;
  wire [i_els_p-1:0] yumi_o;
  wire [o_els_p-1:0] ready_and_i;
  wire [o_els_p-1:0] valid_o;
  wire [o_els_p-1:0][i_els_p-1:0] grants_oi_one_hot_o;

  bsg_crossbar_control_basic_o_by_i #(
    .i_els_p(i_els_p),
    .o_els_p(o_els_p),
    .lg_o_els_lp(lg_o_els_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .valid_i(valid_i),
    .sel_io_i(sel_io_i),
    .yumi_o(yumi_o),
    .ready_and_i(ready_and_i),
    .valid_o(valid_o),
    .grants_oi_one_hot_o(grants_oi_one_hot_o)
  );

endmodule
