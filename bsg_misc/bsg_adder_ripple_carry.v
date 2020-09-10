/**
 *  bsg_adder_ripple_carry.v
 *
 *  @author Tommy Jung
 */

`include "bsg_defines.v"

module bsg_adder_ripple_carry #(parameter width_p = "inv")
  (
    input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , output logic [width_p-1:0] s_o
    , output logic c_o
    );

  assign {c_o, s_o} = a_i + b_i;

endmodule
