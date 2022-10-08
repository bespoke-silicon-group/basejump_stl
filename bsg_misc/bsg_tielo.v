
`include "bsg_defines.v"

module bsg_tielo #(parameter `BSG_INV_PARAM(width_p)
                 )
   (output [width_p-1:0] o
    );

   assign o = { width_p {1'b0} };

endmodule

`BSG_ABSTRACT_MODULE(bsg_tielo)
