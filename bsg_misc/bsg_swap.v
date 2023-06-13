/**
 *  bsg_swap.sv
 *
 *  @author tommy
 */

`include "bsg_defines.sv"

module bsg_swap
  #(parameter `BSG_INV_PARAM(width_p))
  (
    input [1:0][width_p-1:0] data_i
    , input swap_i
    , output logic [1:0][width_p-1:0] data_o
  );

  assign data_o = swap_i
    ? {data_i[0], data_i[1]}
    : {data_i[1], data_i[0]};
  
endmodule

`BSG_ABSTRACT_MODULE(bsg_swap)
