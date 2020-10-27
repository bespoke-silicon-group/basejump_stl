// MBT 8/27/14
//
// ASIC (slave) calibration module
//
// See BSG Source Synchronous I/O for specification of this.
//
// everything beginning with "out" is the output channel clock
// everything beginning with "in"  is the input  channel clock
// everything beginning with "core" is the core channel clock
//
// we feed the async reset directly into this module to
// reduce the latency
//


`include "bsg_defines.v"

module  bsg_source_sync_channel_control_slave #( parameter width_p  = -1
                                                 , lg_token_width_p =  "inv")
   (// output channel
    input  out_clk_i
    , input  out_reset_i
    , output reg out_clk_init_r_o  // initialize output master clock

    // this is used to force data on to the output channel
    // (calibration modes 0 and 1)
    , output                 out_override_en_o
    , output [width_p+1-1:0] out_override_valid_data_o

    // this is actually sampled with out_clk_i
    , input  [width_p+1-1:0] in_snoop_valid_data_i

    // ** signals for the input channel in loopback mode (calibration modes 2 and 3)
    , input  in_clk_i

    , output in_trigger_mode_en_o
    , output in_trigger_mode_alt_en_o

    // AWC fixme: should be out_infinite_credits_o
    //, output in_infinite_credits_o
    , output logic out_infinite_credits_o

    , input core_clk_i     // for synchronizers
    // used for loopback mode (calibration modes 2 and 3)
    , output core_loopback_en_o

    // whether the channel is available for I/O assembler, post reset
    , output out_channel_active_o

    );

   wire [4:0] out_snoop_valid_data;
   wire       out_active_mismatch;
   wire [(((width_p+1)>>1)<<1)-1:0] out_active_pattern
                                    = { ((width_p+1) >> 1) { (2'b10) } };
   // we omit the synchronizer; this code has the express
   // assumption that the async_reset_i is asserted for enough
   // cycles before and after the data is changed.

   if (width_p >= 4)
     assign out_snoop_valid_data = { in_snoop_valid_data_i[(width_p)-:5] };
   else
     assign out_snoop_valid_data = { in_snoop_valid_data_i[(width_p)-:4], 1'b0};

   // we check extra bits if it's an activate code; accidental activation
   // could occur if the right pattern of bits happens to be stuck; this
   // increases the number of required stuck bits a lot to 8 for an 8-bit
   // channel; accidental activation should be very unlikely

   if (width_p <= 4)
     assign out_active_mismatch = 1'b0;
   else
     assign out_active_mismatch
       = | (      out_active_pattern[width_p+1-$bits(out_snoop_valid_data)-1:0]
             ^ in_snoop_valid_data_i[width_p+1-$bits(out_snoop_valid_data)-1:0]
             );

   typedef enum logic [3:0] { sBegin
                        , sPhase1
                        , sPhase2
                        , sPhase3
                        , sPhase4
                        , sActive
                        , sInactive
                        , sResetClock
                        }
                      calib_state_s;

   calib_state_s out_state_n, out_state_r;

   always @(posedge out_clk_i)
     if (out_reset_i)
       out_state_r <= sBegin;
     else
       out_state_r <= out_state_n;

   // calibration state detection
   always_comb
     begin
        out_state_n = out_state_r;

        if (out_state_r == sBegin) // i.e. in reset
          begin
             // value on bus determines the state we go into when reset is deasserted
             // we assume it has stabilized for many cycles before reset goes low
             // to avoid metastability issues.

             // top 5 bits of in_snoop_valid_data_i
             unique casez (out_snoop_valid_data)

               // we are most optimistic about reset clock signals
               // because we want to be able to reset the clock
               // even in the presence of stuck-at faults to avoid
               // x-contamination. in the real chip, this doesn't
               // really matter, since the clock does not need to
               // be reset.

               5'b0_?111: out_state_n = sResetClock; // reset i/o ddr clock
               5'b0_1?10: out_state_n = sResetClock; // reset i/o ddr clock
               5'b0_1011: out_state_n = sResetClock; // reset i/o ddr clock
               5'b0_1101: out_state_n = sResetClock; // reset i/o ddr clock
               5'b1_1111: out_state_n = sResetClock; // valid bit stuck

               5'b0_0100: out_state_n = sPhase1;
               5'b0_0101: out_state_n = sPhase2;
               5'b0_0010: out_state_n = sPhase3;
               5'b0_0011: out_state_n = sPhase4;
               5'b0_0110:
                 begin
                    /*
                    $display("plo %b %b %b %b %b "
                             , out_active_pattern[width_p+1-$bits(out_snoop_valid_data)-1:0]
                             , in_snoop_valid_data_i[width_p+1-$bits(out_snoop_valid_data)-1:0]
                             , out_active_pattern
                             , in_snoop_valid_data_i
                             , out_active_mismatch);
                     */
                    // check all of the bits for this case
                    out_state_n = out_active_mismatch ? sInactive : sActive;
                 end

               // 4+-bit inactive pattern (see bsg_source_sync_output)
               // 3 -bit inactive pattern (see bsg_source_sync_output)
               5'b0_100?: out_state_n = sInactive;

               // we default to sPhase3 (loopback) rather than the sInactive
               // reason: it is a quiet pattern, but allows us to
               // inspect what is going on with the die even if some lines don't work
               // Also, if the valid bit is stuck, then
               // Phase 3 is nice because it's level sensitive so will not be too noisy
               // effectively it detaches the source synchronous fifos
               default:   out_state_n = sPhase3;
             endcase
          end // case: sBegin
     end

   // 24 is 16M cycles
   localparam counter_min_bits_lp = 24;
   localparam counter_bits_lp = `BSG_MAX(counter_min_bits_lp,(width_p+1)*2+1);

   logic [counter_bits_lp-1:0] out_ctr_r,                 out_ctr_n;

   // does not vary with channel width
   logic [7:0]                 out_rot_r,                 out_rot_n;
   logic [width_p+1-1:0]       out_override_valid_data_r, out_override_valid_data_n;
   logic                       out_override_en_r,         out_override_en_n;

   // AWC fixme, add registered value
   //logic                       out_infinite_credits;


   assign out_override_valid_data_o = out_override_valid_data_r;
   assign out_override_en_o         = out_override_en_r;

   logic                       out_reset_r;


   always_ff @(posedge out_clk_i)
     begin
        out_reset_r <= out_reset_i;

        // initialize the outclock if we are entering the sResetClock state from the begin state
        // if we want to avoid upsetting the PLL, the master can skip this state

        out_clk_init_r_o        <=    ~out_reset_i
                                      & (out_state_n == sResetClock)
                                      & (out_state_r == sBegin);

        out_override_en_r       <= out_override_en_n;

        // zero the counter on both reset assertion and deassertion

        // synopsys sync_set_reset "out_reset_i, out_reset_r"
        if (out_reset_i ^ out_reset_r)
          begin
             out_ctr_r                 <= counter_bits_lp ' (0);
             out_override_valid_data_r <= { (width_p+1)  {1'b0} };
          end
        else
          begin
             out_ctr_r                 <= out_ctr_n;
             out_override_valid_data_r <= out_override_valid_data_n;
          end

        if (out_state_r == sBegin)
          out_rot_r                 <= 8'b1010_0101;   // bit alignment sequence
        else
          out_rot_r                 <= out_rot_n;
     end

   // synopsys translate_off

   always @(out_state_r)
     begin
        $display("## Slave %m entering state %s with in_snoop_valid_data_i %b"
                 ,out_state_r.name, in_snoop_valid_data_i);
     end

   initial
     assert (width_p > 2)
       else $error("width_p currently must be >= 3 because of calibration codes");

   // synopsys translate_on

   assign  out_channel_active_o  = (out_state_r == sActive);
   wire  out_loopback_en         = (out_state_r == sPhase3)
                                || (out_state_r == sPhase4);

   wire  out_trigger_mode_alt_en = (out_state_r == sPhase4);

   // note these are not multi-bit signals; they are just a bulk
   // movement of signals across clock domains

   bsg_launch_sync_sync #(.width_p(1)) out_to_core_lss
     (.iclk_i       (out_clk_i  )
      ,.iclk_reset_i(1'b0)
      ,.oclk_i      (core_clk_i )
      ,.iclk_data_i({ out_loopback_en  })
      ,.iclk_data_o()
      ,.oclk_data_o({ core_loopback_en_o})
      );


   // AWC fixme
   // instead of running out_infinite_credits
   // through the synchronizer to create in_infinite_credits_o, we should
   // just register it and send it out as out_infinite_credits_o

   wire  AWC_ignore;

   bsg_launch_sync_sync #(.width_p(3)) out_to_in_lss
     (.iclk_i       (out_clk_i  )
      ,.iclk_reset_i(1'b0)
      ,.oclk_i      (in_clk_i   )
      ,.iclk_data_i({ out_loopback_en     ,   out_trigger_mode_alt_en, out_infinite_credits_o    })
      ,.iclk_data_o()
      ,.oclk_data_o({ in_trigger_mode_en_o,    in_trigger_mode_alt_en_o, AWC_ignore})
      );

   wire [counter_bits_lp-1:0] out_ctr_r_p1 = out_ctr_r + 1'b1;

   // fill pattern with at least as many 10's to fill width_p bits
   // having defaults be 10101 reduces electromigration on pads
   wire [(((width_p+1)>>1)<<1)-1:0] inactive_pattern
                                    = { ((width_p+1) >> 1) { (2'b10) } };

   always_comb
     begin
        out_infinite_credits_o = 1'b0;

        out_ctr_n = out_ctr_r;
        out_rot_n = out_rot_r;
        out_override_en_n         = 1'b0;
        out_override_valid_data_n = { 1'b0, inactive_pattern[0+:width_p] };

        unique case (out_state_r)
          sBegin:
            begin

               // one of the jobs of the begin phase (which occurs during reset)
               // is to toggle the outgoing token clock so that it is reset
               // on the other side.

               out_ctr_n                 = out_ctr_r_p1;
               out_override_en_n         = 1'b1;

               // this pattern causes the node on the other side to assert its
               // outgoing token which allows our token logic to be reset.
               //
               // we want this to occur after reset is asserted but not so soon
               // that the everybody has not entered reset, may occur if
               // frequencies are very mismatched
               //
               // We also possibly want to repeat every so often in case the
               // system misses the first one; for example in the case of
               // having to wait for a FPGA PLL to lock onto the input clock,
               // which glitched when reset transitioned from low to high.
               // (sadly reset does not need to glitch; this is consequence
               // of having to initialize it to a known value in simulation.)
               //
               // however we don't want it to happen again too soon because
               // it might interfere with our efforts to do calibration etc.
               //
               // behavior: every 16 M cycles, wait 2^lg_token_width_p cycles
               // assert the token reset code for 2^lg_token_width_p cycles
               // and then deassert.

               if (out_ctr_r[counter_min_bits_lp-1:lg_token_width_p] == 1'b1)
                 out_override_valid_data_n = { 1'b1, 1'b1, { (width_p-1) {1'b0}} };
            end // case: sBegin

          sPhase1:
            begin
               out_rot_n                 = { out_rot_r[6:0], out_rot_r[7] };
               out_override_en_n         = 1'b1;
               out_override_valid_data_n = { (width_p+1) { out_rot_r[7] } };
            end
          sPhase2:
            begin
               out_ctr_n                 = out_ctr_r_p1;
               out_override_en_n         = 1'b1;
               // we do fast bits then slow bits
               out_override_valid_data_n =   out_ctr_r[0]
                                           ? out_ctr_r[(1+(width_p+1))+:(width_p+1)]
                                           : out_ctr_r[1+:(width_p+1)];
            end

          sPhase3:
            out_infinite_credits_o = 1'b1;

          sPhase4:
            out_infinite_credits_o = 1'b1;


          default:
            begin
            end
        endcase
     end

endmodule
