// MBT  7/7/16
//
// bsg_channel_tunnel
//
// This module allows you to multiplex multiple streams over a shared
// interconnect without having deadlock occur because of stream interleaving.
//
// There are three models for interleaving streams:
//
// a. Your stream is guaranteed to be sunk by the remote node without
//    dependence on external factors, and does not rely upon back pressure.
//    In this case you avoid deadlock but may have fairness issues. Here, you
//    attach directly to the shared interconnect (e.g. bsg_fsb).
//
// b. Your streams rely upon back pressure from the remote node. Here, you
//    can use multiple bsg_channel_tunnel modules, one for each stream.
//    This ensures that you do not deadlock, but it does not address unfairness
//    in the interconnect that may lead to starvation.
//
// c. Your stream rely upon back pressure from the remote node. In this
//    scenario, you use one bsg_channel_tunnel across multiple streams.
//    Within this group of streams, you will have round-robin fairness.
//
// Channel tunneling is like virtual channels except that it includes
// credits as part of the channels, and it does not
// require the virtual channels to demultiplex at every step.
//
// Finally, especially when crossing chip boundaries (and using case c),
// we can aggregrate the FIFO space into a single
// large FIFO which is more efficient per bit than many smaller FIFOs.
//
// 1. remote_credits_p is the number of buffered words per channel. Budget the
//    round-trip bandwidth-delay product plus D = 2**lg_credit_decimation_p:
//      remote_credits_p >= ceil(R * round_trip_latency_cycles) + D.
//    See the latency definition and assumptions below. These examples assume
//    one channel uses the full link bandwidth and omit any additional delays.
//
//    ASIC<->ASIC
//
//    e.g. if the core frequency is 1000 MHz, and the off-chip frequency
//    is 300 MHz, and the off-chip link is 0.4 word/cycle, and the 1-way latency
//    in the core domain is 5 cycles, and the latency in the off-chip
//    domain is 10 cycles, then:
//
//    one-way chip latency = 5 * 1 ns + 10 * (10/3) ns = 38.33 ns
//    bandwidth            = 0.4 words / (10/3) ns    = 0.12 words/ns
//    round-trip latency   = 2 ASICs * 2 directions * 38.33 ns = 153.33 ns
//
//    remote_credits_p >= ceil(0.12 * 153.33) + D = 19 + D words per channel.
//
//    ASIC<->FPGA
//
//    An FPGA can increase the latency. For example, with a 314 ns one-way
//    FPGA path and the 38.33 ns ASIC path above, the round-trip latency is
//    2 * (314 + 38.33) = 704.66 ns. At the same 0.12 words/ns link bandwidth:
//    remote_credits_p >= ceil(0.12 * 704.66) + D = 85 + D words per channel.
//
// 2. area grows as num_in_p * remote_credits_p
//
//
// 3. area for all channels can be stored in a single place when using alternate
//    implementations of virtual fifos
//

`include "bsg_defines.sv"

// The credit return threshold is D = 2**lg_credit_decimation_p words per channel.
// To avoid credit-induced throttling at one word/cycle, use
//   remote_credits_p >= round_trip_latency_cycles + D.
// The round-trip latency includes data transit, receiver consumption, and
// credit-return arbitration/transit, excluding batching and the sender's
// one-cycle processing of the returned credit: (D-1) + 1 = D extra cycles.
// For per-channel rates R <= 1 word/cycle, a conservative budget is
//   remote_credits_p >= ceil(R * round_trip_latency_cycles) + D.
// Use worst-case latency and account for traffic bursts.

module bsg_channel_tunnel #(parameter width_p        = 1
                            , parameter `BSG_INV_PARAM(num_in_p)
                            , parameter `BSG_INV_PARAM(remote_credits_p)
                            , use_pseudo_large_fifo_p = 0
                            , harden_small_fifo_p    = 0
                            , lg_remote_credits_lp   = $clog2(remote_credits_p+1)
                            , parameter `BSG_INV_PARAM(lg_credit_decimation_p)
                            , tag_width_lp           = $clog2(num_in_p+1)
                            , tagged_width_lp        = tag_width_lp + width_p

                            )
   (input clk_i
    ,input reset_i

    // incoming multiplexed data
    ,input  [tagged_width_lp-1:0]  multi_data_i
    ,input  multi_v_i
    ,output multi_yumi_o

    // outgoing multiplexed data
    , output [tagged_width_lp-1:0] multi_data_o
    , output multi_v_o
    , input  multi_yumi_i

    // incoming demultiplexed data
    , input  [num_in_p-1:0][width_p-1:0] data_i
    , input  [num_in_p-1:0] v_i
    , output [num_in_p-1:0] yumi_o

    // outgoing demultiplexed data
    , output [num_in_p-1:0][width_p-1:0] data_o
    , output [num_in_p-1:0]             v_o
    , input  [num_in_p-1:0]              yumi_i
    );

   // Require 1 <= 2**lg_credit_decimation_p <= remote_credits_p.
   // Shift the credit count to avoid overflowing a left-shifted literal.
   `BSG_ELAB_CHECK((remote_credits_p > 0)
                  && (lg_credit_decimation_p >= 0)
                  && ((remote_credits_p >> lg_credit_decimation_p) > 0)
                  ,$error("bsg_channel_tunnel: bad params; remote_credits_p=%0d cannot support lg_credit_decimation_p=%0d"
                          ,remote_credits_p,lg_credit_decimation_p))

   `BSG_ELAB_CHECK(width_p >= num_in_p*lg_remote_credits_lp
                  ,$error("bsg_channel_tunnel: bad params; channel width (%0d) must be at least wide enough to route back credits (%0d)"
                          ,width_p,num_in_p*lg_remote_credits_lp))

   wire [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_local_return_data_oi;
   wire                                          credit_local_return_v_oi;

   wire [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_remote_return_data_oi;
   wire                                          credit_remote_return_yumi_io;


   bsg_channel_tunnel_out #(.width_p                (width_p)
                            ,.num_in_p              (num_in_p)
                            ,.remote_credits_p      (remote_credits_p)
                            ,.lg_credit_decimation_p(lg_credit_decimation_p)
                            ) bcto
     (.clk_i
      ,.reset_i

      ,.data_i
      ,.v_i
      ,.yumi_o

      ,.data_o (multi_data_o )
      ,.v_o(multi_v_o)
      ,.yumi_i (multi_yumi_i )

      ,.credit_local_return_data_i (credit_local_return_data_oi )
      ,.credit_local_return_v_i    (credit_local_return_v_oi    )
      ,.credit_remote_return_data_i(credit_remote_return_data_oi)
      ,.credit_remote_return_yumi_o(credit_remote_return_yumi_io)
      );

   bsg_channel_tunnel_in #(.width_p                (width_p  )
                           ,.num_in_p              (num_in_p )
                           ,.remote_credits_p      (remote_credits_p)
                           ,.use_pseudo_large_fifo_p(use_pseudo_large_fifo_p)
                           ,.harden_small_fifo_p   (harden_small_fifo_p)
                           ,.lg_credit_decimation_p(lg_credit_decimation_p)
                           ) bcti
     (.clk_i
      ,.reset_i

      ,.data_i (multi_data_i )
      ,.v_i    (multi_v_i)
      ,.yumi_o (multi_yumi_o )

      ,.data_o
      ,.v_o
      ,.yumi_i

      ,.credit_local_return_data_o (credit_local_return_data_oi )
      ,.credit_local_return_v_o    (credit_local_return_v_oi    )
      ,.credit_remote_return_data_o(credit_remote_return_data_oi)
      ,.credit_remote_return_yumi_i(credit_remote_return_yumi_io)
      );

endmodule

`BSG_ABSTRACT_MODULE(bsg_channel_tunnel)


