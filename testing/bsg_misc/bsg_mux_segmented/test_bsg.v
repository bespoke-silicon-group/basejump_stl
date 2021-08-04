module test_bsg
#(parameter segments_p=4,
  parameter segment_width_p=2,
  parameter data_width_lp=segments_p*segment_width_p,
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

  wire [data_width_lp-1:0] data0_i;
  wire [data_width_lp-1:0] data1_i;
  wire [segments_p-1:0] sel_i;
  wire [data_width_lp-1:0] data_o;

  bsg_mux_segmented #(
    .segments_p(segments_p),
    .segment_width_p(segment_width_p),
    .data_width_lp(data_width_lp))    
    DUT (
    .data0_i(data0_i),
    .data1_i(data1_i),
    .sel_i(sel_i),
    .data_o(data_o)
  );

endmodule
