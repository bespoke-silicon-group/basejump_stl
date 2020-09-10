// MBT 7/24/2014
// DDR or center/edge-aligned SDR source synchronous input channel
//
// this implements:
//     incoming source-synchronous capture flops
//     async fifo to go from source-synchronous domain to core domain
//     outgoing token channel to go from core domain deque to out of chip
//     outgoing source-synchronous launch flops for token
//     programmable capture on either or both edges of the clock
//
// note, the default FIFO depth is set to 2^5
// based on the following calculation:
//
// 2 clks for channel crossing
// 3 clks for receive fifo crossing
// 1 clk for deque
// 3 clks for receive token fifo crossing
// 4 clks for token decimation
// 2 clks for channel crossing
// 3 clks for sender token fifo crossing
// 1 clk  for sender credit counter adjust
// -----------
// 19 clks
//
// This leaves us with 13 elements of margin
// for FPGA inefficiency. Since the FPGA may run
// at 4X slower, this is equivalent to 3 FPGA cycles.
//
// Aside: SERDES make bandwidth-delay product much worse
// because they simultaneously increase bandwidth and delay!
//
// io_*: signals synchronous to io_clk_i
// core_*: signals synchronous to core_clk_i
//
// During reset, the SS output channel needs to toggle its input toggle clock.
// To do this, it must  assert the two trigger lines (0x180 on { valid , data })
// and wait at least 2**(lg_credit_to_token_decimation_p+1) cycles and then deassert
// it. This will be routed around by the SS input channel and toggle the trigger
// clock line, allowing it be reset.
//

//
// perf fixme: data comes in at 64 bits per core cycle, but it is serialized
// to 32-bits per cycle in the core domain. thus in theory some assembler-like changes could
// allow for the in  I/O data rate to be twice the core frequency. but the assembler
// may be on the core critical path.
//

`include "bsg_defines.v"

module bsg_source_sync_input #(parameter lg_fifo_depth_p=5
                               , parameter lg_credit_to_token_decimation_p=3
                               , parameter channel_width_p=8
)
   (
    // source synchronous input channel; coming from chip edge
    input                         io_clk_i      // sdi_sclk
    , input                        io_reset_i   // synchronous reset
    , input                        io_token_bypass_i // {v,d[7]} controls token signal
    , input  [channel_width_p-1:0] io_data_i    // sdi_data
    , input                        io_valid_i   // sdi_valid
    , input  [1:0]                 io_edge_i    // bit vector of which

                                                // edges to capture <pos, neg edge>
                                                //   11=DDR
                                                //   10=edge-aligned SDR
                                                //   01=center-aligned SDR
                                                //
    , output                       io_token_r_o // sdi_token; output registered

    // positive edge snoop
    , output [channel_width_p:0]   io_snoop_pos_r_o     // { valid, data};

    // negative edge snoop
    , output [channel_width_p:0]   io_snoop_neg_r_o     // { valid, data};

    // for calibration
    , input                        io_trigger_mode_en_i      // in trigger mode
    , input                        io_trigger_mode_alt_en_i  // use alternate trigger

    // going into core; uses core clock
    , input                        core_clk_i
    , input                        core_reset_i  // synchronous reset
    , output [channel_width_p-1:0] core_data_o
    , output                       core_valid_o
    , input                        core_yumi_i   // accept data if:
                                                 //    core_valid_o high, and then
                                                 //    core_yumi_i  high

   );

   // ******************************************
   // DDR capture registers
   //
   // we capture data on both edges. the negedge comes before the
   // positive edge logically and hence is labeled 0. we delay
   // the negedge so we can consider both data words on the same cycle.
   //
   // set_dont_touch these and apply the
   // static timing rules

   logic [channel_width_p-1:0]   core_data_0,  core_data_1
                                 , io_data_0_r,  io_data_1_r;

   logic                         core_valid_0, core_valid_1
                                 , io_valid_0_r, io_valid_1_r
                                 , io_valid_negedge_r;

   logic [channel_width_p-1:0] io_data_negedge_r;

   // capture negedge data and valid
   always @(negedge io_clk_i)
     begin
        io_data_negedge_r  <= io_data_i;
        io_valid_negedge_r <= io_valid_i;
     end

   // then capture posedge data and valid
   always @(posedge io_clk_i)
     begin
        io_data_0_r  <= io_data_negedge_r;    io_valid_0_r <= io_valid_negedge_r;
        io_data_1_r  <= io_data_i;            io_valid_1_r <= io_valid_i;
     end

   assign io_snoop_pos_r_o = {io_valid_1_r, io_data_1_r};
   assign io_snoop_neg_r_o = {io_valid_0_r, io_data_0_r};

   // ******************************************
   // trigger_mode
   //
   // Trigger mode is used for alignment. We sample the input in bursts of 8 pairs
   // and then send through the FIFO.
   //
   // In alternate mode, we capture the valid bit instead of
   // a data bit. Which data bit should we substitute out?
   // We don't want the alternate trigger wire to be next to the valid/ncmd line.
   // GF28: valid (ncmd) bit is between data_0 and sclk.
   // UCSD_BGA: valid (ncmd) bit is between data_3 and sclk.
   // So substituting in for the top bit of the data should be fine for both cases.
   //
   //

   wire    [channel_width_p-1:0] io_data_0_r_swizzle = io_trigger_mode_alt_en_i
                                 ? {io_valid_0_r, io_data_0_r[0+:channel_width_p-1] }
                                 : io_data_0_r;

   wire    [channel_width_p-1:0] io_data_1_r_swizzle = io_trigger_mode_alt_en_i
                                 ? {io_valid_1_r, io_data_1_r[0+:channel_width_p-1] }
                                 : io_data_1_r;

   wire   io_trigger_mode_0, io_trigger_mode_1;

   // when we are in trigger mode, we have not aligned bits yet
   // so we have the risk of metastability, so we must synchronize
   // both possible trigger bits.

   // fixme: do these need launch flops?
   
   bsg_sync_sync #(.width_p(1)) bssv
   (.oclk_i(io_clk_i)
    ,.iclk_data_i(io_valid_1_r)
    ,.oclk_data_o(io_trigger_mode_0)
    );

   // note if you change the location of the trigger bit
   // then you need to potentially change the calibration codes
   bsg_sync_sync #(.width_p(1)) bssd
   (.oclk_i(io_clk_i)
    ,.iclk_data_i(io_data_1_r[channel_width_p-1])
    ,.oclk_data_o(io_trigger_mode_1)
    );

   localparam lg_io_trigger_words_lp = 3;
   logic  io_trigger_line_r;
   logic [lg_io_trigger_words_lp+1-1:0] io_trigger_count_r;

   wire io_trigger_line = io_trigger_mode_alt_en_i
                          ? io_trigger_mode_1
                          : io_trigger_mode_0;

   wire io_trigger_mode_active = (| io_trigger_count_r);

   always @(posedge io_clk_i)
     if (io_reset_i)
       begin
          io_trigger_line_r  <= 0;
          io_trigger_count_r <= 0;
       end
     else
       begin
          // delay by one full clock cycle to detect transition
          io_trigger_line_r <= io_trigger_line;
          if (io_trigger_mode_active)
            io_trigger_count_r <= io_trigger_count_r - 1;
          else
            // if trigger line switched over last cycle
            // we go ahead and capture data
            if (io_trigger_line ^ io_trigger_line_r)
              io_trigger_count_r <= 2**(lg_io_trigger_words_lp);
       end


   // ******************************************
   // clock-crossing async fifo (with DDR interface)
   //
   // we enque both DDR words side-by-side, with valid bits
   // if either one of them is valid. this us allows us
   // to reconcile the ordering of negedge versus posedge clock
   //

   wire   io_async_fifo_full;
   wire   io_async_fifo_enq = io_trigger_mode_en_i
               ? io_trigger_mode_active             // enque if we in trigger mode
               : (io_valid_0_r | io_valid_1_r);     // enque if either valid bit set

   // synopsys translate_off

   always @(negedge io_clk_i)
     assert(!(io_async_fifo_full===1 && io_async_fifo_enq===1))
       else $error("attempt to enque on full async fifo");

   // synopsys translate_on


   wire   core_actual_deque;
   wire   core_valid_o_tmp;


   bsg_async_fifo #(.lg_size_p(lg_fifo_depth_p)  // 32 elements
                    ,.width_p( (channel_width_p+1)*2 ) // room for both valids and
                                                       //  for both data words
		    ,.control_width_p(2)
                    ) baf
   (
    .w_clk_i(io_clk_i)
    ,.w_reset_i(io_reset_i)
    ,.w_enq_i(io_async_fifo_enq)
    ,.w_data_i(io_trigger_mode_en_i
               ? { 1'b1                       , 1'b1
                   , io_data_1_r_swizzle      , io_data_0_r_swizzle}

               : { io_valid_1_r & io_edge_i[1], io_valid_0_r & io_edge_i[0]
                  , io_data_1_r               , io_data_0_r                })

    ,.w_full_o(io_async_fifo_full)

    ,.r_clk_i(core_clk_i)
    ,.r_reset_i(core_reset_i)

    ,.r_deq_i(core_actual_deque)
    ,.r_data_o({core_valid_1, core_valid_0, core_data_1, core_data_0})

    // there is data in the FIFO
    ,.r_valid_o(core_valid_o_tmp)
    );

   logic  core_sent_0_want_to_send_1_r;


   // send 1 if we already sent 0; or if there is no 0.
   wire [channel_width_p-1:0] core_data_o_pre_twofer
                              = (core_sent_0_want_to_send_1_r | ~core_valid_0)
                              ? core_data_1
                              : core_data_0;

   wire core_valid_o_pre_twofer = core_valid_o_tmp; // remove inout warning from lint

   wire core_twofer_ready;

   // Oct 17, 2014
   // we insert a minimal fifo here for two purposes;
   // first, this reduces critical
   // paths causes by excessive access times of the async fifo.
   //
   // second, it ensures that asynchronous paths end inside of this module
   // and do not propogate out to other modules that may be attached, complicating
   // timing assertions.
   //

   bsg_two_fifo #(.width_p(channel_width_p)) twofer
     (.clk_i(core_clk_i)
      ,.reset_i(core_reset_i)

      // we feed this into the local yumi, but only if it is valid
      ,.ready_o(core_twofer_ready)
      ,.data_i(core_data_o_pre_twofer)
      ,.v_i(core_valid_o_pre_twofer)

      ,.v_o(core_valid_o)
      ,.data_o(core_data_o)
      ,.yumi_i(core_yumi_i)
      );


   // a word was transferred to the two input fifo if ...
   wire core_transfer_success = core_valid_o_tmp & core_twofer_ready;

/*   
                               // deque if there was an actual transfer, AND (
   assign   core_actual_deque  = core_transfer_success
                               // we sent the 0th word already,
                               // and just sent the 1st word, OR
                               & ((core_sent_0_want_to_send_1_r & core_valid_1)
                                  // we sent the 0th word and there is no 1st word OR
                                  // we sent the 1st word, and there is no 0th word
                                  | (core_valid_0 ^ core_valid_1));
*/
   assign core_actual_deque = core_transfer_success & ~(~core_sent_0_want_to_send_1_r & core_valid_1 & core_valid_0);

   always @(posedge core_clk_i)
     begin
        if (core_reset_i)
          core_sent_0_want_to_send_1_r  <= 0;
        else
          // if we transferred data, but do not deque, we must have another word to
          // transfer. mbt fixme: this was originally:
          // core_transfer_success & ~core_actual_deque
          // but had a bug. review further.
          core_sent_0_want_to_send_1_r  <= core_transfer_success
                                           ? ~core_actual_deque
                                           : core_sent_0_want_to_send_1_r;
     end

// **********************************************
// credit return
//
// these are credits coming from the receive end of the async fifo in the core clk
//  domain and passing to the io clk domain and out of the chip.
//

   logic [lg_fifo_depth_p+1-1:0] core_credits_gray_r_iosync
                                 , core_credits_binary_r_iosync
                                 , io_credits_sent_r, io_credits_sent_r_gray
                                 , io_credits_sent_r_p1, io_credits_sent_r_p2;

   bsg_async_ptr_gray #(.lg_size_p(lg_fifo_depth_p+1)) bapg
   (.w_clk_i   (core_clk_i)
    ,.w_reset_i(core_reset_i)
    ,.w_inc_i  (core_transfer_success)
    ,.r_clk_i  (io_clk_i)
    ,.w_ptr_binary_r_o() // not needed
    ,.w_ptr_gray_r_o()   // not needed
    ,.w_ptr_gray_r_rsync_o(core_credits_gray_r_iosync)
    );

   // this logic allows us to return two credits at a time
   // note: generally relies on power-of-twoness of io_credits_sent_r
   // to do correct wrap around.

   always_comb io_credits_sent_r_p1 = io_credits_sent_r+1;
   always_comb io_credits_sent_r_p2 = io_credits_sent_r+2;

   // which bit of the io_credits_sent_r counter we use determines
   // the value of the token line in credits
   //
   //
   // this signal's register should be placed right next to the I/O pad:
   //   glitch sensitive.

   assign io_token_r_o = io_credits_sent_r[lg_credit_to_token_decimation_p];

   // we actually absorb credits one or two at a time rather as fast as we can.
   // this because otherwise we would not be slowing transition rates on the token
   // signal, which is the whole point of tokens! this is slightly suboptimal,
   // because if enough cycles have passed from the last
   // time we sent a token, we could actually acknowledge things faster if we
   // absorbed more than one credit at a time.
   // that's okay. we skip this optimization.

   // during token bypass mode, we hardwire the credit signal to the trigger mode signals;
   // this gives the output channel control over the credit signal which
   // allows it to toggle and reset the credit logic.

   // the use of this trigger signal means that we should avoid the use of these
   // two signals for calibration codes, so that we do not mix calibration codes
   // when reset goes low with token reset operation, which would be difficult to avoid
   // since generally we cannot control the timing of these reset signals when
   // they cross asynchronous boundaries

   // this is an optimized token increment system
   // we actually gray code two options and compare against
   // the incoming greycoded pointer. this is because it's cheaper
   // to grey code than to de-gray code. moreover, we theorize it's cheaper
   // to compute an incremented gray code than to add one to a pointer.
   
   assign io_credits_sent_r_gray = (io_credits_sent_r >> 1) ^ io_credits_sent_r;

   logic [lg_fifo_depth_p+1-1:0] io_credits_sent_p1_r_gray;
   
   bsg_binary_plus_one_to_gray #(.width_p(lg_fifo_depth_p+1)) bsg_bp1_2g
     (.binary_i(io_credits_sent_r)
      ,.gray_o(io_credits_sent_p1_r_gray)
      );
   
   wire empty_1 = (core_credits_gray_r_iosync != io_credits_sent_p1_r_gray);
   wire empty_0 = (core_credits_gray_r_iosync != io_credits_sent_r_gray);

   always @(posedge io_clk_i)
     begin
        if (io_token_bypass_i)
          io_credits_sent_r <= { lg_fifo_depth_p+1
                                 { io_trigger_mode_1 & io_trigger_mode_0 } };
        else
          // we absorb up to two credits per cycles, since we receive at DDR,
          // we need this to rate match the incoming data

	  // code is written like this because empty_1 is late relative to empty_0
          io_credits_sent_r <= (empty_1
                                ? (empty_0 ? io_credits_sent_r_p2 : io_credits_sent_r)
                                : (empty_0 ? io_credits_sent_r_p1 : io_credits_sent_r));
     end

endmodule // bsg_source_sync_input
