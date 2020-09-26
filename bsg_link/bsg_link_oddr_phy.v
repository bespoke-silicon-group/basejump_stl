
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

`include "bsg_defines.v"

module bsg_link_oddr_phy

 #(parameter width_p = "inv")

  (// reset, data and ready signals synchronous to clk_i
   // no valid signal required (assume valid_i is constant 1)
   input                      reset_i
  ,input                      clk_i
  ,input [1:0][width_p-1:0]   data_i
  ,output                     ready_o
   // output clock and data
  ,output logic [width_p-1:0] data_r_o
  ,output logic               clk_r_o
  );
  
  logic odd_r, clk_r, reset_i_r;  
  logic [1:0][width_p-1:0] data_i_r;
  
  // ready to accept new data every two cycles
  assign ready_o = ~odd_r;
  
  // register 2x-wide input data in flops
  always_ff @(posedge clk_i)
    if (~odd_r)
        data_i_r <= data_i;
        
  // odd_r signal (mux select bit)
  always_ff @(posedge clk_i)
    if (reset_i)
        odd_r <= 1'b0;
    else 
        odd_r <= ~odd_r;
  
  // reset_i is sync to posedge of clk_i, while clk_r is sync to negedge.
  // This will potentially become critical path (only 1/2 period max delay).
  // Add an extra flop for clk_r reset.
  always_ff @(posedge clk_i)
    reset_i_r <= reset_i;
  
  // clock output
  always_ff @(negedge clk_i)
  begin
    if (reset_i_r)
        clk_r <= 1'b0;
    else 
        clk_r <= ~clk_r;
    // Logically, clk_o launch flop is not necessary
    // Add launch flop for clk_o signal for two reasons:
    // 1. Easier to center-align with data bits on ASIC (symmetric to data launch flops)
    // 2. Pack-up register into IOB on FPGA
    clk_r_o <= clk_r;
  end
  
  // data launch flops
  // odd_r is not a reset; should not need to put a reset in here

  always_ff @(posedge clk_i)
    if (odd_r) 
        data_r_o <= data_i_r[0];
    else 
        data_r_o <= data_i_r[1];

endmodule
