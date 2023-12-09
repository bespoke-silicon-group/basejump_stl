`include "bsg_defines.sv"

module bsg_buf #(parameter `BSG_INV_PARAM(width_p)
                 , harden_p=1)
   (input [width_p-1:0] i
    , output [width_p-1:0] o
    );

   assign o = i;

endmodule

`BSG_ABSTRACT_MODULE(bsg_buf)
