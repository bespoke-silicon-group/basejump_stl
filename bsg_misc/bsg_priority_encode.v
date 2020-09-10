// MBT 5-22-16
//
// Given a bit vector, return binary value
// corresponding to first bit that is set, starting from the low bit.
//
// e.g.   0001 --> 0, v= 1
//        0011 --> 0, v= 1
//        0101 --> 0, v= 1
//        0100 --> 2, v= 1
//        0000 --> 0, v= 0
//
//

`include "bsg_defines.v"

module bsg_priority_encode #(parameter   width_p    = "inv"
                             , parameter lo_to_hi_p = "inv"
                             )

   (input    [width_p-1:0] i
    , output [`BSG_SAFE_CLOG2(width_p)-1:0] addr_o
    , output v_o
    );

   logic [width_p-1:0] enc_lo;

   // We use this v_o instead of the v_o of bsg_encode_one_hot
   //   because it has better critical path
   bsg_priority_encode_one_hot_out #(.width_p(width_p)
                                     ,.lo_to_hi_p(lo_to_hi_p)
                                     ) a
     (.i(i)
      ,.o(enc_lo)
      ,.v_o(v_o)
      );

   bsg_encode_one_hot #(.width_p(width_p)
                        ,.lo_to_hi_p(lo_to_hi_p)
                        ) b
     (.i      (enc_lo)
      ,.addr_o(addr_o)
      ,.v_o   ()
      );

endmodule
