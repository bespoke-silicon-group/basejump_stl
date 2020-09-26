//This module buff 1 bit control signal to width_p vector
`include "bsg_defines.v"

module bsg_buf_ctrl #(parameter width_p="inv"
                 , harden_p=1)
   (input i
  , output [width_p-1:0] o
  );

   assign o = { width_p{i}};

endmodule
