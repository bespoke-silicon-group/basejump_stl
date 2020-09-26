// MBT 8/4/2014
//

`include "bsg_defines.v"

module bsg_cycle_counter #(parameter width_p=32
                           , init_val_p = 0)
   (input clk_i
    , input reset_i
    , output logic [width_p-1:0] ctr_r_o);

   always @(posedge clk_i)
     if (reset_i)
       ctr_r_o <= init_val_p;
     else
       ctr_r_o <= ctr_r_o+1;

endmodule // bsg_cycle_counter
