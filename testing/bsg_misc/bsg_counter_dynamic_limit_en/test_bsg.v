module test_bsg
#(parameter width_p=-1,
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
  wire en_i;
  wire [width_p-1:0] limit_i;
  wire [width_p-1:0] counter_o;
  wire overflowed_o;

  bsg_counter_dynamic_limit_en #(
    .width_p(width_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .en_i(en_i),
    .limit_i(limit_i),
    .counter_o(counter_o),
    .overflowed_o(overflowed_o)
  );

endmodule
