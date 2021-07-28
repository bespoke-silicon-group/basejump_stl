module test_bsg
#(parameter sim_clk_period=10,
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
  wire data_i;
  wire [7:0] data_o;
  wire       k_o;
  wire       v_o;
  wire       frame_align_o;

  bsg_8b10b_shift_decoder DUT (
    .clk_i(clk_i),
    .data_i(data_i),
    .data_o(data_o),
    .k_o(k_o),
    .v_o(v_o),
    .frame_align_o(frame_align_o)
  );

endmodule
