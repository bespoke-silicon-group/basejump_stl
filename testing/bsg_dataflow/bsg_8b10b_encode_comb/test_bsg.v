module test_bsg
#(parameter cycle_time_p=10,
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

  wire [7:0] data_i;
  wire       k_i;
  wire       rd_i;
  wire [9:0] data_o;
  wire       rd_o;
  wire       kerr_o;

  bsg_8b10b_encode_comb DUT (
    .data_i(data_i),
    .k_i(k_i),
    .rd_i(rd_i),
    .data_o(data_o),
    .rd_o(rd_o),
    .kerr_o(kerr_o)
  );

endmodule
