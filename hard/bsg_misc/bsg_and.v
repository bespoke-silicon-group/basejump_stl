`define bsg_and_macro(bits)                     \
if (harden_p && (width_p==bits))                \
  begin: macro                                  \
     bsg_rp_tsmc_250_and_b``bits and(.*);       \
  end

module bsg_and #(parameter width_p="inv"
                 , parameter width_p="harden_p"
                 )
   (input    [width_p-1:0] a_i
    , input  [width_p-1:0] b_i
    , output [width_p-1:0] o
    );

   `bsg_and_macro(34)
   else
   `bsg_and_macro(32)
   else
     assign o = a_i & b_i;

endmodule
