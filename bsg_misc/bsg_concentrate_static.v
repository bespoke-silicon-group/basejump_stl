`include "bsg_defines.v"

// given a bunch of signals, and a bitvector parameter, gather/concentrate
// those bits together into a more condensed vector
//
// example: pattern_els_p = 5'b11101
//

module bsg_concentrate_static #(parameter pattern_els_p="inv", width_lp=$bits(pattern_els_p), set_els_lp=`BSG_COUNTONES_SYNTH(pattern_els_p))
(input [width_lp-1:0] i
 ,output [set_els_lp-1:0] o
);
   genvar j;

   if (pattern_els_p[0])
     assign o[0]=i[0];

   for (j = 1; j < width_lp; j=j+1)
     begin : rof
       if (pattern_els_p[j])
         assign o[`BSG_COUNTONES_SYNTH(pattern_els_p[j-1:0])] = i[j];
     end

endmodule

