
`include "bsg_defines.sv"

`define bsg_and_macro(bits)                      \
if (harden_p && width_p == bits)                  \
  begin: macro                                    \
    for (genvar j = 0; j < width_p; j++)          \
      begin : x                                   \
        AN2D4BWP7T40P140 x_BSG_RESIZE_OK (.A1(a_i[j]), .A2(b_i[j]), .Z(o[j])); \
      end                                                     \
  end

module bsg_and #(parameter `BSG_INV_PARAM(width_p)
                 , parameter harden_p=0
                 )
   (input    [width_p-1:0] a_i
    , input  [width_p-1:0] b_i
    , output [width_p-1:0] o
    );

   `bsg_and_macro(34) else
   `bsg_and_macro(33) else
   `bsg_and_macro(32) else
   `bsg_and_macro(31) else
   `bsg_and_macro(30) else
   `bsg_and_macro(29) else
   `bsg_and_macro(28) else
   `bsg_and_macro(27) else
   `bsg_and_macro(26) else
   `bsg_and_macro(25) else
   `bsg_and_macro(24) else
   `bsg_and_macro(23) else
   `bsg_and_macro(22) else
   `bsg_and_macro(21) else
   `bsg_and_macro(20) else
   `bsg_and_macro(19) else
   `bsg_and_macro(18) else
   `bsg_and_macro(17) else
   `bsg_and_macro(16) else
   `bsg_and_macro(15) else
   `bsg_and_macro(14) else
   `bsg_and_macro(13) else
   `bsg_and_macro(12) else
   `bsg_and_macro(11) else
   `bsg_and_macro(10) else
   `bsg_and_macro(9) else
   `bsg_and_macro(8) else
   `bsg_and_macro(7) else
   `bsg_and_macro(6) else
   `bsg_and_macro(5) else
   `bsg_and_macro(4) else
   `bsg_and_macro(3) else
   `bsg_and_macro(2) else
   `bsg_and_macro(1) else
       begin :notmacro
          `BSG_SYNTH_HARDEN_ATTEMPT(harden_p)

          assign o = a_i & b_i;
      end
endmodule

`BSG_ABSTRACT_MODULE(bsg_and)
