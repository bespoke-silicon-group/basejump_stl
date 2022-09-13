module test_bsg
#(parameter width_p=32,
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
  wire v_i;
  wire ready_and_o;
  wire zero_divisor_i;
  wire signed_div_r_i;
  wire adder_result_is_neg_i;
  wire opA_is_neg_i;
  wire opC_is_neg_i;
  wire opA_sel_o;
  wire opA_ld_o;
  wire opA_inv_o;
  wire opA_clr_l_o;
  wire [2:0] opB_sel_o;
  wire opB_ld_o;
  wire opB_inv_o;
  wire opB_clr_l_o;
  wire [2:0] opC_sel_o;
  wire opC_ld_o;
  wire latch_signed_div_o;
  wire adder_cin_o;
  wire v_o;
  wire yumi_i;

  bsg_id_pool #(
    .width_p(width_p))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .v_i(v_i),
    .ready_and_o(ready_and_o),
    .zero_divisor_i(zero_divisor_i),
    .signed_div_r_i(signed_div_r_i),
    .adder_result_is_neg_i(adder_result_is_neg_i),
    .opA_is_neg_i(opA_is_neg_i),
    .opC_is_neg_i(opC_is_neg_i),
    .opA_sel_o(opA_sel_o),
    .opA_ld_o(opA_ld_o),
    .opA_inv_o(opA_inv_o),
    .opA_clr_l_o(opA_clr_l_o),
    .opB_sel_o(opB_sel_o),
    .opB_ld_o(opB_ld_o),
    .opB_inv_o(opB_inv_o),
    .opB_clr_l_o(opB_clr_l_o),
    .opC_sel_o(opC_sel_o),
    .opC_ld_o(opC_ld_o),
    .latch_signed_div_o(latch_signed_div_o),
    .adder_cin_o(adder_cin_o),
    .v_o(v_o),
    .yumi_i(yumi_i)
  );

endmodule
