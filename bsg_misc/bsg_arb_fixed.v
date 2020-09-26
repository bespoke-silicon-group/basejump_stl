// MBT 5-22-2016
// fixed priority arbitration unit
//
//

`include "bsg_defines.v"

module bsg_arb_fixed #(parameter     inputs_p = "inv"
                       , parameter lo_to_hi_p = "inv")
   ( input ready_i
     , input  [inputs_p-1:0] reqs_i
     , output [inputs_p-1:0] grants_o
     );

   logic [inputs_p-1:0] grants_unmasked_lo;

   bsg_priority_encode_one_hot_out #(.width_p    (inputs_p)
                                     ,.lo_to_hi_p(lo_to_hi_p)
                                     ) enc
     (.i ( reqs_i            )
      ,.o( grants_unmasked_lo)
      ,.v_o(                 )
      );

   // mask with ready bits
   assign grants_o = grants_unmasked_lo & { (inputs_p) { ready_i } };

endmodule
