
`include "bsg_defines.sv"

module bsg_dff #(parameter `BSG_INV_PARAM(width_p)
		 ,harden_p=0
		 ,strength_p=1   // set drive strength
		 )
   (input   clk_i
    ,input  [width_p-1:0] data_i
    ,output [width_p-1:0] data_o
    );

   reg [width_p-1:0] data_r;

   assign data_o = data_r;

   always @(posedge clk_i)
     data_r <= data_i;

endmodule

`BSG_ABSTRACT_MODULE(bsg_dff)
