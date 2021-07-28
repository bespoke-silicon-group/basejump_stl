module test_bsg
#(parameter width_p=-1,
  parameter i_know_this_is_a_bad_idea_p=0,
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
  wire [width_p-1:0] data_i;
  wire [width_p-1:0] data_o;

  bsg_dlatch #(
    .width_p(width_p),
    .i_know_this_is_a_bad_idea_p(i_know_this_is_a_bad_idea_p))
    DUT (
    .clk_i(clk_i),
    .data_i(data_i),
    .data_o(data_o)
  );

endmodule
