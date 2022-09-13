module test_bsg
#(parameter els_p=4,
  parameter id_width_lp=`BSG_SAFE_CLOG2(els_p),
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

  wire clk_i;
  wire reset_i;
  wire [id_width_lp-1:0] alloc_id_o;
  wire alloc_v_o;
  wire alloc_yumi_i;
  wire dealloc_v_i;
  wire [id_width_lp-1:0] dealloc_id_i;

  bsg_id_pool #(
    .els_p(els_p),
    .id_width_lp(id_width_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .alloc_id_o(alloc_id_o),
    .alloc_v_o(alloc_v_o),
    .alloc_yumi_i(alloc_yumi_i),
    .dealloc_v_i(dealloc_v_i),
    .dealloc_id_i(dealloc_id_i)
  );

endmodule
