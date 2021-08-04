module test_bsg
#(parameter width_p=4,
  parameter num_in_p=3,
  parameter remote_credits_p=2,
  lg_credit_decimation_p = 4,
  tag_width_lp = $clog2(num_in_p+1),
  tagged_width_lp = tag_width_lp+width_p,
  lg_remote_credits_lp = $clog2(remote_credits_p+1),
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
  wire [tagged_width_lp-1:0] data_o;
  wire v_o;
  wire yumi_i;
  wire [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_local_return_data_i;
  wire credit_local_return_v_i;
  wire [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_remote_return_data_i;
  wire credit_remote_return_yumi_o;

  bsg_channel_tunnel_out #(
    .width_p(width_p),
    .num_in_p(num_in_p),
    .remote_credits_p(remote_credits_p),
    .lg_credit_decimation_p(lg_credit_decimation_p),
    .tag_width_lp(tag_width_lp),
    .tagged_width_lp(tagged_width_lp),
    .lg_remote_credits_lp(lg_remote_credits_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .data_i(data_i),
    .v_i(v_i),
    .yumi_o(yumi_o),
    .data_o(data_o),
    .v_o(v_o),
    .yumi_i(yumi_i),
    .credit_local_return_data_i(credit_local_return_data_i),
    .credit_local_return_v_i(credit_local_return_v_i),
    .credit_remote_return_data_i(credit_remote_return_data_i),
    .credit_remote_return_yumi_o(credit_remote_return_yumi_o)
  );

endmodule
