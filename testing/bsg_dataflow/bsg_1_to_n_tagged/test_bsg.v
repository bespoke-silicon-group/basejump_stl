module test_bsg
#(parameter num_out_p=4,
  parameter tag_width_lp = `BSG_SAFE_CLOG2(num_out_p),
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
  wire v_i;
  wire [tag_width_lp-1:0]  tag_i;
  wire yumi_o;
  wire [num_out_p-1:0]   v_o;
  wire [num_out_p-1:0]   ready_i;

  bsg_1_to_n_tagged #(
    .num_out_p(num_out_p),
    .tag_width_lp(tag_width_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .v_i(v_i),
    .tag_i(tag_i),
    .yumi_o(yumi_o),
    .v_o(v_o),
    .ready_i(ready_i)
  );

endmodule
