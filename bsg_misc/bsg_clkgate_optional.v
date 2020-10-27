// MBT: This module has a broken interface because it uses bypass_i as a live input, which could use glitching
// MBT: This module should never be used in actual synthesized RTL; it must be hardened.
// For this reason, I am guarding it with an ifndef SYNTHESIS and we can fix it later.

`include "bsg_defines.v"

`ifndef SYNTHESIS

// This is an integrated clock cell using a negative latch and an AND gate
// This logic may be susceptible bug if en_i changes multiple times within a clk cyle

module bsg_clkgate_optional  (input  clk_i
                             ,input  en_i
                             ,input  bypass_i
                             ,output gated_clock_o
                             );
  //wire en_latch;                  
  //assign en_latch = (reset_i) ?  1'b0 :
  //                    (~clk_i)  ?  en_i : en_latch;

  wire latched_en_lo;

  bsg_dlatch #(.width_p(1), .i_know_this_is_a_bad_idea_p(1))
    en_latch
      ( .clk_i  ( ~clk_i )
      , .data_i ( en_i )
      , .data_o ( latched_en_lo  )
      );
  
  assign gated_clock_o = (latched_en_lo|bypass_i) & clk_i;

endmodule

`endif
