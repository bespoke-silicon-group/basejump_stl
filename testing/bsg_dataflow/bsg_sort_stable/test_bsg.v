module test_bsg
#(parameter width_p=4,
  parameter stages_p=4,
  parameter items_p=4,
  parameter t_p=width_p-1,
  parameter b_p=0,
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

  wire [width_p-1:0] i [items_p-1:0];
  wire [width_p-1:0] o [items_p-1:0];

  bsg_sort_stable #(
    .width_p(width_p),
    .stages_p(stages_p),
    .items_p(items_p),
    .t_p(t_p),
    .b_p(b_p))
    DUT (
    .i(i),
    .o(o)
  );

endmodule
