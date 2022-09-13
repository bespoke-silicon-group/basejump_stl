module test_bsg
#(parameter vec_size_lp=4,
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

  wire [vec_size_lp-1:0] vec_i;
  wire [vec_size_lp*`BSG_SAFE_CLOG2(vec_size_lp)-1:0] fwd_o;
  wire [vec_size_lp*`BSG_SAFE_CLOG2(vec_size_lp)-1:0] fwd_datapath_o;
  wire [vec_size_lp*`BSG_SAFE_CLOG2(vec_size_lp)-1:0] bk_o;
  wire [vec_size_lp*`BSG_SAFE_CLOG2(vec_size_lp)-1:0] bk_datapath_o  ;

  bsg_scatter_gather #(
    .vec_size_lp(vec_size_lp))
    DUT (
    .vec_i(vec_i),
    .fwd_o(fwd_o),
    .fwd_datapath_o(fwd_datapath_o),
    .bk_o(bk_o),
    .bk_datapath_o(bk_datapath_o)
  );

endmodule
