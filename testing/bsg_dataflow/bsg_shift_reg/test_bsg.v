module test_bsg
#(parameter width_p=4,
  parameter stages_p=4,
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
  wire valid_i;
  wire [width_p-1:0] data_i;
  wire valid_o;
  wire [width_p-1:0] data_o;

  bsg_shift_reg #(
    .width_p(width_p),
    .stages_p(stages_p))
    DUT (
    .clk(clk),
    .reset(reset_i),
    .valid_i(valid_i),
    .data_i(data_i),
    .valid_o(valid_o),
    .data_o(data_o)
  );

endmodule
