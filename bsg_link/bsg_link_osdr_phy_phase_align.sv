
//
// Paul Gao 02/2021
//
// This module generates 180-degree-phase-shifted clock (inverted clock)
//
// Input clock runs at 1x speed
// Output clock is generated with XOR logic
// Waveform below shows the detailed behavior of the module
//
// THIS MODULE SHOULD BE HARDENED TO IMPROVE QUALITY OF CLK_O
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
          +--------+
reset_i            |
                   +------------------------------------------------------+
                           +-------+       +-------+       +-------+
clk_r_p                    |       |       |       |       |       |
          +----------------+       +-------+       +-------+       +------+
                       +-------+       +-------+       +-------+       +--+
clk_r_n                |       |       |       |       |       |       |
          +------------+       +-------+       +-------+       +-------+
                       +---+   +---+   +---+   +---+   +---+   +---+   +--+
clk_o                  |   |   |   |   |   |   |   |   |   |   |   |   |
          +------------+   +---+   +---+   +---+   +---+   +---+   +---+

****************************************************************************/

`include "bsg_defines.sv"

module bsg_link_osdr_phy_phase_align

  (input  clk_i
  ,input  reset_i
  ,output clk_o
  );

  logic clk_r_p, clk_r_n;

  bsg_xor #(.width_p(1)) clk_xor
  (.a_i(clk_r_p),.b_i(clk_r_n),. o(clk_o));

  bsg_dff_reset #(.width_p(1),.reset_val_p(0)) clk_ff_p
  (.clk_i(clk_i),.reset_i(reset_i),.data_i(~clk_r_p),.data_o(clk_r_p));

  bsg_dff_reset #(.width_p(1),.reset_val_p(0)) clk_ff_n
  (.clk_i(~clk_i),.reset_i(reset_i),.data_i(~clk_r_n),.data_o(clk_r_n));

`ifndef BSG_HIDE_FROM_SYNTHESIS
  initial
  begin
    $display("## %L: instantiating unhardened bsg_link_osdr_phase_align (%m)");
  end
`endif

endmodule
