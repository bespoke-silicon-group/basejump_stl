
`include "bsg_defines.v"

module bsg_tielo #(parameter width_p="inv"
                 , parameter harden_p=1
                 )
   (output [width_p-1:0] o
    );

   assign o = { width_p {1'b0} };

endmodule
