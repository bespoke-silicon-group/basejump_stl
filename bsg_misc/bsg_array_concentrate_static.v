`include "bsg_defines.v"

module bsg_array_concentrate_static 
  #(parameter pattern_els_p="inv"
    , parameter width_p="inv"
    , dense_els_lp=$bits(pattern_els_p)
    , sparse_els_lp=`BSG_COUNTONES_SYNTH(pattern_els_p))
  (input    [dense_els_lp-1:0][width_p-1:0] i
   ,output [sparse_els_lp-1:0][width_p-1:0] o
);
   genvar j;

   if (pattern_els_p[0])
     assign o[0]=i[0];

  for (j = 1; j < dense_els_lp; j=j+1)
     begin : rof
       if (pattern_els_p[j])
         assign o[`BSG_COUNTONES_SYNTH(pattern_els_p[j-1:0])] = i[j];
     end

endmodule
