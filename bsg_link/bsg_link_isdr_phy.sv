
//
// Paul Gao 02/2021
//
// This is an input SDR PHY
//
// clk_i is center-aligned to data_i
// Waveform below shows the detailed behavior of the module
//
/****************************************************************************

                       +---+   +---+   +---+   +---+   +---+   +---+   +--+
clk_i/clk_o            |   |   |   |   |   |   |   |   |   |   |   |   |
          +------------+   +---+   +---+   +---+   +---+   +---+   +---+
          -----------------+-------+-------+-------+-------+-------+-------
data_i           D00       |  D01  |  D02  |  D03  |  D04  |  D05  |  D06
          -----------------------------------------------------------------
          -----------------------------------------------------------------
data_o               D00                |  D01  |  D02  |  D03  |  D04  |
          ------------------------------+-------+-------+-------+-------+--

****************************************************************************/

`include "bsg_defines.sv"

module bsg_link_isdr_phy

 #(parameter `BSG_INV_PARAM(width_p ))

  (input                clk_i
  ,output               clk_o
  ,input  [width_p-1:0] data_i
  ,output [width_p-1:0] data_o
  ,input                token_i
  ,output               token_o
  );

  assign clk_o = clk_i;
  assign token_o = token_i;

  bsg_dff #(.width_p(width_p)) data_ff 
  (.clk_i(clk_i),.data_i(data_i),.data_o(data_o));

endmodule

`BSG_ABSTRACT_MODULE(bsg_link_isdr_phy)
