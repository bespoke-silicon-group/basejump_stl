//
// Prof. Taylor   7/24/2014
// <prof.taylor@gmail.com>
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
// FIXME: update these numbers based on clocks in each clock domain and from actual waveforms.
//
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

`include "bsg_defines.sv"

module bsg_link_source_sync_downstream 

 #(parameter channel_width_p                 = 16
  ,parameter lg_fifo_depth_p                 = 6
  ,parameter lg_credit_to_token_decimation_p = 3
  // When the async_fifo is not on critical path (e.g. when async_fifo size
  // is small), bypass twofer fifo to minimize buffering and latency
  ,parameter bypass_twofer_fifo_p            = 0
  ,parameter use_hardened_fifo_p             = 0
  )
  
  (// control signals
   input                        core_clk_i
  ,input                        core_link_reset_i
  ,input                        io_link_reset_i

  // coming from IDDR PHY near the physical I/O. valid_i and data_i signals are assumed to be
  // registered, but may be traversing long wires on the top level to reach this module.
  ,input                        io_clk_i       // sdi_sclk
  ,input  [channel_width_p-1:0] io_data_i      // sdi_data
  ,input                        io_valid_i     // sdi_valid
  ,output                       core_token_r_o // sdi_token; output registered

  // going into core; uses core clock
  ,output [channel_width_p-1:0] core_data_o
  ,output                       core_valid_o
  ,input                        core_yumi_i
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

   wire  io_async_fifo_full, io_async_fifo_enq;
   logic io_fifo_ready_lo;
   logic [channel_width_p-1:0] io_async_fifo_data;

`ifndef BSG_HIDE_FROM_SYNTHESIS

   always_ff @(negedge io_clk_i)
     assert(!(io_fifo_ready_lo===0 && io_valid_i===1))
       else $error("attempt to enque on full async fifo");

`endif

  if (use_hardened_fifo_p == 0)
  begin
    assign io_async_fifo_enq  = io_valid_i;
    assign io_async_fifo_data = io_data_i;
    assign io_fifo_ready_lo   = ~io_async_fifo_full;
  end
  else
  begin: harden
    logic io_fifo_valid_lo;
    assign io_async_fifo_enq  = io_fifo_valid_lo & ~io_async_fifo_full;
    bsg_fifo_1r1w_small
   #(.width_p (channel_width_p)
    ,.els_p   (1<<lg_fifo_depth_p)
    ,.harden_p(1)
    ) fifo
    (.clk_i   (io_clk_i)
    ,.reset_i (io_link_reset_i)
    ,.v_i     (io_valid_i)
    ,.ready_param_o (io_fifo_ready_lo)
    ,.data_i  (io_data_i)
    ,.v_o     (io_fifo_valid_lo)
    ,.data_o  (io_async_fifo_data)
    ,.yumi_i  (io_async_fifo_enq)
    );
  end

   wire  core_async_fifo_deque, core_async_fifo_valid_lo;
   logic [channel_width_p-1:0] core_async_fifo_data_lo;

  bsg_async_fifo 
 #(.lg_size_p((use_hardened_fifo_p==0)?lg_fifo_depth_p:3)
  ,.width_p(channel_width_p)
  ) baf
  (.w_clk_i  (io_clk_i)
  ,.w_reset_i(io_link_reset_i)
  
  ,.w_enq_i  (io_async_fifo_enq)
  ,.w_data_i (io_async_fifo_data)
  ,.w_full_o (io_async_fifo_full)

  ,.r_clk_i  (core_clk_i)
  ,.r_reset_i(core_link_reset_i)

  ,.r_deq_i  (core_async_fifo_deque)
  ,.r_data_o (core_async_fifo_data_lo)
  ,.r_valid_o(core_async_fifo_valid_lo));


  if (bypass_twofer_fifo_p == 0)
  begin

   wire core_async_fifo_ready_li;

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
  ,.reset_i(core_link_reset_i)

  // we feed this into the local yumi, but only if it is valid
  ,.ready_param_o (core_async_fifo_ready_li)
  ,.data_i        (core_async_fifo_data_lo)
  ,.v_i           (core_async_fifo_valid_lo)

  ,.v_o           (core_valid_o)
  ,.data_o        (core_data_o)
  ,.yumi_i        (core_yumi_i)
  );

   // a word was transferred to fifo if ...
   assign core_async_fifo_deque = core_async_fifo_valid_lo & core_async_fifo_ready_li;

  end
  else
  begin
    // keep async_fifo isolated when reset is asserted
    assign core_valid_o = (core_link_reset_i)? 1'b0 : core_async_fifo_valid_lo;
    assign core_data_o = core_async_fifo_data_lo;
    assign core_async_fifo_deque = core_yumi_i;
  end


// **********************************************
// credit return
//
// these are credits coming from the receive end of the async fifo in the core clk
//  domain and passing to the io clk domain and out of the chip.
//

  logic [lg_credit_to_token_decimation_p+1-1:0] core_credits_sent_r;
  
  // which bit of the core_credits_sent_r counter we use determines
  // the value of the token line in credits
  //
  //
  // this signal's register should be placed right next to the I/O pad:
  //   glitch sensitive.
  
  assign core_token_r_o = core_credits_sent_r[lg_credit_to_token_decimation_p];
  
  // Increase token counter when dequeue from async fifo
  bsg_counter_clear_up 
 #(.max_val_p({(lg_credit_to_token_decimation_p+1){1'b1}})
  ,.init_val_p(0)
  ,.disable_overflow_warning_p(1) // Allow overflow for this counter
  )
  token_counter
  (.clk_i  (core_clk_i)
  ,.reset_i(core_link_reset_i)
  ,.clear_i(1'b0)
  ,.up_i   (core_async_fifo_deque)
  ,.count_o(core_credits_sent_r)
  );

endmodule // bsg_source_sync_input
