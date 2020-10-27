
// FIXME: untested
//

`include "bsg_defines.v"

module bsg_permute_box #(parameter width_p="inv"
			 , parameter items_p="inv"
			 , parameter lg_items_lp=$bits(items_p))
   (input    [width_p-1:0]     data_i   [items_p-1:0]
    , input  [lg_items_lp-1:0] select_i [items_p-1:0]
    , output [width_p-1:0]     data_o   [items_p-1:0]
    );


   genvar i;

   for (i = 0; i < items_p; i = i + 1)
     assign data_o[i] = data_i[select_i[i]];

endmodule
