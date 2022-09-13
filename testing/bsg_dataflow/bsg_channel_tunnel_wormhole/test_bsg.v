module test_bsg
#(parameter width_p=4,
  parameter x_cord_width_p=3,
  parameter y_cord_width_p=3,
  parameter len_width_p=3,
  parameter reserved_width_p=3,
  parameter remote_credits_p=3,
  parameter max_payload_flits_p=2,
  parameter lg_credit_decimation_p = `BSG_MIN($clog2(remote_credits_p+1),4),
  parameter use_pseudo_large_fifo_p = 1,
  localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(width_p)
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
  wire [width_p-1:0] multi_data_i;
  wire               multi_v_i;
  wire               multi_ready_o;
  wire [width_p-1:0] multi_data_o;
  wire               multi_v_o;
  wire               multi_yumi_i;
  wire [num_in_p-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i;
  wire [num_in_p-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o;

  bsg_channel_tunnel_wormhole #(
    .width_p(width_p),
    .x_cord_width_p(x_cord_width_p),
    .y_cord_width_p(y_cord_width_p),
    .len_width_p(len_width_p),
    .reserved_width_p(reserved_width_p),
    .remote_credits_p(remote_credits_p),
    .max_payload_flits_p(max_payload_flits_p),
    .lg_credit_decimation_p(lg_credit_decimation_p),
    .use_pseudo_large_fifo_p(use_pseudo_large_fifo_p),
    .bsg_ready_and_link_sif_width_lp(bsg_ready_and_link_sif_width_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .multi_data_i(multi_data_i),
    .multi_v_i(multi_v_i),
    .multi_ready_o(multi_ready_o),
    .multi_data_o(multi_data_o),
    .multi_v_o(multi_v_o),
    .multi_yumi_i(multi_yumi_i),
    .link_i(link_i),
    .link_o(link_o)
  );

endmodule
