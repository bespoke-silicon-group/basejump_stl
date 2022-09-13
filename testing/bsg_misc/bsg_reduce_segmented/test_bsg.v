module test_bsg
#(parameter segments_p=4,
  parameter segment_width_p=4,
  parameter xor_p=0,
  parameter and_p=0,
  parameter or_p=0,
  parameter nor_p=0,
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

  wire [segments_p*segment_width_p-1:0] i;
  wire [segments_p-1:0] o;

  bsg_reduce_segmented #(
    .segments_p(segments_p),
    .segment_width_p(segment_width_p),
    .xor_p(xor_p),
    .and_p(and_p),
    .or_p(or_p),
    .nor_p(nor_p))
    DUT (
    .i(i),
    .o(o)
  );

endmodule
