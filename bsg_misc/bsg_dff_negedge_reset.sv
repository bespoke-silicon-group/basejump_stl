`include "bsg_defines.sv"

module bsg_dff_negedge_reset #(`BSG_INV_PARAM(width_p), harden_p=0)
   (input   clk_i
   ,input  reset_i
    ,input  [width_p-1:0] data_i
    ,output [width_p-1:0] data_o
    );

   reg [width_p-1:0] data_r;

   assign data_o = data_r;

   always @(negedge clk_i)
     begin
        if (reset_i)
          data_r <= width_p'(0);
        else
          data_r <= data_i;
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_dff_negedge_reset)
