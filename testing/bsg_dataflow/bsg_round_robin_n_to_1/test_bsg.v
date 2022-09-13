module test_bsg
#(parameter width_p=4,
  parameter num_in_p=4,
  parameter strict_p=2,
  parameter use_scan_p=0,
  parameter tag_width_lp = `BSG_SAFE_CLOG2(num_in_p),
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
  wire [num_in_p-1:0][width_p-1:0] data_i;
  wire [num_in_p-1:0] v_i;
  wire [num_in_p-1:0] yumi_o;
  wire v_o;
  wire [width_p-1:0]     data_o;
  wire [tag_width_lp-1:0] tag_o;
  wire yumi_i;

  bsg_round_robin_n_to_1 #(
    .width_p(width_p),
    .num_in_p(num_in_p),
    .strict_p(strict_p),
    .use_scan_p(use_scan_p),
    .tag_width_lp(tag_width_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .data_i(data_i),
    .v_i(v_i),
    .yumi_o(yumi_o),
    .v_o(v_o),
    .data_o(data_o),
    .tag_o(tag_o),
    .yumi_i(yumi_i)
  );

endmodule
