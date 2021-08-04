module test_bsg
#(parameter width_p=4,
  parameter els_p=4,
  parameter out_els_p = els_p,
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

  wire               clk_i;
  wire               reset_i;
  wire               valid_i;
  wire [width_p-1:0] data_i;
  wire               ready_o;
  wire logic [out_els_p-1:0]                valid_o;
  wire logic [out_els_p-1:0][width_p-1:0]   data_o;
  wire [$clog2(out_els_p+1)-1:0]        yumi_cnt_i;

  bsg_serial_in_parallel_out #(
    .width_p(width_p),
    .els_p(els_p),
    .out_els_p(out_els_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .valid_i(valid_i),
    .data_i(data_i),
    .ready_o(ready_o),
    .valid_o(valid_o),
    .data_o(data_o),
    .yumi_cnt_i(yumi_cnt_i)
  );

endmodule
