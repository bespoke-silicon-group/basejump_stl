`include "bsg_defines.v"

module bsg_nor3 #(parameter `BSG_INV_PARAM(width_p)
                 , harden_p=1)
   (input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , input [width_p-1:0] c_i
    , output [width_p-1:0] o
    );

   assign o = ~(a_i | b_i | c_i);

endmodule

`BSG_ABSTRACT_MODULE(bsg_nor3)
