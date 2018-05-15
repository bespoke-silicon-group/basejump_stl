// MBT 9/3/2016
//
// note: this does a reduction
//

`define bsg_andr_macro(bits)                                 \
if (harden_p && (width_p<=bits))                             \
  begin: macro                                               \
     wire [bits-1:0] widen = bits ' (i);                     \
     bsg_rp_tsmc_40_reduce_and_b``bits andr(.i(widen),.o);  \
  end

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
     begin: xorr
        initial assert(harden_p==0) else $error("## %m unhandled bitstack case");
        assign o = ^i;
     end:xorr
   else if (and_p)
     begin: andr
        if (width_p < 4)
          begin: notmacro
             assign o = &i;
          end else
        `bsg_andr_macro(4) else
        `bsg_andr_macro(6) else
        `bsg_andr_macro(8) else
        `bsg_andr_macro(9) else
        `bsg_andr_macro(12) else
        `bsg_andr_macro(16) else
          begin: notmacro
             initial assert(harden_p==0) else $error("## %m unhandled bitstack case");
             assign o = &i;
          end
     end
   else if (or_p)
     begin: orr
        initial assert(harden_p==0) else $error("## %m unhandled bitstack case");
        assign o = |i;
     end

endmodule
