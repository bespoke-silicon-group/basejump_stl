
//
// Paul Gao 02/2021
//
// This module generates 180-degree-phase-shifted clock (inverted clock)
//
// Input clock runs at 1x speed
// Output clock is generated with XOR logic
// Waveform below shows the detailed behavior of the module
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

module bsg_link_osdr_phy_phase_align

  (input  clk_i
  ,input  reset_i
  ,output clk_o
  );

  logic clk_r_p, clk_r_n;
  assign clk_o = clk_r_p ^ clk_r_n;

  bsg_dff_reset #(.width_p(1),.reset_val_p(0)) clk_ff_p
  (.clk_i(clk_i),.reset_i(reset_i),.data_i(~clk_r_p),.data_o(clk_r_p));

  bsg_dff_reset #(.width_p(1),.reset_val_p(0)) clk_ff_n
  (.clk_i(~clk_i),.reset_i(reset_i),.data_i(~clk_r_n),.data_o(clk_r_n));

endmodule
