
// MBT 7-2-2016
//
// takes N channels and tunnels them, with credit flow control.
//
// SV "output parameters" would make this implementation nicer
//
//

`include "bsg_defines.v"

module bsg_channel_tunnel_out #(
                                parameter `BSG_INV_PARAM(width_p)
                                ,parameter `BSG_INV_PARAM(num_in_p)
                                ,parameter `BSG_INV_PARAM(remote_credits_p)
                                ,parameter num_credit_channels_p = 1

                                // determines when we send out credits remotely
                                , lg_credit_decimation_p = 4

                                , tag_width_lp        = $clog2(num_in_p+num_credit_channels_p)
                                , tagged_width_lp     = tag_width_lp+width_p
                                , lg_remote_credits_lp = $clog2(remote_credits_p+1)
                                , credit_channel_width_lp = lg_remote_credits_lp * `BSG_CDIV(num_in_p, num_credit_channels_p)
                                )
   (input  clk_i
    , input  reset_i

    // to fifos
    , input  [num_in_p-1:0][width_p-1:0] data_i
    , input  [num_in_p-1:0] v_i
    , output [num_in_p-1:0] yumi_o

    // to downstream
    , output [tagged_width_lp-1:0] data_o
    , output v_o
    , input  yumi_i

    // from bsg_channel_tunnel_in; returning credits to us; we always accept
    , input [num_credit_channels_p-1:0][credit_channel_width_lp-1:0] credit_local_return_data_i
    , input [num_credit_channels_p-1:0] credit_local_return_v_i

    // from bsg_channel_tunnel_in; return credits to remote side
    // always v

    , input [num_credit_channels_p-1:0][credit_channel_width_lp-1:0] credit_remote_return_data_i

    // yep, we sent all of the credits out
    , output [num_credit_channels_p-1:0] credit_remote_return_yumi_o
    );

   // synopsys translate_off
   initial
     begin
        assert(remote_credits_p >= (1 << lg_credit_decimation_p))
          else $error("%m remote_credits_p is smaller than credit decimation factor!");
     end
   // synopsys translate_on

   genvar i;

   logic [num_in_p-1:0][lg_remote_credits_lp-1:0] local_credits;
   logic [num_in_p-1:0]                           local_credits_avail;
   logic [num_credit_channels_p-1:0]              remote_credits_avail;
   logic [num_credit_channels_p-1:0]              credit_v_li;
   logic [num_credit_channels_p-1:0][width_p-1:0] credit_remote_return_data_li;

   for (i = 0; i < num_in_p; i=i+1)
     begin: rof
        localparam ch = i / (credit_channel_width_lp/lg_remote_credits_lp);
        localparam b  = i % (credit_channel_width_lp/lg_remote_credits_lp);
        bsg_counter_up_down_variable #(.max_val_p  (remote_credits_p)
                                       ,.init_val_p(remote_credits_p)
                                       ,.max_step_p(remote_credits_p)
                                       ) bcudv
        (.clk_i
         ,.reset_i

         // credit return
         ,.up_i    ( credit_local_return_v_i[ch]
                     ? credit_local_return_data_i[ch][b*lg_remote_credits_lp+:lg_remote_credits_lp]
                     : (lg_remote_credits_lp ' (0))
                     )

         // sending
         ,.down_i  ( lg_remote_credits_lp '  (yumi_o  [i]) )
         ,.count_o (local_credits [i])
         );
        assign local_credits_avail [i] = |(local_credits[i]);
     end

   for (i = 0; i < num_credit_channels_p; i++)
     begin : rof2
        assign credit_remote_return_data_li[i] = credit_remote_return_data_i[i];
        assign remote_credits_avail[i]
               = | (credit_remote_return_data_li[i][credit_channel_width_lp-1:lg_credit_decimation_p]);
       assign credit_v_li[i] = | remote_credits_avail;
     end

   // we are going to round-robin choose between incoming channels,
   // adding a tag to the hi bits

   bsg_round_robin_n_to_1 #(.width_p  (width_p   )
                            ,.num_in_p(num_in_p+num_credit_channels_p)
                            ,.strict_p(0)
                            )
   rr
     (.clk_i
      ,.reset_i
      ,.data_i ({  credit_remote_return_data_li,  data_i  })

      // we present as v only if there are credits available to send
      ,.v_i    ({  credit_v_li,              v_i & local_credits_avail })
      ,.yumi_o ({  credit_remote_return_yumi_o,  yumi_o                        })

      ,.data_o (data_o[0+:width_p] )
      ,.tag_o  (data_o[width_p+:tag_width_lp])
      ,.v_o    (v_o)
      ,.yumi_i (yumi_i )
      );

endmodule

`BSG_ABSTRACT_MODULE(bsg_channel_tunnel_out)
