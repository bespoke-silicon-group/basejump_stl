
`include "bsg_defines.v"

module bsg_tiehi #(parameter width_p="inv"
                   , parameter harden_p=1
                   )
   (output [width_p-1:0] o
    );

   assign o = { width_p {1'b1} };
   
endmodule
