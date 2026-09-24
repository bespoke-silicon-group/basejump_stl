// bsg_nonsynth_clk_watcher
//
// monitors the edges of a clock
// and tells you if it changed and
// what the lengths of each phase are
//

`include "bsg_defines.sv"

module bsg_nonsynth_clk_watcher #(tolerance_p=0)
  (input clk_i);

   longint                    my_ticks_posedge = 0;
   longint                    my_ticks_negedge = 0;
   longint                    last_posedge = -1;
   longint                    last_negedge = -1;
   longint                    cycles_posedge = -1;
   longint                    cycles_negedge = -1;
   longint                    pos_temp_time, neg_temp_time;

   always_ff @(posedge clk_i)
     begin
        pos_temp_time = $time;

        if ((pos_temp_time-my_ticks_negedge > last_posedge+tolerance_p)
            || (pos_temp_time-my_ticks_negedge < last_posedge-tolerance_p))
          begin
             if (cycles_posedge > 0)
               $write("## clock_watcher [%t] {                                                                                POSEDGE offset (after %-8d cycles) %-7d ps (n/p phase ratio=%2.3f)} (%m)\n"
                      ,$time, cycles_posedge, $time-my_ticks_negedge, ( real ' (last_negedge))/(real ' ($time-my_ticks_negedge)));
             cycles_posedge <= 0;
             last_posedge <= $time-my_ticks_negedge;
          end
        else
          cycles_posedge <= cycles_posedge+1;

        my_ticks_posedge = $time;

     end // always @ (posedge clk_i)

   always_ff @(negedge clk_i)
     begin
        neg_temp_time = $time;
        if ((neg_temp_time-my_ticks_posedge > last_negedge+tolerance_p)
            || (neg_temp_time-my_ticks_posedge < last_negedge-tolerance_p))
          begin
             if (cycles_negedge > 0)
               $write("## clock_watcher [%t] { NEGEDGE offset (after %-7d cycles) %-7d ps (p/n phase ratio=%2.3f)} (%m)\n"
                      ,$time, cycles_negedge, $time-my_ticks_posedge, ( real ' (last_posedge))/(real ' ($time-my_ticks_posedge)));
             cycles_negedge <= 0;
             last_negedge <= $time-my_ticks_posedge;
          end
        else
          cycles_negedge <= cycles_negedge+1;

        my_ticks_negedge = $time;
     end
endmodule
