// takes an input vector and spreads the elements according to a bit pattern
// example width_p=3, pattern_els_p=5'b10101
module bsg_unconcentrate_static #(pattern_els_p="inv"
                                  , width_lp=`BSG_COUNTONES_SYNTH(pattern_els_p)
                                 )
(input [width_lp-1:0] i
 ,output [$bits(pattern_els_p)-1:0] o
 );
   genvar j;

   if (pattern_els_p[0])
     assign o[0] = i[0];
   else
     assign o[0] = `BSG_DISCONNECTED_IN_SIM(1'b0);

   for (j = 1; j < $bits(pattern_els_p); j=j+1)
     begin: rof
             if (pattern_els_p[j])
               assign o[j] = i[`BSG_COUNTONES_SYNTH(pattern_els_p[j-1:0])];
             else
               assign o[j] = `BSG_DISCONNECTED_IN_SIM(1'b0);
     end

endmodule
