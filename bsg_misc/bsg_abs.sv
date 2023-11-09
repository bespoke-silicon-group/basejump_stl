/**
 *  bsg_abs.sv
 *
 *  calculate absolute value of signed integer.
 *
 *  @author Tommy Jung
 */

`include "bsg_defines.sv"

module bsg_abs #( parameter `BSG_INV_PARAM(width_p) )
(
  input [width_p-1:0] a_i
  ,output logic [width_p-1:0] o
);

  assign o = a_i[width_p-1]
    ? (~a_i) + 1'b1
    : a_i;

endmodule

`BSG_ABSTRACT_MODULE(bsg_abs)
