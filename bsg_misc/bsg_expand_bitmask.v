/**
 *  bsg_expand_bitmask.v
 *
 *  This module expands each bit in the input vector by the factor of
 *  expand_p.
 *  
 *  @author tommy
 * 
 *
 *  example
 *  ------------------------
 *  in_width_p=2, expand_p=4
 *  ------------------------
 *  i=00 -> o=0000_0000
 *  i=01 -> o=0000_1111
 *  i=10 -> o=1111_0000
 *  i=11 -> o=1111_1111
 *
 */


`include "bsg_defines.v"

module bsg_expand_bitmask #(parameter in_width_p="inv", expand_p="inv")
(
  input [in_width_p-1:0] i
  , output logic [(in_width_p*expand_p)-1:0] o
);


  always_comb
    for (integer k = 0; k < in_width_p; k++)
      o[expand_p*k+:expand_p] = {expand_p{i[k]}};


endmodule
