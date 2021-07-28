module test_bsg
#(parameter max_tokens_p=4,
  parameter lg_credit_to_token_decimation_p=1,
  parameter count_negedge_p=0,
  parameter extra_margin_p=0,
  parameter check_excess_credits_p=1,
  parameter start_full_p=1,
  parameter use_async_w_reset_p=0,
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

  wire w_clk_i;
  wire w_inc_token_i;
  wire w_reset_i;
  wire r_clk_i;
  wire r_reset_i;
  wire r_dec_credit_i;
  wire r_infinite_credits_i;
  wire r_credits_avail_o;

  bsg_async_credit_counter #(
    .max_tokens_p(max_tokens_p),
    .lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p),
    .count_negedge_p(count_negedge_p),
    .extra_margin_p(extra_margin_p),
    .check_excess_credits_p(check_excess_credits_p),
    .start_full_p(start_full_p),
    .use_async_w_reset_p(use_async_w_reset_p))
    DUT (
    .w_clk_i(w_clk_i),
    .w_reset_i(w_reset_i),
    .w_inc_token_i(w_inc_token_i),
    .r_clk_i(r_clk_i),
    .r_reset_i(r_reset_i),
    .r_dec_credit_i(r_dec_credit_i),
    .r_infinite_credits_i(r_infinite_credits_i),
    .r_credits_avail_o(r_credits_avail_o)
  );

endmodule
