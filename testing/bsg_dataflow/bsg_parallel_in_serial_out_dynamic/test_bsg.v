module test_bsg
#(parameter width_p=4,
  parameter max_els_p=4,
  parameter lg_max_els_lp=`BSG_SAFE_CLOG2(max_els_p),
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
  wire                               v_i;
  wire [lg_max_els_lp-1:0]          len_i;
  wire [max_els_p-1:0][width_p-1:0] data_i;
  wire                              ready_o;
  wire                              v_o;
  wire                              len_v_o;
  wire [width_p-1:0]                data_o;
  wire                               yumi_i;

  bsg_parallel_in_serial_out_dynamic #(
    .width_p(width_p),
    .max_els_p(max_els_p),
    .lg_max_els_lp(lg_max_els_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .v_i(v_i),
    .len_i(len_i),
    .data_i(data_i),
    .ready_o(ready_o),
    .v_o(v_o),
    .len_v_o(len_v_o),
    .data_o(data_o),
    .yumi_i(yumi_i)
  );

endmodule
