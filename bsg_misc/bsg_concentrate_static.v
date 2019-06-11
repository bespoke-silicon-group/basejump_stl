module bsg_concentrate_static #(parameter width_p="inv", pattern_els_p="inv", set_els_lp=`BSG_COUNTONES_SYNTH(pattern_els_p))
(input [width_p-1:0] i
 ,output [set_els_lp-1:0] o
 );
   genvar j;

   if (pattern_els_p[0])
     assign o[0]=i[0];
   
   for (j = 1; j < width_p; j=j+1)
     begin : rof
        if (pattern_els_p[j])
          assign o[`BSG_COUNTONES_SYNTH(pattern_els_p[j-1:0])] = i[j];
     end
      
endmodule
