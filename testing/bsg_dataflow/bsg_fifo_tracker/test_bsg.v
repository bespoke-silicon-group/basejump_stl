module test_bsg
#(parameter els_p=2,
  ptr_width_lp = `BSG_SAFE_CLOG2(els_p),
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
  wire enq_i;
  wire deq_i;
  wire [ptr_width_lp-1:0] wptr_r_o;
  wire [ptr_width_lp-1:0] rptr_r_o;
  wire [ptr_width_lp-1:0] rptr_n_o;
  wire full_o;
  wire empty_o;

  bsg_fifo_tracker #(
    .els_p(els_p),
    .ptr_width_lp(ptr_width_lp))
    DUT (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .enq_i(enq_i),
    .deq_i(deq_i),
    .wptr_r_o(wptr_r_o),
    .rptr_r_o(rptr_r_o),
    .rptr_n_o(rptr_n_o),
    .full_o(full_o),
    .empty_o(empty_o)
  );

endmodule
