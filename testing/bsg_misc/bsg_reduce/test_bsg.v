module test_bsg
#(parameter width_p=4,
  parameter xor_p=0,
  parameter and_p=0,
  parameter or_p=0,
  parameter harden_p=0,
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
  wire o;

  bsg_reduce #(
    .width_p(width_p),
    .xor_p(xor_p),
    .and_p(and_p),
    .or_p(or_p),
    .harden_p(harden_p))
    DUT (
    .i(i),
    .o(o)
  );

endmodule
