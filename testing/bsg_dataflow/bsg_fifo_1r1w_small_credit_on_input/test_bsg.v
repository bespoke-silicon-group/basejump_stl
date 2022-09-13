module test_bsg
#(parameter width_p=4,
  parameter els_p=2,
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

  wire                clk_i;
  wire                reset_i;
  wire [width_p-1:0]  data_i;
  wire                v_i;
  wire                credit_o;
  wire                v_o;
  wire  [width_p-1:0] data_o;
  wire                yumi_i;

  bsg_fifo_1r1w_small_credit_on_input #(
    .width_p(width_p),
    .els_p(els_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .data_i(data_i),
    .v_i(v_i),
    .credit_o(credit_o),
    .v_o(v_o),
    .data_o(data_o),
    .yumi_i(yumi_i)
  );

endmodule
