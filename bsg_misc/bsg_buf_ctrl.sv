//This module buff 1 bit control signal to width_p vector
`include "bsg_defines.sv"

module bsg_buf_ctrl #(parameter `BSG_INV_PARAM(width_p)
                 , harden_p=1)
   (input i
  , output [width_p-1:0] o
  );

   assign o = { width_p{i}};

endmodule

`BSG_ABSTRACT_MODULE(bsg_buf_ctrl)
