`include "bsg_defines.sv"

module bsg_mux2_gatestack #(parameter `BSG_INV_PARAM(width_p), harden_p=1)
   (input [width_p-1:0] i0
    , input [width_p-1:0] i1
    , input [width_p-1:0] i2
    , output [width_p-1:0] o
    );

   genvar j;

   for (j = 0; j < width_p; j=j+1)
     begin
	assign o[j] = i2[j] ? i1[j] : i0[j];
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mux2_gatestack)
