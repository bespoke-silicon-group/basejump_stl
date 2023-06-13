
`include "bsg_defines.sv"

module bsg_tielo #(parameter `BSG_INV_PARAM(width_p)
                 , parameter harden_p=1
                 )
   (output [width_p-1:0] o
    );

   assign o = { width_p {1'b0} };

endmodule

`BSG_ABSTRACT_MODULE(bsg_tielo)
