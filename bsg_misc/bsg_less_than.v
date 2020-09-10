/**
 *  bsg_less_than.v
 *
 *  @author Tommy Jung
 */

`include "bsg_defines.v"

module bsg_less_than #(parameter width_p="inv") (
  input [width_p-1:0] a_i
  ,input [width_p-1:0] b_i
  ,output logic o       // a is less than b
  );

  assign o =  (a_i < b_i);

endmodule
