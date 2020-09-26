// bsg_nonsynth_clk_watcher
//
// monitors the edges of a clock
// and tells you if it changed and
// what the lengths of each phase are
//

`include "bsg_defines.v"

module bsg_nonsynth_clk_watcher #(tolerance_p=0)
  (input clk_i);

   longint                    my_ticks_posedge = 0;
   longint                    my_ticks_negedge = 0;
   longint                    last_posedge = -1;
   longint                    last_negedge = -1;
   longint                    cycles_posedge = -1;
   longint                    cycles_negedge = -1;
   longint                    temp_time;

   always @(posedge clk_i)
     begin
        temp_time = $time;

        if ((temp_time-my_ticks_negedge > last_posedge+tolerance_p)
            || (temp_time-my_ticks_negedge < last_posedge-tolerance_p))
          begin
             if (cycles_posedge != -1)
               $write("## clock_watcher {                                                                                POSEDGE offset (after %-8d cycles) %-7d ps (n/p phase ratio=%2.3f)} (%m)\n"
                      ,cycles_posedge, $time-my_ticks_negedge, ( real ' (last_negedge))/(real ' ($time-my_ticks_negedge)));
             cycles_posedge = 0;
             last_posedge = $time-my_ticks_negedge;
          end
        else
          cycles_posedge = cycles_posedge+1;

        my_ticks_posedge = $time;

     end // always @ (posedge clk_i)

   always @(negedge clk_i)
     begin
        temp_time = $time;
        if ((temp_time-my_ticks_posedge > last_negedge+tolerance_p)
            || (temp_time-my_ticks_posedge < last_negedge-tolerance_p))
          begin
             if (cycles_negedge != -1)
               $write("## clock_watcher { NEGEDGE offset (after %-7d cycles) %-7d ps (p/n phase ratio=%2.3f)} (%m)\n"
                      ,cycles_negedge, $time-my_ticks_posedge, ( real ' (last_posedge))/(real ' ($time-my_ticks_posedge)));
             cycles_negedge = 0;
             last_negedge = $time-my_ticks_posedge;
          end
        else
          cycles_negedge = cycles_negedge+1;

        my_ticks_negedge = $time;
     end
endmodule
