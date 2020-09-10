// MBT 7/24/2014
// source synchronous output channel
//
// this implements:
//     - outgoing source-synchronous launch flops
//     - async fifo to go from source-synchronous domain to core domain
//     - outgoing token channel to go from core domain deque to out of chip
//     - outgoing source-synchronous launch flops for token
//     - center-aligned DDR source sync output clock
//
// io_    : signals synchronous to io_clk_i
// core_  : signals synchronous to core_clk_i
// token_ : signals synchronous to token_clk_i
//
//
// Note, for token clock reset, there is a certain pattern that must be asserted
// and deasserted during io reset.
//
// lg_start_credits_p should be consistent with the paired source_sync_output
//
`include "bsg_defines.v"

module bsg_source_sync_output
     #(
       parameter   lg_start_credits_p              = 5
       , parameter lg_credit_to_token_decimation_p = 3 // 8:1
       , parameter channel_width_p                 = 8

       // we explicit set the "inactive pattern"
       // on data lines when valid bit is not set
       //  to (01)+ = 0x5*
       //
       // the inactive pattern should balance the current
       // across I/O V33 and VZZ pads, reducing
       // electromigration for the common case of not
       // sending.
       //
       // for example, in TSMC 250, the EM limit is 41 mA
       // and the ratio of signal to I/O V33 and VZZ is
       // 4:1:1.
       //

       // fixme: an alternative might be to tri-state
       // the output, but further analysis is required
       // as to whether this is a good idea.

       // This has implications for calibration;
       // specifically v=0,d=5* should not be used.
       // an alternative to this inactive pattern is to
       // invert alternating bits or to apply a scramble
       //  pattern. We keep it simple.

       , parameter inactive_pattern_p = {channel_width_p { 2'b01 } }
       )
   (
    // going out of core; uses core clock
    input                           core_clk_i
    , input                         core_reset_i
    , input [channel_width_p-1:0]   core_data_i
    , input                         core_valid_i
    , output                        core_ready_o  // if core_valid_i and core_ready_o
                                                  // high , data accepted.

    , input                         io_master_clk_i
    , input                         io_reset_i       // reset
    , input                         io_clk_init_i     // necess. for sim. only

    , input                         io_override_en_i

    // includes valid bit at top
    , input   [channel_width_p:0]   io_override_valid_data_i

    // sometimes the master wants to know if the data we are overriding
    // is happening on the positive or negative edge of the clock
    , output                        io_override_is_posedge_o


    // source synchronous output channel; going to chip edge
    , output logic                        io_clk_r_o   // sdo_sclk (output DDR clock)
    , output logic  [channel_width_p-1:0] io_data_r_o  // sdo_data
    , output logic                        io_valid_r_o // sdo_valid


    // make there be infinite credits -- use only for calibration
    // must be asserted continuously between resets.

    , input                               io_infinite_credits_i

    , input                         token_clk_i      // sdo_token; input clk

    // token reset rules:
    //    token_clk_i should be 010'd while token_reset_i is asserted
    //    io_master_clk_i should have > 4 posedges after that.
    //    token_reset_i is not actually synchronous to token_clk_i
    //    so it should be asserted well before token_clk_i is asserted
    //    and de-asserted well afterwards to avoid metastability

    , input                         token_reset_i    // token fifo reset
   );

   // MBT: we insert a two-element fifo here to
   // decouple the async fifo logic which can be on the critical
   // path in some cases. possibly this is being overly conservative
   // and may introduce too much latency. but certainly in the
   // case of the bsg_comm_link code, it is necessary.
   // fixme: possibly make it a parameter as to whether we instantiate
   // this fifo

   wire core_twofer_valid, core_twofer_yumi;
   wire [channel_width_p-1:0] core_twofer_data;

   bsg_two_fifo #(.width_p(channel_width_p)) twofer
     (.clk_i(core_clk_i)
      ,.reset_i(core_reset_i)
      ,.ready_o(core_ready_o)
      ,.data_i (core_data_i)
      ,.v_i    (core_valid_i)

      ,.v_o   (core_twofer_valid)
      ,.data_o(core_twofer_data)
      ,.yumi_i(core_twofer_yumi)
      );

   logic                            io_data_avail;

   // ******************************************
   // launch registers;
   //
   // set_dont_touch these and apply the
   // static timing rules

   logic [channel_width_p-1:0] io_data_n;
   logic                       io_valid_n;

   // whether reset was asserted on the last cycle
   logic                       io_reset_r;

   always @(posedge io_master_clk_i)
     begin
        io_reset_r   <= io_reset_i;
        if (io_override_en_i)
          { io_valid_r_o, io_data_r_o }   <= io_override_valid_data_i;
        else
          begin
             io_valid_r_o <= io_valid_n;

             if (io_valid_n)
               io_data_r_o <= io_data_n;
             else
               io_data_r_o <= inactive_pattern_p [0+:channel_width_p];
          end
     end


   logic io_clk_n, io_clk_r_pos;

   // generate a DDR clock at same mbps rate as data and valid
   // we use negedge to center align the clock with the data
   // this is helpful because on the other side, there is no clock edge
   // available to do this alignment.

   // for simulation, we need to reset the clock waveform to
   // a known value. this is not necessary for the real chip.
   // unfortunately, this has a 50 percent probability of causing
   // a 180 degree phase shift, which would cause most PLLs to lose lock,
   // such as the ones controlling the SERDES in the FPGA.
   //
   // to get around this problem, for the slave, we have a special phase
   // (sResetClock) in calibration that causes this to be done; this phase
   //  can be skipped by the master in the real system.

   // we explicitly instantiate this register so that we can eliminate
   // the clock uncertainty in the constraints file
   
   always @(negedge io_master_clk_i)
     begin
        io_clk_r_o  <= io_clk_init_i ? 1'b0 : io_clk_n;
     end

   /*   bsg_dff_negedge_reset #(.width_p(1)) io_clk_r_o_reg
    (.clk_i(io_master_clk_i)
    ,.data_i(io_clk_n)
    ,.reset_i(io_clk_init_i)
    ,.data_o(io_clk_r_o)
    );
    */
   
   // synopsys translate_off
   always @(posedge io_master_clk_i)
   begin
      if (io_clk_init_i === 1)
	$display("## %m Reset DDR clock");
   end
   // synopsys translate_on

   assign io_clk_n = ~io_clk_r_o;

   always_ff @(posedge io_master_clk_i)
     io_clk_r_pos <= io_clk_n;

   // we negate after the register to prevent
   // $ynopsys from optimizing and placing
   // more load on the io_clk_r_o
   //
   assign io_override_is_posedge_o = ~io_clk_r_pos;

   wire core_fifo_full;
   assign core_twofer_yumi = core_twofer_valid & ~core_fifo_full;




   // ******************************************
   // clock-crossing async fifo
   // this is just an output fifo and does not
   // need to cover the round trip latency
   // of the channel; just the clock domain crossing
   //
   // Assuming (A and B are registers with the corresponding clocks)
   // this is the structure of the roundtrip path:
   //
   //                 /--  B <-- B <-- A <--\
   //                |                      |
   //                 \--> B --> A --> A ---/
   //
   // Suppose we have cycleTimeA and cycleTimeB, with cycleTimeA > cycleTimeB
   // the bandwidth*delay product of the roundtrip is:
   //
   //   3 * (cycleTimeA + cycleTimeB) * min(1/cycleTimeA, 1/cycleTimeB)
   // = 3 + 3 * cycleTimeB / cycleTimeA
   //
   // w.c. is cycleTimeB == cycleTimeA
   //
   // --> 6 elements
   //
   // however, for the path from A to B and B to A
   // we need to clear not only the cycle time of A/B
   // but the two setup times, which are guaranteed to
   // be less than a cycle each. So we get 8 elements total.
   //

   bsg_async_fifo #(.lg_size_p(3)
                    ,.width_p(channel_width_p)
                    ) baf
   (
    .w_clk_i(core_clk_i)
    ,.w_reset_i(core_reset_i)

    // if the fifo is not full, and we have valid data coming in, we grab it
    ,.w_enq_i(core_twofer_yumi)
    ,.w_data_i(core_twofer_data)
    ,.w_full_o(core_fifo_full)

    ,.r_clk_i(io_master_clk_i)
    ,.r_reset_i(io_reset_i)

    ,.r_deq_i(io_valid_n)
    ,.r_data_o(io_data_n)

    // there is data in the FIFO
    ,.r_valid_o(io_data_avail)
    );

   // this can easily happen if the sending core clock
   // is higher than the I/O clock
   // always @(negedge core_clk_i)
   //  assert (~(core_fifo_full===1))
   //   else $error("source synchronous output FIFO unexpectedly full");

   // we need to track whether the credits are coming from
   // posedge or negedge tokens.

   // high bit indicates which counter we are grabbing from
   logic [lg_credit_to_token_decimation_p+1-1:0] token_alternator_r;

   always @(posedge io_master_clk_i)
     begin
        if (io_reset_i)
          // this will start us on the posedge token
          token_alternator_r <= 0;
        else
          if (io_valid_n)
            token_alternator_r <= token_alternator_r + 1;
     end

   // high bit set means we have exceeded number of posedge credits
   // and are doing negedge credits
   wire on_negedge_token = token_alternator_r[lg_credit_to_token_decimation_p];

   logic io_negedge_credits_avail, io_posedge_credits_avail;

   wire io_credit_avail = on_negedge_token
        ? io_negedge_credits_avail
        : io_posedge_credits_avail;

   // we send if we have both data to send and credits to send with
   assign io_valid_n = io_credit_avail & io_data_avail;

   wire io_negedge_credits_deque = io_valid_n & on_negedge_token;
   wire io_posedge_credits_deque = io_valid_n & ~on_negedge_token;

   // **********************************************
   // token channel
   //
   // these are tokens coming from off chip that need to
   // cross into the io clock domain.
   //
   // note that we are a little unconventional here; we use the token
   // itself as a clock. this because we don't know the phase of the
   // token signal coming in.
   //
   // we count both edges of the token separately, and assume that they
   // will alternate in lock-step. we use two separate counters to do this.
   //
   // an alternative would be to use
   // dual-edged flops, but they are not available in most ASIC libraries
   // and although you can synthesize these out of XOR'd flops, they
   // violate the async maxim that all signals crossing clock boundaries
   // must come from a launch flop.

   bsg_async_credit_counter
     #(// half the credits will be positive edge tokens
       .max_tokens_p(2**(lg_start_credits_p-1-lg_credit_to_token_decimation_p))
       ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
       ,.count_negedge_p(1'b0)
       // we enable extra margin in case downstream module wants more tokens
       ,.extra_margin_p(2)
       ,.start_full_p(1)
       ) pos_credit_ctr
       (
        .w_clk_i   (token_clk_i  )
	,.w_inc_token_i(1'b1)
        ,.w_reset_i(token_reset_i)

        // the I/O clock domain is responsible for tabulating tokens
        ,.r_clk_i  (io_master_clk_i)
        ,.r_reset_i(io_reset_i     )
        ,.r_dec_credit_i      (io_posedge_credits_deque)
        ,.r_infinite_credits_i(io_infinite_credits_i)
        ,.r_credits_avail_o   (io_posedge_credits_avail)
        );

   bsg_async_credit_counter
     #(// half the credits will be negative edge tokens
       .max_tokens_p(2**(lg_start_credits_p-1-lg_credit_to_token_decimation_p))
       ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
       ,.count_negedge_p(1'b1)
       // we enable extra margin in case downstream module wants more tokens
       ,.extra_margin_p(2)
       ,.start_full_p(1)
       ) neg_credit_ctr
       (
        .w_clk_i   (token_clk_i)
	,.w_inc_token_i(1'b1)
        ,.w_reset_i(token_reset_i)

        // the I/O clock domain is responsible for tabulating tokens
        ,.r_clk_i             (io_master_clk_i         )
        ,.r_reset_i           (io_reset_i              )
        ,.r_dec_credit_i      (io_negedge_credits_deque)
        ,.r_infinite_credits_i(io_infinite_credits_i)
        ,.r_credits_avail_o(io_negedge_credits_avail)
        );


endmodule
