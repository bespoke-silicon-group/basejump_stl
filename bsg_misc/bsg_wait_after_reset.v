// MBT 7-28-14
//
// Wait a certain number of cycles after reset to begin
//
//
//

`include "bsg_defines.v"

module bsg_wait_after_reset  #(parameter lg_wait_cycles_p="inv")
   (input reset_i
    , input clk_i
    , output reg ready_r_o);

   logic [lg_wait_cycles_p-1:0] counter_r;

   always @(posedge clk_i)
     begin
        if (reset_i)
          begin
             counter_r <= 1;
             ready_r_o <= 0;
          end
        else
          if (counter_r == 0)
            ready_r_o <= 1;
          else
            counter_r <= counter_r + 1;
     end
endmodule
