/**
 *  bsg_mul_synth.v
 *
 *  synthesized multiplier
 */

`include "bsg_defines.v"

module bsg_mul_synth #(parameter `BSG_INV_PARAM(width_p))
(
  input [width_p-1:0] a_i
  , input [width_p-1:0] b_i
  , output logic [(2*width_p)-1:0] o
);


  assign o = a_i * b_i;

endmodule

`BSG_ABSTRACT_MODULE(bsg_mul_synth)
