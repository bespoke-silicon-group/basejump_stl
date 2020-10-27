// MBT 8-28-14
//
// sequence through all of the tests.
//
// for each test, assert a prepare line for prepare_time_p cycles
// then wait for either 1) all channels to pass that test
//                   or 2) one channel passes and things have stabilized
//                         for timeout_time_p cycles
//
//


`include "bsg_defines.v"

module bsg_source_sync_channel_control_master_master
  #(parameter  link_channels_p  = "inv"
    , parameter tests_p          = "inv"
    , parameter prepare_cycles_p = "inv"
    , parameter timeout_cycles_p = "inv")
  (input clk_i
   , input reset_i
   , input start_i
   , input  [tests_p+1-1:0][link_channels_p-1:0]    test_scoreboard_i
   , output [$clog2(tests_p+1)-1:0] test_index_r_o
   , output prepare_o
   , output done_o
   );

   logic [$clog2(tests_p+1)-1:0] test_index_n, test_index_r;
   logic [tests_p+1-1:0][link_channels_p-1:0] test_scoreboard_r;

   wire prep_done,     timeout_wait_done;
   logic prep_actiwait;

   assign test_index_r_o = test_index_r;
   assign prepare_o      = ~prep_done;

   logic done_r, done_n;

   assign done_o = done_r;

   wire final_test = (test_index_r == tests_p);

   bsg_wait_cycles #(.cycles_p(prepare_cycles_p)) bwc
     (.clk_i       (clk_i)
      ,.reset_i    (reset_i)
      ,.activate_i (prep_actiwait)
      ,.ready_r_o  (prep_done)
      );

   // reactivate the timeout if the channels that pass change
   // this timeout is not really for handling intermittant operation
   // but more to deal with slight amounts of skew between channel
   // wakeup times.
   //
   // note: this means that we could potentially loop indefinitely
   // if things are intermittant; i.e. a channel oscillates between
   // going active and being inactive.
   //
   // fixme: this is okay for FPGA (we can fix the code after the fact)
   // but not for ASIC.
   //

   bsg_wait_cycles #(.cycles_p(timeout_cycles_p)) bwc2
     (.clk_i      (clk_i)
      ,.reset_i   (reset_i)
      ,.activate_i(test_scoreboard_i[test_index_r] != test_scoreboard_r[test_index_r])
      ,.ready_r_o( timeout_wait_done)
      );

   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          test_index_r       <= { ($clog2(tests_p+1)) { 1'b0 } };
        else
          test_index_r       <= test_index_n;

        if (reset_i)
          test_scoreboard_r <= { link_channels_p*(tests_p+1) {  1'b0 } };
        else
          test_scoreboard_r <= test_scoreboard_i;

        if (reset_i)
             done_r     <= 1'b0;
        else
             done_r     <= done_n;
     end

   always_comb
     begin
        done_n     = done_r;
        test_index_n  = test_index_r;
        prep_actiwait = 0;

        if (start_i)
          begin
             done_n          = 1'b0;
             test_index_n    = 0;
             prep_actiwait   = 1'b1;
          end
        else
          if (prep_done & ~done_r) // if we're done preparing for the tests,
            begin                  // or haven't finished them all...
               if ( (& test_scoreboard_r[test_index_r]) // all chanls passed the test
                    | ( (| test_scoreboard_r[test_index_r]) // or if at least one has
                         & timeout_wait_done                // and we have timed out
                         )
                    )
                 begin
                    if (final_test)
                      done_n = 1'b1;
                    else
                      begin
                         // if we've already passed all tests
                         // then go directly to the last test.
			 // "temporary fix" for accelerating simulation 5/1/17 mbt
                         if (&test_scoreboard_r[tests_p-1:0])
                           test_index_n = tests_p;
			 else
                           test_index_n = test_index_r + 1'b1;
                         prep_actiwait = 1'b1;
                      end
                 end
            end
     end // always_comb

endmodule
