`include "bsg_defines.v"

module bsg_array_reverse 
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(els_p))
  (input    [els_p-1:0][width_p-1:0] i
   , output [els_p-1:0][width_p-1:0] o
  );

  genvar j;
  
  for (j = 0; j < els_p; j=j+1)
    begin: rof
      // els_p = 3    o[2,1,0] = i[0,1,2]
      assign o[els_p-j-1] = i[j]; 
    end
  
endmodule

`BSG_ABSTRACT_MODULE(bsg_array_reverse)

