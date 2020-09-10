`include "bsg_defines.v"

module bsg_reduce_segmented #(parameter segments_p = "inv"
                              ,parameter segment_width_p = "inv"

                  , parameter xor_p = 0
                  , parameter and_p = 0
                  , parameter or_p = 0
                  , parameter nor_p = 0                        
                  )
  (input    [segments_p*segment_width_p-1:0] i
   , output [segments_p-1:0] o
    );

   // synopsys translate_off
   initial
     assert( $countones({xor_p[0], and_p[0], or_p[0], nor_p[0]}) == 1)
       else $error("%m: exactly one function may be selected\n");

  // synopsys translate_on

  
  genvar j;
  
  for (j = 0; j < segments_p; j=j+1)
  begin: rof2
  if (xor_p)
    assign o[j] = ^i[(j*segment_width_p)+:segment_width_p];
   else if (and_p)
     assign o[j] = &i[(j*segment_width_p)+:segment_width_p];
   else if (or_p)
     assign o[j] = |i[(j*segment_width_p)+:segment_width_p];
    else if (nor_p)
      assign o[j] = ~(|i[(j*segment_width_p)+:segment_width_p]);
  end
    
endmodule
