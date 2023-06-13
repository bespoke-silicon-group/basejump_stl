`include "bsg_defines.sv"

module bsg_nand #(parameter `BSG_INV_PARAM(width_p)
                 , harden_p=1)
   (input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , output [width_p-1:0] o
    );

   assign o = ~(a_i & b_i);

endmodule

`BSG_ABSTRACT_MODULE(bsg_nand)
