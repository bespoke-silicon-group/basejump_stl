
//
// Paul Gao 03/2019
//
// This is an output DDR PHY
//
// Output clock is center-aligned to output data
// Theoretically clk_r_o is always centered to data_r_o, because negedge of clk_i
// has 90-degree phase delay to posedge of clk_i.
// Need output delay constraint(s) to ensure clock and data delay are same
//
// Waveform of all signals when going out of reset:
/******************************************************************************************

          +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+
clk_i         |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
              +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+   +---+
          +--------+
reset_i            |
                   +----------------------------------------------------------------------+
          +----------------+
reset_i_r                  |
                           +--------------------------------------------------------------+
                               +-------+       +-------+       +-------+       +-------+
clk_r                          |       |       |       |       |       |       |       |
          +--------------------+       +-------+       +-------+       +-------+       +---
                           +-------+       +-------+       +-------+       +-------+
odd_r                      |       |       |       |       |       |       |       |
          +----------------+       +-------+       +-------+       +-------+       +-------
          +----------------+       +-------+       +-------+       +-------+       +-------
ready_o                    |       |       |       |       |       |       |       |
                           +-------+       +-------+       +-------+       +-------+
          +--------+-----------------------------------------------------------------------
data_i    |        | d1d0  |       | d1d0  |       | d1d0  |       | d1d0  |       | d1d0
          +--------------------------------------------------------------------------------
          +--------------------------------------------------------------------------------
data_i_r  |                |     d1d0      |     d1d0      |     d1d0      |     d1d0
          +----------------+---------------------------------------------------------------
                                       +-------+       +-------+       +-------+       +---
clk_o                                  |       |       |       |       |       |       |
          +----------------------------+       +-------+       +-------+       +-------+
          +--------------------------------+---------------+---------------+---------------
data_o    |                        |  d0   |  d1   |  d0   |  d1   |  d0   |  d1   |  d0
          +------------------------+-------+-------+-------+-------+-------+-------+-------

******************************************************************************************/
//
// Schematic and more information: (Google Doc) 
// https://docs.google.com/document/d/1lmkOxvlAvxrk_MM5W8xv3ho2DS26xbOMTCqUIyS6di8/edit?ts=5cf76063#heading=h.o6ptt6mn49us
//
//

module bsg_link_oddr_phy_hard

 #(parameter width_p = "inv")

  (// reset, data and ready signals synchronous to clk_i
   // no valid signal required (assume valid_i is constant 1)
   input                      reset_i
  ,input                      clk_i
  ,input                      clk90_i
  ,input [1:0][width_p-1:0]   data_i
  ,output                     ready_o
   // output clock and data
  ,output logic [width_p-1:0] data_r_o
  ,output logic               clk_r_o
  );
  
  assign ready_o = 1'b1;
  logic [width_p-1:0] data_r_lo;
  
  always_ff @(posedge clk_i or negedge clk_i)
  begin
    if (reset_i)
      begin
        data_r_o <= '0;
      end
    else if (clk_i)
      begin
        data_r_o <= data_i[0];
        data_r_lo <= data_i[1];
      end
    else
      begin
        data_r_o <= data_r_lo;
      end
  end

  always_ff @(posedge clk90_i or negedge clk90_i)
    if (reset_i)
        clk_r_o <= 1'b0;
    else if (clk90_i)
        clk_r_o <= 1'b1;
    else
        clk_r_o <= 1'b0;
  
endmodule
