`include "bsg_defines.v"

module bsg_nonsynth_val_watcher_1p #(string_p = "unknown", trigger_val_p = -1, val_size_p = 32, one_time_trigger_p = 1'b1, p1_width_p=32, extra_p = 1)
   (input clk_i
    , input reset_i
    , input [val_size_p-1:0] val_i
    , input [p1_width_p-1:0] p1_i
    );

   logic triggered_r, triggered_n;

   always_ff @(posedge clk_i)
     begin
        if (triggered_n)
          begin
             if (extra_p)
               $display("// %m: %s %x.\n", string_p, p1_i);
             else
               $display("// %m: %s.\n", string_p);
          end

        if (reset_i)
          triggered_r <= 0;
        else
          triggered_r <= triggered_r | triggered_n;
     end

   assign triggered_n = (val_i == trigger_val_p) & (~triggered_r | ~one_time_trigger_p);

endmodule

