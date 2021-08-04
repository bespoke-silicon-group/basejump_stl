module test_bsg
#(parameter in_width_p=4,
  parameter banks_p=1,
  parameter index_width_lp=$clog2((2**width_p+banks_p-1)/banks_p),
  parameter lg_banks_lp=`BSG_SAFE_CLOG2(banks_p),
  parameter debug_lp=0,
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

  wire [index_width_lp-1:0] index_i;
  wire [lg_banks_lp-1:0] bank_i;
  wire [width_p-1:0] o;

  bsg_hash_bank_reverse #(
    .in_width_p(in_width_p),
    .banks_p(banks_p))
    DUT (
    .index_i(index_i),
    .bank_i(bank_i),
    .o(o)
  );

endmodule
