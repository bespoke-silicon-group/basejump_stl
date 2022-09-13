module test_bsg
#(parameter width_p=4,
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
  wire [width_p*2-1:0] data_i;
  wire [1:0] v_i;
  wire [1:0] ready_o;
  wire [width_p*2-1:0] data_o;
  wire [1:0] v_o;
  wire [1:0] ready_i;

  bsg_round_robin_2_to_2 #(
    .width_p(width_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .data_i(data_i),
    .v_i(v_i),
    .ready_o(ready_o),
    .data_o(data_o),
    .v_o(v_o),
    .ready_i(ready_i)
  );

endmodule
