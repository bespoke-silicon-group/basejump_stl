// MBT 5-1-2017
//
// fast version of the gateway reset sequence
//
// this version assumes that all channels work
// and is just for gatelevel simulation.
//


`include "bsg_defines.v"

module bsg_source_sync_channel_control_master_master
  #(parameter  link_channels_p  = "inv"
    , parameter tests_p          = "inv"
    , parameter prepare_cycles_p = "inv"   // ignored
    , parameter timeout_cycles_p = "inv")  // ignored
  (input clk_i   // from io_master_clk_i
   , input reset_i // from im_reset_i

   // we should begin the calibration stuff

   , input start_i

   // from masters, signals that that channel thinks it is done with the test

   , input  [tests_p+1-1:0][link_channels_p-1:0]    test_scoreboard_i
   , output [$clog2(tests_p+1)-1:0] test_index_r_o

   // simultaneously a reset signal and a signal to the masters

   , output prepare_o
   , output done_o        // we are done with all of this calibration stuff.
   );

   logic done_r, done_n;

   logic [$clog2(tests_p+1)-1:0] test_index_n, test_index_r;
   assign test_index_r_o = test_index_r;

   logic                         started_r;

   always_ff @(posedge clk_i)
     if (reset_i)
       started_r <= 0;
     else
       started_r <= started_r | start_i;

   // we assert reset on states that end in 0

   assign prepare_o = ~(test_index_r[0]) & started_r & ~done_r;

   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          test_index_r <= 0;
        else
          test_index_r <= test_index_n;
     end

   assign done_o =  done_r;

   always @(posedge clk_i)
     if (reset_i)
       done_r <= 0;
     else
       done_r <= done_n;

   always_comb
     begin
        done_n = done_r;
        if (&test_scoreboard_i[tests_p])
          done_n = 1'b1;
     end

   // move to the next test if everybody is happy

   always_comb
     begin
        test_index_n = test_index_r;

        if (!done_r & started_r & (&test_scoreboard_i[test_index_r]))
          test_index_n = test_index_r+1;
     end


endmodule
