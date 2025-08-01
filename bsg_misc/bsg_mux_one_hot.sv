
`include "bsg_defines.sv"

module bsg_mux_one_hot #(parameter `BSG_INV_PARAM(width_p)
                         , int els_p=1
			 , harden_p=1
                         )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [els_p-1:0] sel_one_hot_i
    ,output [width_p-1:0] data_o
    );

   wire [els_p-1:0][width_p-1:0]   data_masked;

   genvar                          i,j;

   for (i = 0; i < els_p; i++)
     begin : mask
        assign data_masked[i] = data_i[i] & { width_p { sel_one_hot_i[i] } };
     end

   for (i = 0; i < width_p; i++)
     begin: reduce
        wire [els_p-1:0] gather;

        for (j = 0; j < els_p; j++)
          begin : reduce2
            assign gather[j] = data_masked[j][i];
          end

        assign data_o[i] = | gather;
     end

   if (els_p == 0)
     begin : zero
        assign data_o = '0;
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mux_one_hot)
