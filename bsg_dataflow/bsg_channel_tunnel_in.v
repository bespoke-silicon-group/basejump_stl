
// MBT 7-2-2016
//
// takes N channels and tunnels them, with credit flow control.
// will work even if you have only a single channel.
//
// SV_gripe "output parameters" would make this implementation nicer
//           vector parameters would be very useful as well

`include "bsg_defines.v"

module bsg_channel_tunnel_in #(parameter width_p = -1
                               , num_in_p = "inv"
                               , remote_credits_p = "inv"
                               , use_pseudo_large_fifo_p = 0

                               // determines when we send out credits remotely
                               // and consequently how much bandwidth is used on credits
                               , lg_credit_decimation_p = 4

                               , tag_width_lp           = $clog2(num_in_p+1)
                               , tagged_width_lp        = tag_width_lp+width_p
                               , lg_remote_credits_lp   = $clog2(remote_credits_p+1)
                               )
   (input  clk_i
    , input  reset_i

    // to downstream
    , input  [tagged_width_lp-1:0] data_i
    , input  v_i
    , output yumi_o

    // to outgoing channels (v/r)
    , output [num_in_p-1:0][width_p-1:0] data_o
    , output [num_in_p-1:0]             v_o
    , input  [num_in_p-1:0]              yumi_i

    // to bsg_channel_tunnel_out; returning credits to them; they always accept
    , output [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_local_return_data_o
    , output credit_local_return_v_o

    // to bsg_channel_tunnel_out; return credits to remote side
    // always v

    , output [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_remote_return_data_o

    // bsg_channel_tunnel sent all of the pending credits out
    , input credit_remote_return_yumi_i
    );

   // always ready to deque credit_ready
   logic credit_v_lo;
   logic [width_p-1:0] credit_data_lo;

   // demultiplex the packets.
   bsg_1_to_n_tagged_fifo #(.width_p            (width_p)
                            ,.num_out_p          (num_in_p+1      )
                            ,.els_p             (remote_credits_p)
                            // credit fifo is unbuffered
                            ,.unbuffered_mask_p (1 << num_in_p   )
                            ,.use_pseudo_large_fifo_p(use_pseudo_large_fifo_p)
                            )
   b1_ntf
     (.clk_i
      ,.reset_i

      ,.v_i   (v_i)
      ,.tag_i (data_i[width_p+:tag_width_lp])
      ,.data_i(data_i[0+:width_p])
      ,.yumi_o

      // v / ready
      ,.v_o     ( {credit_v_lo, v_o}  )
      ,.data_o  ( {credit_data_lo , data_o  } )

      // credit fifo is unbuffered, so no yumi signal
      ,.yumi_i  ( { 1'b0, yumi_i }            )
      );

   // route local credit return to bsg_channel_tunnel_out module
   assign credit_local_return_data_o = credit_data_lo[0+:num_in_p*lg_remote_credits_lp];
   assign credit_local_return_v_o    = credit_v_lo;

   // compute remote credit arithmetic
   wire [num_in_p-1:0] sent = v_o & yumi_i;

   genvar              i;

   // keep track of how many credits need to be send back
   for (i = 0; i < num_in_p; i=i+1)
     begin: rof
        bsg_counter_clear_up #(.max_val_p  (remote_credits_p)
                               ,.init_val_p(0)
                               ) ctr
            (.clk_i
             ,.reset_i
             ,.clear_i (credit_remote_return_yumi_i   )
             ,.up_i    (sent[i]                       )
             ,.count_o (credit_remote_return_data_o[i])
             );
     end

endmodule
