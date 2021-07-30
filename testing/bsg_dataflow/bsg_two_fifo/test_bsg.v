module test_bsg
#(parameter width_p=4,
  parameter verbose_p=0,
  parameter allow_enq_deq_on_full_p=0,
  parameter ready_THEN_valid_p=allow_enq_deq_on_full_p,
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
  wire               ready_o;
  wire [width_p-1:0] data_i;
  wire               v_i;
  wire               v_o;
  wire [width_p-1:0] data_o;
  wire               yumi_i;

  bsg_two_fifo #(
    .width_p(width_p),
    .verbose_p(verbose_p),
    .ready_THEN_valid_p(ready_THEN_valid_p),
    .allow_enq_deq_on_full_p(allow_enq_deq_on_full_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .ready_o(ready_o),
    .data_i(data_i),
    .v_i(v_i),
    .v_o(v_o),
    .data_o(data_o),
    .yumi_i(yumi_i)
  );

endmodule
