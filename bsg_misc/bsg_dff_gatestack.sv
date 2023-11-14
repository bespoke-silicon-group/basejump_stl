`include "bsg_defines.sv"

module bsg_dff_gatestack #(`BSG_INV_PARAM(width_p), harden_p=1)
   (input [width_p-1:0] i0
    , input [width_p-1:0] i1
    , output logic [width_p-1:0] o
    );

   genvar j;

   for (j = 0; j < width_p; j=j+1)
     begin
        always_ff @(posedge i1[j])
          o[j] <= i0[j];
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_dff_gatestack)
