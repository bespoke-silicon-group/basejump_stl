
// This module is useful for connecting two clock domains where the faster is a
//   synchronous multiple of the slower domain. This allows for maximum
//   throughput between the domains i.e. 1 transaction per slow clock.
// The interface is demanding on both sides. Most likely, this will connect
//   to a fifo on either side, but in the case of connecting two already
//   helpful modules, absorbing the fifos here would result in an additional
//   two cycles of latency
// IMPORTANT: The 'a' and 'b' clocks are NOT asynchronous. One must be
//   generated from the other. In Synopsys tools, the command is approximately
//   create_generated_clock \
//      -name "clk_2x" \
//      -source [get_pins "clk_1x"] \
//      -divide_by 2 \
//      [get_pins "clk_2x"]
//
// Parameters:
//   - x_period_p: the clock period of each clock. Only a relative (1:N) ratio
//       is currently supported
//
//  Notes:
//    - Only a strict clock period multiple is currently supported. However,
//        this module could be extended to use the LCM of the frequencies
//    - This implementation leaves only a fast clock period of latency to
//        actually complete the transaction. This should be acceptable for
//        small multiples, but for large multiples, it may be desirable to
//        latch the output signal to the faster clock, to give more slack.
//        Another solution would be to set a false path on the data line
module bsg_fifo_periodic
 #(parameter a_period_p   = "inv"
   , parameter b_period_p = "inv"
   )
  (input          a_clk_i
   , input        a_reset_i
   , input        a_v_i
   , output logic a_ready_and_o

   , input        b_clk_i
   , input        b_reset_i
   , output logic b_v_o
   , input        b_ready_and_i
   );

  localparam fast2slow_lp  = (a_period_p > b_period_p);
  localparam ratio_lp      = fast2slow_lp ? a_period_p : b_period_p;

  logic [ratio_lp-1:0] cnt_r;
  wire fast_clk   = fast2slow_lp ? a_clk_i   : b_clk_i;
  wire fast_reset = fast2slow_lp ? a_reset_i : b_reset_i;
  bsg_counter_clear_up_one_hot
   #(.max_val_p(ratio_lp-1))
   counter
    (.clk_i(fast_clk)
     ,.reset_i(fast_reset)

     ,.clear_i(1'b0)
     ,.up_i(1'b1)
     ,.count_r_o(cnt_r)
     );
  assign b_v_o         = cnt_r[ratio_lp-1] & a_v_i & ~a_reset_i & ~b_reset_i;
  assign a_ready_and_o = cnt_r[ratio_lp-1] & b_ready_and_i & ~a_reset_i & ~b_reset_i;

  //synopsys translate_off
  initial
    begin
      assert ((a_period_p == 1) || (b_period_p == 1))
        else $error("Only 1:N or N:1 division ratios are currently supported");
    end
  //synopsys translate_on

endmodule

