`include "bsg_defines.sv"

// Eight credits cannot be returned sixteen at a time (lg_credit_decimation_p=4).
// Elaboration must stop with the tunnel's own diagnostic; the Makefile requires
// that text and a failed build. Simulation is not needed for this check.
module test_bad_decimation;

  bit clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(10)) clock_gen (.o(clk));

  bsg_channel_tunnel
    #(.width_p(16)
      ,.num_in_p(2)
      ,.remote_credits_p(8)
      ,.lg_credit_decimation_p(4)
      ) dut
    (.clk_i(clk)
     ,.reset_i(1'b1)
     ,.multi_data_i('0)
     ,.multi_v_i(1'b0)
     ,.multi_yumi_o()
     ,.multi_data_o()
     ,.multi_v_o()
     ,.multi_yumi_i(1'b0)
     ,.data_i('0)
     ,.v_i('0)
     ,.yumi_o()
     ,.data_o()
     ,.v_o()
     ,.yumi_i('0)
     );

  initial
    $fatal(1, "[BSG_ERROR] remote_credits_p=8 with lg_credit_decimation_p=4 was accepted");

endmodule
