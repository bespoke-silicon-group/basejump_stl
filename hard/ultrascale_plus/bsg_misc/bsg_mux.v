// Xilinx recommends for 3/4:1 clock muxes use 2 2:1 muxing instances
// https://docs.xilinx.com/r/2021.1-English/ug1387-acap-hardware-ip-platform-dev-methodology/Clock-Multiplexing

`include "bsg_defines.v"

module bsg_macro_clk_mux_2_1
   (
    input [1:0] data_i
    ,input sel_i
    ,output data_o
    );

  // BUFGMUX_CTRL: 2-to-1 General Clock MUX Buffer
  //               Versal Prime series
  // Xilinx HDL Language Template, version 2022.2
  // https://docs.xilinx.com/r/en-US/ug1344-versal-architecture-libraries/BUFGMUX_CTRL

  BUFGMUX_CTRL BUFGMUX_CTRL_inst (
     .O(data_o),
     .I0(data_i[0]),
     .I1(data_i[1]),
     .S(sel_i)
  );
endmodule

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
   
  if((harden_p == 1) && (balanced_p == 1)
        && els_p != 1)
    begin: macro
      if(els_p == 2)
        begin: mux2
          bsg_macro_clk_mux_2_1 m (.*);
        end

      else if(els_p == 3)
        begin: mux3
          if(sel_i == 2'h3)
            $error("invalid select value\n");

          wire data_1_0, data_3_2;
          bsg_macro_clk_mux_2_1 d_1_0
            (.data_i(data[1:0])
            ,.sel_i(sel_i[0])
            ,.data_o(data_1_0)
            );
          bsg_macro_clk_mux_2_1 d_3_2
            (.data_i({1'b0, data[2]})
            ,.sel_i(sel_i[0])
            ,.data_o(data_3_2)
            );
          bsg_macro_clk_mux_2_1 m
            (.data_i({data_3_2, data_1_0})
            ,.sel_i(sel_i[1])
            ,.data_o(data_o)
            );
        end

      else if(els_p == 4)
        begin: mux4
          wire data_1_0, data_3_2;
          bsg_macro_clk_mux_2_1 d_1_0
            (.data_i(data_i[1:0])
            ,.sel_i(sel_i[0])
            ,.data_o(data_1_2)
            );
          bsg_macro_clk_mux_2_1 d_3_2
            (.data_i(data_i[3:2])
            ,.sel_i(sel_i[0])
            ,.data_o(data_3_2)
            );
          bsg_macro_clk_mux_2_1 m
            (.data_i({data_3_2, data_1_0})
            ,.sel_i(sel_i[1])
            ,.data_o(data_o)
            );
        end

      else 
        $error("macro not instantiated; create one from 2/3/4:1 by referring to the Xilinx recommendations\n");

    end
  else
    begin: notmacro
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
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mux)
