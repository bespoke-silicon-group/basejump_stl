module test_bsg
#(parameter width_p=4,
  parameter lo_to_hi_p=1,
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

  wire [width_p-1:0] i;
  wire [width_p-1:0] o;
  wire               v_o;

  bsg_priority_encode_one_hot_out #(
    .width_p(width_p),
    .lo_to_hi_p(lo_to_hi_p))
    DUT (
    .i(i),
    .o(o),
    .v_o(v_o)
  );

endmodule
