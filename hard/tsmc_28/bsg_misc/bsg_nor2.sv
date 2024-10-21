
`include "bsg_defines.sv"

`define bsg_nor2_macro(bits)                      \
if (harden_p && (width_p==bits))                  \
  begin: macro                                    \
    for (genvar j = 0; j < width_p; j++)          \
      begin : x                                   \
        NR2D4BWP7T40P140 x_BSG_RESIZE_OK (.A1(a_i[j]), .A2(b_i[j]), .ZN(o[j])); \
      end                                                     \
  end

module bsg_nor2 #(parameter `BSG_INV_PARAM(width_p)
                 , parameter harden_p=0
                 )
   (input    [width_p-1:0] a_i
    , input  [width_p-1:0] b_i
    , output [width_p-1:0] o
    );

   `bsg_nor2_macro(34) else
   `bsg_nor2_macro(33) else
   `bsg_nor2_macro(32) else
   `bsg_nor2_macro(31) else
   `bsg_nor2_macro(30) else
   `bsg_nor2_macro(29) else
   `bsg_nor2_macro(28) else
   `bsg_nor2_macro(27) else
   `bsg_nor2_macro(26) else
   `bsg_nor2_macro(25) else
   `bsg_nor2_macro(24) else
   `bsg_nor2_macro(23) else
   `bsg_nor2_macro(22) else
   `bsg_nor2_macro(21) else
   `bsg_nor2_macro(20) else
   `bsg_nor2_macro(19) else
   `bsg_nor2_macro(18) else
   `bsg_nor2_macro(17) else
   `bsg_nor2_macro(16) else
   `bsg_nor2_macro(15) else
   `bsg_nor2_macro(14) else
   `bsg_nor2_macro(13) else
   `bsg_nor2_macro(12) else
   `bsg_nor2_macro(11) else
   `bsg_nor2_macro(10) else
   `bsg_nor2_macro(9) else
   `bsg_nor2_macro(8) else
   `bsg_nor2_macro(7) else
   `bsg_nor2_macro(6) else
   `bsg_nor2_macro(5) else
   `bsg_nor2_macro(4) else
   `bsg_nor2_macro(3) else
   `bsg_nor2_macro(2) else
   `bsg_nor2_macro(1) else
       begin :notmacro
          // synopsys translate_off
          initial assert(harden_p==0) else $error("## %m wanted to harden but no macro");
          // synopsys translate_on

          assign o = ~(a_i | b_i);
      end
endmodule

`BSG_ABSTRACT_MODULE(bsg_nor2)
