`include "bsg_defines.sv"

// Two channels with eight credits each need 2*4 bits to carry the credit counts; width_p=4 is too narrow.
// Elaboration must stop with the tunnel's own diagnostic; the Makefile requires
// that text and a failed build. Simulation is not needed for this check.
module test_bad_width;

  bit clk;
  bsg_nonsynth_clock_gen #(.cycle_time_p(10)) clock_gen (.o(clk));

  bsg_channel_tunnel
    #(.width_p(4)
      ,.num_in_p(2)
      ,.remote_credits_p(8)
      ,.lg_credit_decimation_p(3)
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
    $fatal(1, "[BSG_ERROR] width_p=4 with num_in_p=2 and remote_credits_p=8 was accepted");

endmodule
