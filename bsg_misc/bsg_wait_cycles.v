`include "bsg_defines.v"

module bsg_wait_cycles #(parameter cycles_p="inv")
   (
    input clk_i
    , input reset_i
    , input activate_i
    , output reg ready_r_o
    );

   logic [$clog2(cycles_p+1)-1:0] ctr_r, ctr_n;

   always_ff @(posedge clk_i)
     begin
        ctr_r     <= ctr_n;
        ready_r_o <= (ctr_n == cycles_p);
     end

   always_comb
     begin
        ctr_n = ctr_r;

        if (reset_i)
          ctr_n = cycles_p;
        else
          if (activate_i)
            ctr_n = 0;
          else
            if (ctr_r != cycles_p)
              ctr_n = ctr_r + 1'b1;
     end

endmodule
