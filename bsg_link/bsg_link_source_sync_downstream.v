// MBT 7/24/2014
//
// Updated by Paul Gao 02/2019
//
// DDR or center/edge-aligned SDR source synchronous input channel
//
// this implements:
//     incoming source-synchronous capture flops
//     async fifo to go from source-synchronous domain to core domain
//     outgoing token channel to go from core domain deque to out of chip
//     outgoing source-synchronous launch flops for token
//
// note, the default FIFO depth is set to 2^6 based on experiments on FPGA
// Below is a rough calculation:
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
// This leaves us with 45 elements of margin
// for FPGA inefficiency. Since the FPGA may run
// at 4X slower, this is equivalent to 3 FPGA cycles.
//
// Aside: SERDES make bandwidth-delay product much worse
// because they simultaneously increase bandwidth and delay!
//
// io_*: signals synchronous to io_clk_i
// core_*: signals synchronous to core_clk_i
//

module bsg_link_source_sync_downstream 

 #(parameter channel_width_p                 = 16
  ,parameter lg_fifo_depth_p                 = 6
  ,parameter lg_credit_to_token_decimation_p = 3
  
  // Reset pattern is 0xF*
  // This is a soft reset from link_upstream to link_downstream
  // When channel data bits are in reset pattern, downstream link is on reset
  // Note that this pattern must be the same for upstream and downstream links
  
  ,parameter reset_pattern_p = {channel_width_p {1'b1}}
  )
  
  (// control signals
   input                        core_clk_i
  ,input                        core_link_reset_i

  // source synchronous input channel; coming from chip edge
  ,input                        io_clk_i     // sdi_sclk
  ,input  [channel_width_p-1:0] io_data_i    // sdi_data
  ,input                        io_valid_i   // sdi_valid
  ,output                       io_token_r_o // sdi_token; output registered

  // going into core; uses core clock
  ,output [channel_width_p-1:0] core_data_o
  ,output                       core_valid_o
  ,input                        core_yumi_i
  );
  
  
  // local reset from core clock to io clock
  logic io_reset_lo;
  
  bsg_launch_sync_sync 
 #(.width_p(1)
  ) local_reset_lss
  (.iclk_i      (core_clk_i)
  ,.iclk_reset_i(1'b0)
  ,.oclk_i      (io_clk_i)
  ,.iclk_data_i (core_link_reset_i)
  ,.iclk_data_o ()
  ,.oclk_data_o (io_reset_lo)
  );
  
     
  // internal reset signal
  logic core_link_internal_reset_lo;
  logic io_link_internal_reset_n, io_link_internal_reset_lo;
  
  // Soft reset signal coming from bsg_link_source_sync_upstream
  assign io_link_internal_reset_n = (io_data_i==reset_pattern_p && ~io_valid_i);
  
  // Actual reset = remote_soft_reset | local_core_link_reset
  // This is very useful when a link channel is left unused or physical IO
  // pins are left floating (remote reset not available in these cases)
  bsg_launch_sync_sync 
 #(.width_p(1)
  ) internal_reset_lss
  (.iclk_i      (io_clk_i)
  ,.iclk_reset_i(1'b0)
  ,.oclk_i      (core_clk_i)
  ,.iclk_data_i (io_link_internal_reset_n | io_reset_lo)
  ,.iclk_data_o (io_link_internal_reset_lo)
  ,.oclk_data_o (core_link_internal_reset_lo)
  );
                                 

   // ******************************************
   // clock-crossing async fifo (with DDR interface)
   //
   // Note that this async fifo also serves as receive buffer
   // The buffer size depends on lg_fifo_depth_p (must match bsg_link_source_sync_upstream)
   //
   // With token based flow control, fifo should never overflow
   // io_async_fifo_full signal is only for debugging purposes
   //

   wire   io_async_fifo_full;
   wire   io_async_fifo_enq = io_valid_i; // enque if either valid bit set

   // synopsys translate_off

   always_ff @(negedge io_clk_i)
     assert(!(io_async_fifo_full===1 && io_async_fifo_enq===1))
       else $error("attempt to enque on full async fifo");

   // synopsys translate_on


   wire   core_actual_deque;
   wire   core_valid_o_tmp;
   logic [channel_width_p-1:0]   core_data_lo;

  bsg_async_fifo 
 #(.lg_size_p(lg_fifo_depth_p)
  ,.width_p(channel_width_p)
  ) baf
  (.w_clk_i  (io_clk_i)
  ,.w_reset_i(io_link_internal_reset_lo)
  
  ,.w_enq_i  (io_async_fifo_enq)
  ,.w_data_i (io_data_i)
  ,.w_full_o (io_async_fifo_full)

  ,.r_clk_i  (core_clk_i)
  ,.r_reset_i(core_link_internal_reset_lo)

  ,.r_deq_i  (core_actual_deque)
  ,.r_data_o (core_data_lo)
  ,.r_valid_o(core_valid_o_tmp));


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
  bsg_two_fifo 
 #(.width_p(channel_width_p)
  ) twofer
  (.clk_i  (core_clk_i)
  ,.reset_i(core_link_internal_reset_lo)

  // we feed this into the local yumi, but only if it is valid
  ,.ready_o(core_twofer_ready)
  ,.data_i (core_data_lo)
  ,.v_i    (core_valid_o_pre_twofer)

  ,.v_o    (core_valid_o)
  ,.data_o (core_data_o)
  ,.yumi_i (core_yumi_i)
  );


   // a word was transferred to the two input fifo if ...
   wire core_transfer_success = core_valid_o_tmp & core_twofer_ready;
   assign core_actual_deque = core_transfer_success;


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
    ,.w_reset_i(core_link_internal_reset_lo)
    ,.w_inc_i  (core_transfer_success)
    ,.r_clk_i  (io_clk_i)
    ,.w_ptr_binary_r_o() // not needed
    ,.w_ptr_gray_r_o()   // not needed
    ,.w_ptr_gray_r_rsync_o(core_credits_gray_r_iosync)
    );

   // this logic allows us to return two credits at a time
   // note: generally relies on power-of-twoness of io_credits_sent_r
   // to do correct wrap around.

   assign io_credits_sent_r_p1 = io_credits_sent_r + (lg_fifo_depth_p+1)'(1);
   assign io_credits_sent_r_p2 = io_credits_sent_r + (lg_fifo_depth_p+1)'(2);

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

   always_ff @(posedge io_clk_i)
     begin
        if (io_link_internal_reset_lo)
          io_credits_sent_r <= { lg_fifo_depth_p+1 { 1'b0 } };
        else
          // we absorb up to two credits per cycles, since we receive at DDR,
          // we need this to rate match the incoming data

      // code is written like this because empty_1 is late relative to empty_0
          io_credits_sent_r <= (empty_1
                                ? (empty_0 ? io_credits_sent_r_p2 : io_credits_sent_r)
                                : (empty_0 ? io_credits_sent_r_p1 : io_credits_sent_r));
     end

endmodule // bsg_source_sync_input