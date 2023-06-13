/**
 *  bsg_expand_bitmask.sv
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


`include "bsg_defines.sv"

module bsg_expand_bitmask #(parameter `BSG_INV_PARAM(in_width_p)
                           ,parameter `BSG_INV_PARAM(expand_p)
                           ,localparam safe_expand_lp = `BSG_MAX(expand_p, 1))
(
  input [in_width_p-1:0] i
  , output logic [(in_width_p*safe_expand_lp)-1:0] o
);


  always_comb
    for (integer k = 0; k < in_width_p; k++)
      o[safe_expand_lp*k+:safe_expand_lp] = {safe_expand_lp{i[k]}};


endmodule

`BSG_ABSTRACT_MODULE(bsg_expand_bitmask)
