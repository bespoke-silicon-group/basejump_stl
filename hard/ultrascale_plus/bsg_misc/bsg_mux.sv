// Xilinx recommends for 3/4:1 clock muxes use 2 2:1 muxing instances
// https://docs.xilinx.com/r/2021.1-English/ug1387-acap-hardware-ip-platform-dev-methodology/Clock-Multiplexing

`include "bsg_defines.sv"

// macro datasheet: https://docs.xilinx.com/r/en-US/ug1344-versal-architecture-libraries/BUFGMUX_CTRL
`define bsg_macro_clk_mux(inst, data_o, data_i_1, data_i_0, sel_i) \
BUFGMUX_CTRL BUFGMUX_CTRL_``inst`` (                               \
   .O  (data_o),                                                   \
   .I0 (data_i_0),                                                 \
   .I1 (data_i_1),                                                 \
   .S  (sel_i)                                                     \
);

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
  
  // the following macros are for clock muxing only
  if((harden_p == 1) && (balanced_p == 1) && (width_p == 1) && (els_p == 2))
    begin: macro
      `bsg_macro_clk_mux(m, data_o, data_i[0], data_i[1], sel_i)
    end

  else if((harden_p == 1) && (balanced_p == 1) && (width_p == 1) && (els_p == 3))
    begin: macro
      wire data_1_0, data_3_2;
      `bsg_macro_clk_mux(m_1_0, data_1_0, data_i[1], data_i[0], sel_i[0])
      `bsg_macro_clk_mux(m_3_2, data_3_2, 1'b0     , data_i[2], sel_i[0])
      `bsg_macro_clk_mux(m    , data_o  , data_3_2 , data_1_0 , sel_i[1])
    end
  else if((harden_p == 1) && (balanced_p == 1) && (width_p == 1) && (els_p == 4))
    begin: macro
      wire data_1_0, data_3_2;
      `bsg_macro_clk_mux(m_1_0, data_1_0, data_i[1], data_i[0], sel_i[0])
      `bsg_macro_clk_mux(m_3_2, data_3_2, data_i[3], data_i[2], sel_i[0])
      `bsg_macro_clk_mux(m    , data_o  , data_3_2 , data_1_0 , sel_i[1])
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

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        assert(balanced_p == 0)
          else $error("%m warning: synthesizable implementation of bsg_mux does not support the provided parameters");
`endif
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mux)
