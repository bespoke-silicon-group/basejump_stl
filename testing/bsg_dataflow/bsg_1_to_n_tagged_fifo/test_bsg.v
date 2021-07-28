module test_bsg
#(parameter width_p=4,
  parameter num_out_p=3,
  parameter els_p=2,
  parameter unbuffered_mask_p=0,
  parameter use_pseudo_large_fifo_p=0,
  parameter harden_small_fifo_p=0,
  parameter tag_width_lp=`BSG_SAFE_CLOG2(num_out_p),
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

  wire clk_i;
  wire reset_i;
  wire v_i;
  wire [tag_width_lp-1:0] tag_i;
  wire [width_p-1:0] data_i
  wire yumi_o;
  wire [num_out_p-1:0] v_o;
  wire [num_out_p-1:0] yumi_i;
  wire [num_out_p-1:0] [width_p-1:0] data_o;

  bsg_1_to_n_tagged_fifo #(
    .width_p(width_p),
    .num_out_p(num_out_p),
    .els_p(els_p),
    .unbuffered_mask_p(unbuffered_mask_p),
    .use_pseudo_large_fifo_p(use_pseudo_large_fifo_p),
    .harden_small_fifo_p(harden_small_fifo_p),
    .tag_width_lp(tag_width_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .v_i(v_i),
    .tag_i(tag_i),
    .data_i(data_i),
    .yumi_o(yumi_o),
    .v_o(v_o),
    .yumi_i(yumi_i),
    .data_o(data_o)
  );

endmodule
