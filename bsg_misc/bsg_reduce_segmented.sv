`include "bsg_defines.sv"

module bsg_reduce_segmented #(parameter `BSG_INV_PARAM(segments_p )
                              ,parameter `BSG_INV_PARAM(segment_width_p )

                  , parameter xor_p = 0
                  , parameter and_p = 0
                  , parameter or_p = 0
                  , parameter nor_p = 0                        
                  )
  (input    [segments_p*segment_width_p-1:0] i
   , output [segments_p-1:0] o
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
   initial
     assert( $countones({xor_p[0], and_p[0], or_p[0], nor_p[0]}) == 1)
       else $error("%m: exactly one function may be selected\n");

`endif

  
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

`BSG_ABSTRACT_MODULE(bsg_reduce_segmented)
