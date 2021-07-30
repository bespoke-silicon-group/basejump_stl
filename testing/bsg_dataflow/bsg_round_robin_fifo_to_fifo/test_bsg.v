module test_bsg
#(parameter width_p=4,
  parameter num_out_p=4,
  parameter middle_meet_p=2,
  parameter min_out_middle_meet_lp=`BSG_MIN(num_out_p,middle_meet_p),
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

  wire clk;
  wire reset;
  wire [num_out_p-1:0]     ready_i;
  wire [middle_meet_p-1:0]    ready_head_o;
  wire [min_out_middle_meet_lp-1:0] go_channels_i;
  wire [$clog2(min_out_middle_meet_lp+1)-1:0] go_cnt_i;
  wire [width_p-1:0]      data_head_i[min_out_middle_meet_lp-1:0];
  wire [num_out_p-1:0]   valid_o;
  wire [width_p-1:0]     data_o [num_out_p-1:0];

  bsg_rr_f2f_output #(
    .width_p(width_p),
    .num_out_p(num_out_p),
    .middle_meet_p(middle_meet_p),
    .min_out_middle_meet_lp(min_out_middle_meet_lp))
    DUT (
    .clk(clk),
    .reset(reset),
    .ready_i(ready_i),
    .ready_head_o(ready_head_o),
    .go_channels_i(go_channels_i),
    .go_cnt_i(go_cnt_i),
    .data_head_i(data_head_i),
    .valid_o(valid_o),
    .data_o(data_o)
  );

endmodule
