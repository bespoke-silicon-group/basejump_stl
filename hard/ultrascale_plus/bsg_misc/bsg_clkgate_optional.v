`include "bsg_defines.v"

module bsg_clkgate_optional
    #( parameter is_ce_inverted = 1'b0
       , parameter is_i_inverted  = 1'b0
     )
    (input  clk_i
     ,input  en_i
     ,input  bypass_i // unused
     ,output gated_clock_o
     );

  // BUFGCE: General Clock Buffer with Clock Enable
  //         UltraScale
  // Xilinx HDL Language Template, version 2021.1

  BUFGCE #(
     .CE_TYPE("SYNC"),
     .IS_CE_INVERTED(is_ce_inverted),
     .IS_I_INVERTED(is_i_inverted),
     .SIM_DEVICE("ULTRASCALE_PLUS")
  )
  BUFGCE_inst (
     .O(gated_clock_o),
     .CE(en_i),
     .I(clk_i)
  );

  // End of BUFGCE_inst instantiation
endmodule
