module test_bsg
#(parameter width_p=4,
  parameter els_p=4,
  parameter hi_to_lo_p=0,
  parameter use_minimal_buffering_p=0,
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

  wire clk_i;
  wire reset_i;
  wire v_i;
  wire ready_o;
  wire [width_p-1:0] data_i;
  wire [els_p-1:0][width_p-1:0] data_o;
  wire v_o;
  wire yumi_i;

  bsg_serial_in_parallel_out_full #(
    .width_p(width_p),
    .els_p(els_p),
    .hi_to_lo_p(hi_to_lo_p),
    .use_minimal_buffering_p(use_minimal_buffering_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .v_i(v_i),
    .ready_o(ready_o),
    .data_i(data_i),
    .data_o(data_o),
    .v_o(v_o),
    .yumi_i(yumi_i)
  );

endmodule
