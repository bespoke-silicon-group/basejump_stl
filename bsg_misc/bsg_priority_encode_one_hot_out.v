// MBT 5-22-16
//
// Given a bit vector, return a one-hot bit vector
// that has the latest/earliest bit selected.
//
// Can combine with bsg_encode_one_hot
// to get typical priority encoder.
//

`include "bsg_defines.v"

module bsg_priority_encode_one_hot_out #(parameter width_p      = "inv"
                                         , parameter lo_to_hi_p = "inv"
                                         )

   (input    [width_p-1:0] i
    , output [width_p-1:0] o
    , output               v_o
    );

   logic [width_p-1:0] scan_lo;

   if (width_p == 1)
     begin: w1
      assign o = i;
      assign v_o = i;
     end
   else
     begin: nw1
       bsg_scan #(.width_p(width_p)
                  ,.or_p      (1)
                  ,.lo_to_hi_p(lo_to_hi_p)
                  ) scan (.i (i)
                          ,.o(scan_lo)
                          );

       // edge detect
       if (lo_to_hi_p)
         begin : fi1
           assign o = scan_lo & { (~scan_lo[width_p-2:0]), 1'b1 };
           assign v_o = scan_lo[width_p-1];
         end
       else
         begin : fi1
           assign o = scan_lo & { 1'b1, (~scan_lo[width_p-1:1]) };
           assign v_o = scan_lo[0];
         end
     end
endmodule
