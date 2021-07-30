module test_bsg
#(parameter num_channels_p=4,
  parameter channel_width_p=4,
  parameter pipeline_indir_p=0,
  parameter pipeline_outdir_p=0,
  parameter one_hot_p=1,
  parameter sim_clk_period=10,
  parameter reset_cycles_lo_p=-1,
  parameter reset_cycles_hi_p=-1
  );

  wire clk_lo;
  logic reset;

  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
   #(.cycle_time_p(sim_clk_period))
   clock_gen
    (.o(clk_lo));

  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk_lo) 
                           , .async_reset_o(reset)
                          );

  initial begin
    $display("[BSG_PASS] Empty testbench");
    $finish();
  end

  wire reset_i;
  wire calibration_done_i;
  wire [num_channels_p-1:0] channel_active_i;
  wire [num_channels_p-1:0 ] in_v_i;
  wire [channel_width_p-1:0] in_data_i [num_channels_p-1:0];
  wire [num_channels_p-1:0 ] in_yumi_o;
  wire [num_channels_p-1:0 ] in_v_o;
  wire [channel_width_p-1:0] in_data_o [num_channels_p-1:0];
  wire [num_channels_p-1:0 ] in_yumi_i;
  wire [num_channels_p-1:0 ] out_me_v_i;
  wire [channel_width_p-1:0] out_me_data_i [num_channels_p-1:0];
  wire [num_channels_p-1:0 ] out_me_ready_o;
  wire [num_channels_p-1:0 ] out_me_v_o;
  wire [channel_width_p-1:0] out_me_data_o [num_channels_p-1:0];
  wire [num_channels_p-1:0 ] out_me_ready_i;

  bsg_sbox #(
    .num_channels_p(num_channels_p),
    .channel_width_p(channel_width_p),
    .pipeline_indir_p(pipeline_indir_p),
    .pipeline_outdir_p(pipeline_outdir_p),
    .one_hot_p(one_hot_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .calibration_done_i(calibration_done_i),
    .channel_active_i(channel_active_i),
    .in_v_i(in_v_i),
    .in_data_i(in_data_i),
    .in_yumi_o(in_yumi_o),
    .in_v_o(in_v_o),
    .in_data_o(in_data_o),
    .in_yumi_i(in_yumi_i),
    .out_me_v_i(out_me_v_i),
    .out_me_data_i(out_me_data_i),
    .out_me_ready_o(out_me_ready_o),
    .out_me_v_o(out_me_v_o),
    .out_me_data_o(out_me_data_o),
    .out_me_ready_i(out_me_ready_i)
  );

endmodule
