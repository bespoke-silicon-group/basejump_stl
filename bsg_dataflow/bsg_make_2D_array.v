`include "bsg_defines.v"

module bsg_make_2D_array #(parameter width_p = -1,
                           parameter items_p = -1)
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
