// MBT 8/27/14
//
// FPGA calibration module (example, only implements Phase 1 and dummy Phase 0,2,3)
//
// See BSG Source Synchronous I/O for specification of this.
//
// everything beginning with "out" is the output channel clock
// everything beginning with "in"  is the input  channel clock
//
// respect the clock domains!
//
// tests_lp defines the number of real tests; but we have one more "fake"
// test at the end, which causes activation or deactivation of the channel
//
//

module  bsg_source_sync_channel_control_master #(parameter   width_p  = -1
                                                 , parameter lg_token_width_p = 6
                                                 , parameter lg_out_prepare_hold_cycles_p = 6
                                                 // bit vector
                                                 , parameter bypass_test_p = 5'b0
                                                 , parameter words_per_cal_round_p = 16
                                                 , parameter tests_lp = 5
                                                 , parameter verbose_lp = 1
                                                 )
   (// output channel
    input  out_clk_i
    , input  out_reset_i // note this is just a synchronized version of core_reset

    // we can do calibration in parallel, or channel-by-channel
    , input [$clog2(tests_lp+1)-1:0]  out_calibration_state_i

    // whether we are in the "prepare" part of the state, or the "go" part
    // the prepare corresponds to reset being asserted to the slave device

    , input                      out_calib_prepare_i

    // this is for the final test, and means that the channel is "blessed"
    // i.e. ready to use

    , input                      out_channel_blessed_i

    // this is used to force data on to the output channel
    // (calibration modes 0 and 1)
    , output                 out_override_en_o
    , output [width_p+1-1:0] out_override_valid_data_o
    , input                  out_override_is_posedge_i

    // whether the test passed
    , output [tests_lp+1-1:0] out_test_pass_r_o

    // read the input channel
    , input  in_clk_i      // for sampling the data below
    , input  in_reset_i    // just a synchronized version of core_reset

    // negative edge snoop (precedes positive edge in time)
    , input  [width_p+1-1:0] in_snoop_valid_data_neg_i

    // positive edge snoop
    , input  [width_p+1-1:0] in_snoop_valid_data_pos_i

    // basically disable the output module from looking
    // at the credit counters
    , output                 in_infinite_credits_o

    // This signal is routed out to the testbench in order
    // to test the bit slip functionality of the phase1 checker
    // module
    , output logic [width_p-1:0] bit_slip_vector_to_tb_o
    );

   // 24 is 16M cycles
   localparam counter_min_bits_lp = 24;
   localparam     counter_bits_lp = $max(counter_min_bits_lp,(width_p+1)*2+1);

   logic [counter_bits_lp-1:0] out_ctr_r,   out_ctr_n;
   logic [width_p+1-1:0]       out_override_valid_data_r, out_override_valid_data_n;
   logic                       out_override_en_r,         out_override_en_n;

   logic out_calib_prepare_i_r;

   logic [tests_lp+1-1:0] out_test_pass_r, out_test_pass_n;

   // fill pattern with at least as many 10's to fill width_p bits
   // having defaults be 10101 reduces electromigration on pads
   wire [(((width_p+1)>>1)<<1)-1:0] inactive_pattern
                                    = { ((width_p+1) >> 1) { (2'b01) } };

   // we don't strictly need to register this
   // as it is registered in the source synchronous output module
   // however, this is a non-latency critical path it seems reasonable
   // to add an extra flop.

   assign out_override_valid_data_o = out_override_valid_data_r;
   assign out_override_en_o         = out_override_en_r;

   assign out_test_pass_r_o           = out_test_pass_r[tests_lp:0];

   logic [4:0] out_calib_code;

   logic        out_activating;

   // these codes have been chosen very exhaustively
   // with consideration to stuck-at faults.
   // please do not change them -- mbt
   // note; when width_p=3, then only even numbered
   // codes will run on the slave device
   always_comb
     begin
        out_activating = 1'b0;

        unique case (out_calibration_state_i)
          0: out_calib_code = 5'b0_111_1; // reset clk

          // phase 1 and 2 are "noisy"
          // so keep hamming distance from sActive high

          1: out_calib_code = 5'b0_010_0; // Phase 1
          2: out_calib_code = 5'b0_010_1; // Phase 2
          3: out_calib_code = 5'b0_001_0; // Phase 3
          4: out_calib_code = 5'b0_001_1; // Phase 4

          tests_lp:
            begin
               out_calib_code = out_channel_blessed_i
                              ? (5'b0_011_0)    // corresponds to channel activated
                                                // --> do prepare part of this state
                              : (5'b0_100_1);   // channel NOT activated (also 0_011_1)
                                                // this pattern should be maximally
                                                // different from active pattern so
                                                // that stuck-at faults do not cause
                                                // accidental activation after the final
                                                // reset.
               out_activating = out_channel_blessed_i;
            end
          default: out_calib_code = 5'b0_000_1; // includes sInactive
        endcase
     end // always_comb

   wire [width_p+1-1:0] out_calib_code_padded;

   if (width_p <= 4)
     assign out_calib_code_padded = out_calib_code[($bits(out_calib_code)-1)-:(1+width_p)];
   else
     // we invert the extra bits if we are activating
     assign out_calib_code_padded
       = { out_calib_code
           , inactive_pattern[width_p+1-$bits(out_calib_code)-1:0]
              ^ { (width_p+1-$bits(out_calib_code)) { out_activating } }
           };

   logic out_finish_prepare_r, out_finish_prepare_n;

   /*************************************************************************
   /*
   /* Phase 3 and Phase 4 Logic
   /*
   /*************************************************************************/
   typedef enum {
                 sIdle, sDone, sError
                 , sPhase3Trigger, sPhase3Delay1, sPhase3Delay2, sPhase3Delay3, sPhase3Send, sPhase3Recv, sPhase3Delay4
                 , sPhase4Trigger, sPhase4Delay1, sPhase4Delay2, sPhase4Delay3, sPhase4Send, sPhase4Recv, sPhase4Delay4
                } trigger_mode_state;

   trigger_mode_state tm_state_n, tm_state_r;
   logic [4:0] tm_counter_r, tm_counter_n;
   logic fs_pattern_gen_en;
   logic [width_p-1:0] pattern_o;
   logic checker_success, checker_timed_out;
   logic trigger_n, trigger_r;
   logic in_all_packets_received, out_all_packets_received;

   always_ff @(posedge out_clk_i) begin:trigger_mode_output_counter
       if (out_reset_i) tm_counter_r <= 0;
       else tm_counter_r <= tm_counter_n;
   end:trigger_mode_output_counter

   fs_pattern_gen #(.width_p(width_p), .counter_bits_p(counter_bits_lp))
      fspg (.clk(out_clk_i)
           , .reset(out_reset_i || tm_state_r == sIdle)
           , .enable(fs_pattern_gen_en)
           , .pattern_o);

   always_ff @(posedge out_clk_i)
     begin

        out_calib_prepare_i_r <= out_calib_prepare_i;
        out_test_pass_r       <= out_test_pass_n;
        out_finish_prepare_r  <= out_finish_prepare_n;

        if (out_reset_i) begin
            tm_state_r        <= sIdle;
            trigger_r         <= 0;
        end else begin
            tm_state_r        <= tm_state_n;
            trigger_r         <= trigger_n;
        end

        // zero the counter on prepare assertion and deassertion
        if (out_calib_prepare_i  ^ out_calib_prepare_i_r)
          out_ctr_r                 <= counter_bits_lp ' (0);
        else
          out_ctr_r                 <= out_ctr_n;

        out_override_valid_data_r   <= out_override_valid_data_n;
        out_override_en_r           <= out_override_en_n;

        if (verbose_lp)
        if (out_calib_prepare_i ^ out_calib_prepare_i_r)
          $display("## Master %m:  %s prepare part for Phase %1d"
                   , out_calib_prepare_i ? "entering" : "exiting"
                   , out_calibration_state_i
                   );

     end

   wire [counter_bits_lp-1:0] out_ctr_r_p1 = out_ctr_r + 1'b1;

   wire [tests_lp+1-1:0]            out_phase_X_good;

   always_comb
     begin
        out_finish_prepare_n = out_reset_i ? 0: out_finish_prepare_r;
        out_ctr_n            = out_reset_i ? 0: out_ctr_r;
        out_test_pass_n      = out_reset_i ? 0: out_test_pass_r;

        out_override_en_n         = 1'b0;
        out_override_valid_data_n = { 1'b0, (width_p) ' (0) };

        tm_state_n = sIdle;
        tm_counter_n = 0;
        trigger_n =0;
        fs_pattern_gen_en = 0;

        // transmit calibration code to slave
        // general, if we are in prepare mode, we will
        // assert the calibration code.

        if (out_calib_prepare_i)
          begin
             out_override_en_n         = 1'b1;
             out_finish_prepare_n      = 1'b1;

             // clear pass bit when we try to prepare
             out_test_pass_n[out_calibration_state_i] = 1'b0;

             out_override_valid_data_n = out_calib_code_padded;

             //
             // this pattern causes the node on the other side to assert its
             // outgoing token which allows our token logic to be reset.
             //
             // we want this to occur after reset is asserted but not so soon
             // that the everybody has not entered reset, may occur if
             // frequencies are very mismatched
             //
             // We also possibly want to repeat every so often in case the
             // system misses the first one.
             // however we don't want it to happen again too soon because
             // it might interfere with our efforts to do calibration etc.
             //
             // behavior: every 16 M cycles, wait 2^6 cycles
             // assert the token reset code for 2^6 cycles
             // and then deassert.

             out_ctr_n                 = out_ctr_r_p1;
             if (out_ctr_r[counter_min_bits_lp-1:lg_token_width_p] == 1'b1)
                  out_override_valid_data_n
                    = { 2'b11, { (width_p-3) {1'b0} }, out_calibration_state_i[1:0] };
          end
        else // if we need to finish preparing, which basically means assert the
             // calibration code for some cycles after the prepare signal goes down.
          if (out_finish_prepare_r)
            begin
               out_ctr_n                 = out_ctr_r_p1;
               out_override_en_n         = 1'b1;
               out_override_valid_data_n = out_calib_code_padded;

               // if the 7th bit is set (and we have had enough time to reset
               // the counter), let's exit the prepare stage
               // fixme: magic number
               if (out_ctr_r[lg_out_prepare_hold_cycles_p] & ~out_calib_prepare_i_r)
                 out_finish_prepare_n = 1'b0;
            end
          else
          begin
             out_test_pass_n[out_calibration_state_i]
               = out_phase_X_good[out_calibration_state_i];
             unique case (out_calibration_state_i)
            3:
              begin
                unique case (tm_state_r)
                sIdle: tm_state_n = sPhase3Trigger;
                sPhase3Trigger: begin
                    if (~out_override_is_posedge_i) begin
                        trigger_n = ~trigger_r;
                        out_override_en_n = 1;
                        out_override_valid_data_n = {~trigger_r, {width_p {1'b0}}};
                        tm_state_n = sPhase3Delay1;
                    end else begin
                        trigger_n = trigger_r;
                        out_override_en_n = 1;
                        out_override_valid_data_n = {trigger_r, {width_p {1'b0}}};
                        tm_state_n = sPhase3Trigger;
                    end
                end
                // 4 cycle delay is required for the trigger bit 
                // to propagate through the input channel synchronizer
                // TODO: refactor to one state and counter
                sPhase3Delay1: begin
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {trigger_r, {width_p {1'b0}}};
                    tm_state_n = sPhase3Delay2;
                end
                sPhase3Delay2: begin
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {trigger_r, {width_p {1'b0}}};
                    tm_state_n = sPhase3Delay3;
                end
                sPhase3Delay3: begin
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {trigger_r, {width_p {1'b0}}};
                    tm_state_n = sPhase3Delay4;
                end
                sPhase3Delay4: begin
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {trigger_r, {width_p {1'b0}}};
                    tm_state_n = sPhase3Send;
                end
                sPhase3Send: begin
                    fs_pattern_gen_en = 1;
                    out_override_en_n = 1;
                    trigger_n = trigger_r;
                    out_override_valid_data_n = {trigger_r, pattern_o};
                    tm_counter_n = tm_counter_r + 1;

                    if (tm_counter_n == words_per_cal_round_p) begin
                        tm_counter_n = 0;
                        tm_state_n = sPhase3Recv;
                    end else begin 
                        tm_state_n = sPhase3Send;
                    end
                end
                sPhase3Recv: begin
                    tm_counter_n = tm_counter_r + 1;
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {trigger_r, {width_p {1'b0}}};

                    if (out_all_packets_received)
                        tm_state_n = sPhase3Trigger;
                    else 
                        tm_state_n = sPhase3Recv;
                end
                default:
                begin
                end
                endcase
              end
            4:
              begin
                unique case (tm_state_r)
                sIdle: tm_state_n = sPhase4Trigger;
                sPhase4Trigger: begin
                    if (~out_override_is_posedge_i) begin
                        trigger_n = ~trigger_r;
                        out_override_en_n = 1;
                        // In Phase 3 the high data bit is the trigger
                        out_override_valid_data_n = {2'b0, ~trigger_r, {width_p-1 {1'b0}}};
                        tm_state_n = sPhase4Delay1;
                    end else begin
                        trigger_n = trigger_r;
                        out_override_en_n = 1;
                        out_override_valid_data_n = {2'b0, trigger_r, {width_p-1 {1'b0}}};
                        tm_state_n = sPhase4Trigger;
                    end
                end
                // 4 cycle delay is required for the trigger bit 
                // to propagate through the input channel synchronizer
                // TODO: refactor to one state and counter
                sPhase4Delay1: begin
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {2'b0, trigger_r, {width_p-1 {1'b0}}};
                    tm_state_n = sPhase4Delay2;
                end
                sPhase4Delay2: begin
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {2'b0, trigger_r, {width_p-1 {1'b0}}};
                    tm_state_n = sPhase4Delay3;
                end
                sPhase4Delay3: begin
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {2'b0, trigger_r, {width_p-1 {1'b0}}};
                    tm_state_n = sPhase4Delay4;
                end
                sPhase4Delay4: begin
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {2'b0, trigger_r, {width_p-1 {1'b0}}};
                    tm_state_n = sPhase4Send;
                end
                sPhase4Send: begin
                    fs_pattern_gen_en = 1;
                    out_override_en_n = 1;
                    trigger_n = trigger_r;
                    out_override_valid_data_n = {pattern_o[width_p-1], trigger_r, pattern_o[width_p-2:0]};
                    tm_counter_n = tm_counter_r + 1;

                    if (tm_counter_n == words_per_cal_round_p) begin
                        tm_counter_n = 0;
                        tm_state_n = sPhase4Recv;
                    end else begin 
                        tm_state_n = sPhase4Send;
                    end
                end
                sPhase4Recv: begin
                    tm_counter_n = tm_counter_r + 1;
                    trigger_n = trigger_r;
                    out_override_en_n = 1;
                    out_override_valid_data_n = {2'b0, trigger_r, {width_p-1 {1'b0}}};

                    if (out_all_packets_received)
                        tm_state_n = sPhase4Trigger;
                    else 
                        tm_state_n = sPhase4Recv;
                end
                default:
                begin
                end
                endcase
              end

            default:
              begin
              end
             endcase // unique case (out_calibration_state_i)
          end
     end // always_comb



   // ***********************************************
   // ** "IN" CLK DOMAIN LOGIC BELOW HERE
   //
   // This logic is basically responsible for checking
   // incoming data.
   //
   // Because we don't know the relationship between the output
   // and input clocks; we need to process incoming data in this
   // domain; and sending outgoing data in the other domain,
   // and only send occasional signals between the two.
   //

        wire [tests_lp+1-1:0] in_phase_X_good;

   // cross clock domain
   bsg_launch_sync_sync #(.width_p(tests_lp+1)) in_to_out
     (.iclk_i       (in_clk_i)
      ,.iclk_reset_i()
      ,.oclk_i      (out_clk_i)
      ,.iclk_data_i({ in_phase_X_good  })
      ,.iclk_data_o()
      ,.oclk_data_o({ out_phase_X_good })
      );

   wire [tests_lp-1:0]        in_test_enables;

   // bit vector of tests to make it more domain-crossing friendly
   // in this case, it's okay if they are temporarily enabled at the same time
   // so we don't worry about bit synchronization.
   wire [tests_lp-1:0] out_test_enables
     = (tests_lp) ' ((1 << out_calibration_state_i) & ({ tests_lp { ~out_calib_prepare_i } }));

   // send test enables from out clock domain to in clock domain
   bsg_launch_sync_sync #(.width_p(tests_lp)) out_to_in
     (.iclk_i       (out_clk_i)
      ,.iclk_reset_i()
      ,.oclk_i      (in_clk_i)
      ,.iclk_data_i({ out_test_enables })
      ,.iclk_data_o()
      ,.oclk_data_o({ in_test_enables  })
      );

   // START PHASE 2 CHECK 

   logic [width_p+1-1:0]    in_last_pos_r, in_last_neg_r, in_last_last_pos_r;

   logic [2*(width_p+1)-1:0] in_consec_pos_neg_match_r;
   logic [2*(width_p+1)-1:0] in_consec_neg_pos_match_r;

   // easy case: neg is the low order (fast) bits
   //
   //      neg      pos
   // t0  (a-1)_lo
   //                (a-1)_hi
   // t1   (a)_lo
   //               (a)_hi

   wire in_pos_neg_match
        = (              { in_last_pos_r,             in_last_neg_r } + 1'b1)
          == ({in_snoop_valid_data_pos_i, in_snoop_valid_data_neg_i});

   // harder case: neg is the high order bits.
   //
   //       neg      pos
   // t-1  (a-2)_hi
   //               (a-1)_lo
   //  t0  (a-1)_hi
   //               (a)_lo
   //  t1   (a)_hi
   //               (a+1)_lo

   wire in_neg_pos_match
        =  (    {             in_last_neg_r, in_last_last_pos_r } + 1'b1)
            == ({ in_snoop_valid_data_neg_i,      in_last_pos_r }        );


   // we allow for infinite credits if any of the loopback-style tests
   // are enabled.

   assign in_infinite_credits_o = in_test_enables[3] | in_test_enables[4];


   always_ff @(posedge in_clk_i)
     begin
        if (in_test_enables[2])
          begin
             in_last_pos_r      <= in_snoop_valid_data_pos_i;
             in_last_neg_r      <= in_snoop_valid_data_neg_i;
             in_last_last_pos_r <= in_last_pos_r;

             in_consec_pos_neg_match_r <= in_pos_neg_match & ~in_reset_i
                                          ? (&in_consec_pos_neg_match_r
                                             ? in_consec_pos_neg_match_r
                                             : in_consec_pos_neg_match_r+1'b1
                                             )
                                            : 0;

             in_consec_neg_pos_match_r <= in_neg_pos_match & ~in_reset_i
                                          ? (&in_consec_neg_pos_match_r
                                             ? in_consec_neg_pos_match_r
                                             : in_consec_neg_pos_match_r+1'b1
                                             )
                                            : 0;
             if ((in_consec_pos_neg_match_r > 100) & !in_pos_neg_match)
               $display("## Phase 1 Mismatch(P) %x %x %x %x"
                        , in_last_pos_r, in_last_neg_r
                        , in_snoop_valid_data_pos_i, in_snoop_valid_data_neg_i);

             if ((in_consec_neg_pos_match_r > 100) & !in_neg_pos_match)
               $display("## Phase 1 Mismatch(N) %x %x %x %x"
                        , in_last_neg_r, in_last_last_pos_r
                        , in_snoop_valid_data_neg_i, in_last_pos_r);
             if (&in_consec_pos_neg_match_r && ~in_pos_neg_match)
               $display("## Phase 1 Pos Lock");

             if (&in_consec_neg_pos_match_r  && ~in_neg_pos_match)
               $display("## Phase 1 Neg Lock");

             if (verbose_lp)
               begin
                  if ((in_consec_pos_neg_match_r & 12'hfff) == 12'hffe)
                    $display("## Posmatch %x; negmatch %x"
                             ,in_consec_pos_neg_match_r,in_consec_neg_pos_match_r);

                  if ((in_consec_neg_pos_match_r & 12'hfff) == 12'hffe)
                    $display("## Posmatch %x; negmatch %x"
                             ,in_consec_pos_neg_match_r,in_consec_neg_pos_match_r);
              end
           end
     end

  /***************************************************
   * 
   * Phase 1: Bit Alignment
   *
   ***************************************************/
  logic phase1_cal_done, phase1_timed_out;
  logic [width_p-1:0] bit_slip_vector, bit_slip_vector_r;
  logic in_test_enable_one_r;
  assign bit_slip_vector_to_tb_o = bit_slip_vector_r;

  always_ff @ (posedge in_clk_i)
  begin
      in_test_enable_one_r <= in_test_enables[1];

      if (in_reset_i)
          bit_slip_vector_r <= '0;

      if (in_test_enables[1])
         bit_slip_vector_r <= bit_slip_vector; 
  end

  phase1_checker #(.width_p(width_p))
    p1c (.clk(in_clk_i)
        ,.reset(in_reset_i)
        ,.enable(in_test_enables[1])
        ,.neg_valid_data_i(in_snoop_valid_data_neg_i[0+:width_p+1])
        ,.pos_valid_data_i(in_snoop_valid_data_pos_i[0+:width_p+1])
        ,.bit_slip_vector_o(bit_slip_vector)
        ,.cal_done_o(phase1_cal_done)
        ,.timed_out_o(phase1_timed_out)
        );

  /***************************************************
   * 
   * Phase 3, and Phase 4:  Input Channel Calibration
   *
   ***************************************************/

   bsg_launch_sync_sync #(.width_p(1'b1)
                         ,.words_per_cal_round_p(words_per_cal_round_p))
      blss_checker (.iclk_i(in_clk_i)
                   ,.iclk_reset_i(in_reset_i)
                   ,.oclk_i(out_clk_i)
                   ,.iclk_data_i(in_all_packets_received)
                   ,.iclk_data_o()
                   ,.oclk_data_o(out_all_packets_received)
                   );

   fs_pattern_checker #( .width_p(width_p))
      fspc (.clk(in_clk_i)
           ,.reset(in_reset_i)
           ,.enable(tm_state_r == sPhase3Send || 
                    tm_state_r == sPhase3Recv || 
                    tm_state_r == sPhase4Send || 
                    tm_state_r == sPhase4Recv) 
                    
           ,.neg_valid_data_i(in_snoop_valid_data_neg_i)
           ,.pos_valid_data_i(in_snoop_valid_data_pos_i)

           // Lets the state machine know that it can flip the trigger and send
           // another round of calibration words
           ,.all_packets_received_o(in_all_packets_received)
           ,.checker_success_o(checker_success)

           ,.checker_timed_out_o(checker_timed_out)
       );

   // clock initialize
   assign in_phase_X_good[0]            = 1'b1;

   // FIXME PHASE 1 CHECK
   assign in_phase_X_good[1]            = phase1_cal_done | bypass_test_p[1];

   // PHASE 2 (test 2) CHECK
   assign in_phase_X_good[2] =   (&in_consec_neg_pos_match_r)
                               | (&in_consec_pos_neg_match_r)
                               | bypass_test_p[2];

   // PHASE 3 and PHASE 4 CHECK
   assign in_phase_X_good[3] = (in_test_enables[3] & checker_success) | bypass_test_p[3];
   assign in_phase_X_good[4] = (in_test_enables[4] & checker_success) | bypass_test_p[4];

   // DONE
   assign in_phase_X_good[tests_lp] = 1'b1;


endmodule
