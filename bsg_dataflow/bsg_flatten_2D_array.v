`include "bsg_defines.v"

module bsg_flatten_2D_array #(parameter `BSG_INV_PARAM(  width_p )
                              , parameter `BSG_INV_PARAM(items_p ))
   (input [width_p-1:0]            i [items_p-1:0]
    , output [width_p*items_p-1:0] o
    );

   genvar j;

   for (j = 0; j < items_p; j=j+1)
     begin
        assign o[j*width_p+:width_p] = i[j];
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_flatten_2D_array)
