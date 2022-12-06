// Xilinx recommends for 3/4:1 clock muxes, using 2 2:1 muxing instances
// https://docs.xilinx.com/r/2021.1-English/ug1387-acap-hardware-ip-platform-dev-methodology/Clock-Multiplexing

`include "bsg_defines.v"
module bsg_mux #(parameter `BSG_INV_PARAM(width_p)
                 , parameter els_p=1
                 , parameter harden_p = 0
                 , parameter balanced_p = 0
                 , parameter lg_els_lp=`BSG_SAFE_CLOG2(els_p)
                 )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [lg_els_lp-1:0] sel_i
    ,output [width_p-1:0] data_o
    );
   
  if ((els_p == 3 || els_p == 4) && 
       (harden_p == 1) && (balanced_p == 1))
    begin: xilinx
      wire clk_0_1;
      // BUFGMUX_CTRL: 2-to-1 General Clock MUX Buffer
      //               Versal Prime series
      // Xilinx HDL Language Template, version 2022.2
      // https://docs.xilinx.com/r/en-US/ug1344-versal-architecture-libraries/BUFGMUX_CTRL
      
      BUFGMUX_CTRL BUFGMUX_CTRL_0_1 (
         .O(clk_0_1),
         .I0(data_i[0]),
         .I1(data_i[1]),
         .S(sel_i[0])
      );

      wire clk_2_3;
      wire data_3 = (els_p == 3) ? 1'b0 : data_i[3];
      BUFGMUX_CTRL BUFGMUX_CTRL_2_3 (
         .O(clk_2_3),
         .I0(data_i[2]),
         .I1(data_3),
         .S(sel_i[0])
      );

      BUFGMUX_CTRL BUFGMUX_CTRL_o (
         .O(data_o),
         .I0(clk_0_1),
         .I1(clk_2_3),
         .S(sel_i[1])
      );
    end
  else
    begin: normal
      if (els_p == 1)
        begin
          assign data_o = data_i;
          wire unused = sel_i;
        end
      else
        assign data_o = data_i[sel_i];

  // synopsys translate_off
  initial
    assert(balanced_p == 0)
      else $error("%m warning: synthesizable implementation of bsg_mux does not support balanced_p");
  // synopsys translate_on

endmodule

`BSG_ABSTRACT_MODULE(bsg_mux)

