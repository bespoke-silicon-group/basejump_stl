
`include "bsg_defines.v"

module bsg_tiehi #(parameter `BSG_INV_PARAM(width_p)
                   , parameter harden_p=1
                   )
   (output [width_p-1:0] o
    );

   assign o = { width_p {1'b1} };
   
endmodule

`BSG_ABSTRACT_MODULE(bsg_tiehi)
