module test_bsg
#(parameter width_p=4,
  parameter els_p=2,
  lg_els_lp=`BSG_SAFE_CLOG2(els_p),
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

  wire [els_p-1:0][width_p-1:0] data_i;
  wire [lg_els_lp-1:0] sel_i;
  wire [els_p-1:0][width_p-1:0] data_o;

  bsg_mux_butterfly #(
    .width_p(width_p),
    .els_p(els_p),
    .lg_els_lp(lg_els_lp))
    DUT (
    .data_i(data_i),
    .sel_i(sel_i),
    .data_o(data_o)
  );

endmodule
