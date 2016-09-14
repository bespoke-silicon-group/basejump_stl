// MBT 9/3/2016
//
// note: this does a reduction
//

module bsg_reduce #(parameter width_p = -1
                  , parameter xor_p = 0
                  , parameter and_p = 0
                  , parameter or_p = 0
                  , parameter harden_p = 0
                  )
   (input    [width_p-1:0] i
    , output o
    );

   // synopsys translate_off
   initial
      assert( $countones({xor_p & 1'b1, and_p & 1'b1, or_p & 1'b1}) == 1)
        else $error("bsg_scan: only one function may be selected\n");
   // synopsys translate_on

   if (xor_p)
     assign o = ^i;
   else if (and_p)
     assign o = &i;
   else if (or_p)
     assign o = |i;

endmodule
