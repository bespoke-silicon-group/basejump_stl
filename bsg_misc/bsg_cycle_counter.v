// MBT 8/4/2014
//

module bsg_cycle_counter #(parameter width_p=32)
   (input clk
    , input reset_i
    , output logic [width_p-1:0] ctr_r_o);

   always @(posedge clk)
     if (reset_i)
       ctr_r_o <= 0;
     else
       ctr_r_o <= ctr_r_o+1;

endmodule // bsg_cycle_counter


