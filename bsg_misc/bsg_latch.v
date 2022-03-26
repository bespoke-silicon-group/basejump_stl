/**
 *    bsg_latch.v
 *
 */

`include "bsg_defines.v"

module bsg_latch
 #(parameter `BSG_INV_PARAM(width_p)
  (
    input clk_i
    , input [width_p-1:0] data_i
    , output logic [width_p-1:0] data_o
  );

  logic [width_p-1:0] data_r;
  
  always_latch
    if (clk_i)
      data_r <= data_i;

  // Version 4.213 of Verilator doesn't detect latches
  //   for data_o merged with data_r
  assign data_o = data_r;
  
endmodule

`BSG_ABSTRACT_MODULE(bsg_latch)

