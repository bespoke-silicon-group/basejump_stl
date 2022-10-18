
`include "bsg_defines.v"

`define bsg_nand_macro(bits)                      \
if (harden_p && (width_p==bits))                  \
  begin: macro                                    \
    for (genvar j = 0; j < width_p; j++)          \
      begin : x                                   \
        ND2D4BWP7T40P140 x (.A1(a_i[j]), .A2(b_i[j]), .ZN(o[j])); \
      end                                                     \
  end

module bsg_nand #(parameter `BSG_INV_PARAM(width_p)
                 , parameter harden_p=0
                 )
   (input    [width_p-1:0] a_i
    , input  [width_p-1:0] b_i
    , output [width_p-1:0] o
    );

   `bsg_nand_macro(34) else
   `bsg_nand_macro(33) else
   `bsg_nand_macro(32) else
   `bsg_nand_macro(31) else
   `bsg_nand_macro(30) else
   `bsg_nand_macro(29) else
   `bsg_nand_macro(28) else
   `bsg_nand_macro(27) else
   `bsg_nand_macro(26) else
   `bsg_nand_macro(25) else
   `bsg_nand_macro(24) else
   `bsg_nand_macro(23) else
   `bsg_nand_macro(22) else
   `bsg_nand_macro(21) else
   `bsg_nand_macro(20) else
   `bsg_nand_macro(19) else
   `bsg_nand_macro(18) else
   `bsg_nand_macro(17) else
   `bsg_nand_macro(16) else
   `bsg_nand_macro(15) else
   `bsg_nand_macro(14) else
   `bsg_nand_macro(13) else
   `bsg_nand_macro(12) else
   `bsg_nand_macro(11) else
   `bsg_nand_macro(10) else
   `bsg_nand_macro(9) else
   `bsg_nand_macro(8) else
   `bsg_nand_macro(7) else
   `bsg_nand_macro(6) else
   `bsg_nand_macro(5) else
   `bsg_nand_macro(4) else
   `bsg_nand_macro(3) else
   `bsg_nand_macro(2) else
   `bsg_nand_macro(1) else
       begin :notmacro
          initial assert(harden_p==0) else $error("## %m wanted to harden but no macro");

          assign o = ~(a_i & b_i);
      end
endmodule

`BSG_ABSTRACT_MODULE(bsg_nand)
