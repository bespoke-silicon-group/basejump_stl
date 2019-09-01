/**
 *  bsg_expand.v
 *
 *  This module expands each bit in the input vector by the factor of
 *  expand_p.
 *  
 *  @author tommy
 *
 */


module bsg_expand #(parameter in_width_p="inv", expand_p="inv")
(
  input [in_width_p-1:0] i
  , output logic [(in_width_p*expand_p)-1:0] o
);


  always_comb
    for (integer k = 0; k < in_width_p; k++)
      o[expand_p*k+:expand_p] = {expand_p{i[k]}};


endmodule
