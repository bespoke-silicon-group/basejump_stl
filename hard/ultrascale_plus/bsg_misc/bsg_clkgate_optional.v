`include "bsg_defines.v"

module bsg_clkgate_optional #(parameter harden_p = 0)
    
            (input  clk_i
             ,input  en_i
             ,input  bypass_i
             ,output gated_clock_o
             );

  if(harden_p)
    begin: macro
      // BUFGCE: General Clock Buffer with Clock Enable
      //         UltraScale
      // Xilinx HDL Language Template, version 2021.1

      BUFGCE #(
         .CE_TYPE("SYNC"),
         .IS_CE_INVERTED(1'b0),
         .IS_I_INVERTED(1'b0),
         .SIM_DEVICE("ULTRASCALE_PLUS")
      )
      BUFGCE_inst (
         .O(gated_clock_o),
         .CE(en_i),
         .I(clk_i)
      );

      // End of BUFGCE_inst instantiation
    end

`ifndef SYNTHESIS
// MBT: This module has a broken interface because it uses bypass_i as a live input, which could use glitching
// MBT: This module should never be used in actual synthesized RTL; it must be hardened.
// For this reason, I am guarding it with an ifndef SYNTHESIS and we can fix it later.
// This is an integrated clock cell using a negative latch and an AND gate
// This logic may be susceptible bug if en_i changes multiple times within a clk cyle
  else 
    begin: notmacro
      wire latched_en_lo;

      bsg_dlatch #(.width_p(1), .i_know_this_is_a_bad_idea_p(1))
        en_latch
          ( .clk_i  ( ~clk_i )
          , .data_i ( en_i )
          , .data_o ( latched_en_lo  )
          );
      
      assign gated_clock_o = (latched_en_lo|bypass_i) & clk_i;
    end
`endif

endmodule
