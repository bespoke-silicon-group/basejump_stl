`include "bsg_defines.v"

module bsg_xor #(parameter width_p="inv"
                 , harden_p=1)
   (input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , output [width_p-1:0] o
    );

   assign o = a_i ^ b_i;

endmodule
