
`include "bsg_defines.v"

module bsg_dff #(width_p=-1
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
