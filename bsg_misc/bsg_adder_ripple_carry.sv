/**
 *  bsg_adder_ripple_carry.sv
 *
 *  @author Tommy Jung
 */

`include "bsg_defines.sv"

module bsg_adder_ripple_carry #(parameter `BSG_INV_PARAM(width_p ))
  (
    input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , output logic [width_p-1:0] s_o
    , output logic c_o
    );

  assign {c_o, s_o} = a_i + b_i;

endmodule

`BSG_ABSTRACT_MODULE(bsg_adder_ripple_carry)
