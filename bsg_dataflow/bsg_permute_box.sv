
// FIXME: untested
//

`include "bsg_defines.sv"

module bsg_permute_box #(parameter `BSG_INV_PARAM(width_p)
			 , parameter `BSG_INV_PARAM(items_p)
			 , parameter lg_items_lp=$bits(items_p))
   (input    [width_p-1:0]     data_i   [items_p-1:0]
    , input  [lg_items_lp-1:0] select_i [items_p-1:0]
    , output [width_p-1:0]     data_o   [items_p-1:0]
    );


   genvar i;

   for (i = 0; i < items_p; i = i + 1)
     assign data_o[i] = data_i[select_i[i]];

endmodule

`BSG_ABSTRACT_MODULE(bsg_permute_box)
