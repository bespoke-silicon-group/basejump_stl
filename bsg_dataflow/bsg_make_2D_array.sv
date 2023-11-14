`include "bsg_defines.sv"

module bsg_make_2D_array #(parameter `BSG_INV_PARAM(width_p ),
                           parameter `BSG_INV_PARAM(items_p ))
   (
    input [width_p*items_p-1:0] i
    , output [width_p-1:0] o [items_p-1:0]
    );

   genvar j;

   for (j = 0; j < items_p; j=j+1)
     begin
        assign o[j] = i[j*width_p+:width_p];
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_make_2D_array)
