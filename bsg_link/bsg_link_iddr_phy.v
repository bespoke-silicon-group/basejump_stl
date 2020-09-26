
//
// Paul Gao 03/2019
//
// Input DDR PHY 
//
// The output data is a 2x wide data bus synchronized to the posedge of clk_i
// The MSBs of the output data is the negedge registered data while the LSBs of the 
// output data is the posedge registered data
// * Posedge (LSB) data received earlier in time than MSB data
//
// Note that input clock edges must be center-aligned to input data signals
// Need input delay constraint(s) to ensure clock and data delay are same
//
// Schematic and more information: (Google Doc) 
// https://docs.google.com/document/d/1lmkOxvlAvxrk_MM5W8xv3ho2DS26xbOMTCqUIyS6di8/edit?ts=5cf76063#heading=h.o6ptt6mn49us
//
//

`include "bsg_defines.v"

module bsg_link_iddr_phy

 #(parameter width_p = "inv")

  (input                  clk_i
  ,input  [width_p-1:0]   data_i
  ,output [2*width_p-1:0] data_r_o
  );
  
  logic [2*width_p-1:0] data_rr;
  logic [width_p-1:0] data_n_r, data_p_r;
  
  assign data_r_o = data_rr;

  always_ff @(posedge clk_i) 
    // First buffer posedge data into data_p_r
    data_p_r <= data_i;
  
  always_ff @(negedge clk_i)
    // Then buffer negedge data into data_n_r
    data_n_r <= data_i;
    
  always_ff @(posedge clk_i) 
    // Finally output to the data_rr flop
    // data_p_r occurs logically earlier in time than data_n_r
    data_rr <= {data_n_r, data_p_r};

endmodule