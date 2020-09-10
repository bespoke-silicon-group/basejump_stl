/**
 *  bsg_swap.v
 *
 *  @author tommy
 */

`include "bsg_defines.v"

module bsg_swap
  #(parameter width_p="inv")
  (
    input [1:0][width_p-1:0] data_i
    , input swap_i
    , output logic [1:0][width_p-1:0] data_o
  );

  assign data_o = swap_i
    ? {data_i[0], data_i[1]}
    : {data_i[1], data_i[0]};
  
endmodule
