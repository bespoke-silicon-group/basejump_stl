// MBT  7/7/16
//
// This implements channel tunneling. Effectively, it is like virtual channels
// except that it includes credits as part of the channels, and it does not
// require the virtual channels to demultiplex at every step. Finally, especially
// when crossing chip boundaries, we can aggregrate the FIFO space into a single
// large FIFO which is more efficient per bit than many smaller FIFOs.
//
// 1. remote_credits_p typical set to 2X bandwidth delay product of link
//
//    ASIC<->ASIC
//
//    e.g. if the core frequency is 1000 MHz, and the off-chip frequency
//    is 300 MHz, and the off-chip link is 0.4 word/cycle, and the 1-way latency
//    in the core domain is 5 cycles, and the latency in the off-chip
//    domain is 10 cycles, then:
//
//    one-way chip latency = 5 * 1 ns + 10 * 3.3 ns = 38.3 ns
//    bandwidth            = 0.4 words / 3.33 ns    = .133 words / ns
//    bandwidth * delay    = .133 * 35 = 4.6 words
//
//    * 2 ASICS            = 9.2  words
//    * 2 (roundtrip)      = 18.4 words
//
//    ASIC<->FPGA
//
//    note, if there is an FPGA in the loop, then latencies blow up.
//    suppose the FPGA runs at 300*.4 = 120 Mhz=8.3ns, and so the on-FPGA latency
//    is 38.3 * (8.3) = 314 ns. then one way latency is 352 ns, and buffering is
//    (.133 * (352))*2 = 93 words.
//
// 2. area grows as num_in_p * remote_credits_p
//
//
// 3. area for all channels can be stored in a single place when using alternate
//    implementations of virtual fifos
//

module bsg_channel_tunnel #(parameter width_p        = 1
                            , num_in_p               = "inv"
                            , remote_credits_p       = "inv"
                            , lg_credit_decimation_p = 4
                            , tag_width_lp           = $clog2(num_in_p+1)
                            , tagged_width_lp        = tag_width_lp + width_p
                            , lg_remote_credits_lp   = $clog2(remote_credits_p+1)
                            )
   (input clk_i
    ,input reset_i

    // incoming multiplexed data
    ,input  [tagged_width_lp-1:0]  multi_data_i
    ,input  multi_valid_i
    ,output multi_yumi_o

    // outgoing multiplexed data
    , output [tagged_width_lp-1:0] multi_data_o
    , output multi_valid_o
    , input  multi_yumi_i

    // incoming demultiplexed data
    , input  [num_in_p-1:0][width_p-1:0] data_i
    , input  [num_in_p-1:0] valid_i
    , output [num_in_p-1:0] yumi_o

    // outgoing demultiplexed data
    , output [num_in_p-1:0][width_p-1:0] data_o
    , output [num_in_p-1:0]             valid_o
    , input  [num_in_p-1:0]              yumi_i
    );


   wire [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_local_return_data_oi;
   wire                                          credit_local_return_v_oi;

   wire [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_remote_return_data_oi;
   wire                                          credit_remote_return_yumi_io;


   bsg_channel_tunnel_out #(.width_p                (width_p)
                            ,.num_in_p              (num_in_p)
                            ,.remote_credits_p      (credits_p)
                            ,.lg_credit_decimation_p(lg_credit_decimation_p)
                            ) bcto
     (.clk_i
      ,.reset_i

      ,.data_i
      ,.valid_i
      ,.yumi_o

      ,.data_o (multi_data_o )
      ,.valid_o(multi_valid_o)
      ,.yumi_i (multi_yumi_i )

      ,.credit_local_return_data_i (credit_local_return_data_oi )
      ,.credit_local_return_v_i    (credit_local_return_v_oi    )
      ,.credit_remote_return_data_i(credit_remote_return_data_oi)
      ,.credit_remote_return_yumi_o(credit_remote_return_yumi_io)
      );

   bsg_channel_tunnel_in #(.width_p                (width_p  )
                           ,.num_in_p              (num_in_p )
                           ,.remote_credits_p      (credits_p)
                           ,.lg_credit_decimation_p(lg_credit_decimation_p)
                           ) bcti
     (.clk_i
      ,.reset_i

      ,.data_i (multi_data_i )
      ,.valid_i(multi_valid_i)
      ,.yumi_o (multi_yumi_o )

      ,.data_o
      ,.valid_o
      ,.yumi_i

      ,.credit_local_return_data_o (credit_local_return_data_oi )
      ,.credit_local_return_v_o    (credit_local_return_v_oi    )
      ,.credit_remote_return_data_o(credit_remote_return_data_oi)
      ,.credit_remote_return_yumi_i(credit_remote_return_yumi_io)
      );

endmodule


