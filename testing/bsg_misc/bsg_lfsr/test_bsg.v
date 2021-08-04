module test_bsg
#(parameter width_p=4,
  parameter init_val_p=1,
  parameter xor_mask_p=0,
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

  wire clk;
  wire reset_i;
  wire yumi_i;
  wire [width_p-1:0] o;

  bsg_lfsr #(
    .width_p(width_p),
    .init_val_p(init_val_p),
    .xor_mask_p(xor_mask_p))
    DUT (
    .clk(clk),
    .reset_i(reset_i),
    .yumi_i(yumi_i),
    .o(o)
  );

endmodule
