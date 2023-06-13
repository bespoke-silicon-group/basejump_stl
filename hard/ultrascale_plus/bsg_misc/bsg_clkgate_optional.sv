`include "bsg_defines.sv"

module bsg_clkgate_optional
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
endmodule
