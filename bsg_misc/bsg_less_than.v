/**
 *  bsg_less_than.v
 *
 *  @author Tommy Jung
 */

`include "bsg_defines.v"

module bsg_less_than #(parameter `BSG_INV_PARAM(width_p)) (
  input [width_p-1:0] a_i
  ,input [width_p-1:0] b_i
  ,output logic o       // a is less than b
  );

  assign o =  (a_i < b_i);

endmodule

`BSG_ABSTRACT_MODULE(bsg_less_than)
