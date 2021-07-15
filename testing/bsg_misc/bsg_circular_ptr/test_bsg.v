module test_bsg
#(parameter width_p=-1,
  parameter harden_p=1,
  parameter sim_clk_period=10,
  parameter reset_cycles_lo_p=-1,
  parameter reset_cycles_hi_p=-1,
  parameter ptr_width_lp = `BSG_SAFE_CLOG2(slots_p)
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

  wire clk;
  wire reset_i;
  wire [$clog2(max_add_p+1)-1:0] add_i;
  wire [ptr_width_lp-1:0] o;
  wire [ptr_width_lp-1:0] n_o;

  bsg_circular_ptr #(
    .slots_p(slots_p),
    .max_add_p(max_add_p)),
    .ptr_width_lp(ptr_width_lp)
    DUT (
    .clk(clk),
    .reset_i(reset_i),
    .add_i(add_i),
    .n_o(n_o),
    .o(o)
  );

endmodule
