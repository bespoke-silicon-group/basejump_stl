
//
// Paul Gao 02/2021
//
// This is an output SDR PHY
//
// clk_o is center-aligned to data_o and is inverted from clk_i
// Waveform below shows the detailed behavior of the module
//
// WARNING:
// Source of clk_o is combinational logic instead of a register
// Duty-cycle of clk_o may not be ideal under certain cirtumstances
// Using negedge of clk_o may result in timing violation
//
/****************************************************************************

          +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+
clk_i         |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
              +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+
          -----------------+-------+-------+-------+-------+-------+-------
data_i           D00       |  D01  |  D02  |  D03  |  D04  |  D05  |  D06
          -----------------------------------------------------------------
                       +---+   +---+   +---+   +---+   +---+   +---+   +--+
clk_o                  |   |   |   |   |   |   |   |   |   |   |   |   |
          +------------+   +---+   +---+   +---+   +---+   +---+   +---+
          -----------------------------------------------------------------
data_o               D00           |  D01  |  D02  |  D03  |  D04  |  D05
          -------------------------+-------+-------+-------+-------+-------

****************************************************************************/

`include "bsg_defines.sv"

module bsg_link_osdr_phy

 #(parameter `BSG_INV_PARAM(width_p )
  ,parameter strength_p = 0)

  (input                clk_i
  ,input                reset_i
  ,input  [width_p-1:0] data_i
  ,output               clk_o
  ,output [width_p-1:0] data_o
  ,input                token_i
  ,output               token_o
  );

  assign token_o = token_i;

  bsg_link_osdr_phy_phase_align clk_pa
  (.clk_i  (clk_i)
  ,.reset_i(reset_i)
  ,.clk_o  (clk_o)
  );

  bsg_dff #(.width_p(width_p)) data_ff 
  (.clk_i(clk_i),.data_i(data_i),.data_o(data_o));

endmodule

`BSG_ABSTRACT_MODULE(bsg_link_osdr_phy)
