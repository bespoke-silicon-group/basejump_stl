// bsg_transpose_reduce
//
// transpose a 2D array and reduce it 
// using Verilog reduction operators
//
// Example:

// els_p = 3, width_p = 4, or_p = 1
//
// { {1 0 1 0 },
//   {0 0 1 0 },
//   {1 0 0 1 } }
//
// --->
//
// { 1 0 1 1 }
//

`include "bsg_defines.sv"

module bsg_transpose_reduce #(`BSG_INV_PARAM(els_p)
                              ,`BSG_INV_PARAM(width_p)
                              , xor_p = 0
                              , and_p = 0
                              , or_p  = 0
                             )
  (input [els_p-1:0][width_p-1:0] i
   , output [width_p-1:0] o
  );

  wire [width_p-1:0][els_p-1:0] lo;
  
  bsg_transpose #(.els_p  (els_p)
                 ,.width_p(width_p)
                 ) xpose
  (.i(i)
   ,.o(lo)
  );
  
  for (genvar j = 0; j < width_p; j++)
    begin: rof
      // one day we will have an enum =)
      bsg_reduce #(.width_p(els_p)
                   ,.xor_p (xor_p)
                   ,.and_p (and_p)
                   ,.or_p  (or_p)
                  ) red
      (.i(lo[j])
       ,.o(o[j])
      );
    end	

endmodule

`BSG_ABSTRACT_MODULE(bsg_transpose_reduce)
  
