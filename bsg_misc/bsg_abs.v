/**
 *  bsg_abs.v
 *
 *  calculate absolute value of signed integer.
 *
 *  @author Tommy Jung
 */

`include "bsg_defines.v"

module bsg_abs #( parameter width_p="inv" )
(
  input [width_p-1:0] a_i
  ,output logic [width_p-1:0] o
);

  assign o = a_i[width_p-1]
    ? (~a_i) + 1'b1
    : a_i;

endmodule
