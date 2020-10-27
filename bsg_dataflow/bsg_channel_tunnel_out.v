
// MBT 7-2-2016
//
// takes N channels and tunnels them, with credit flow control.
//
// SV "output parameters" would make this implementation nicer
//
//

`include "bsg_defines.v"

module bsg_channel_tunnel_out #(
                                parameter  width_p = -1
                                , num_in_p = "inv"
                                , remote_credits_p = "inv"

                                // determines when we send out credits remotely
                                , lg_credit_decimation_p = 4

                                , tag_width_lp        = $clog2(num_in_p+1)
                                , tagged_width_lp     = tag_width_lp+width_p
                                , lg_remote_credits_lp = $clog2(remote_credits_p+1)
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
    , input [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_local_return_data_i
    , input credit_local_return_v_i

    // from bsg_channel_tunnel_in; return credits to remote side
    // always v

    , input [num_in_p-1:0][lg_remote_credits_lp-1:0] credit_remote_return_data_i

    // yep, we sent all of the credits out
    , output credit_remote_return_yumi_o
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
   logic [num_in_p-1:0]                          local_credits_avail, remote_credits_avail;

   // the most scalable way to deal with the below issue is to add more "credit channels"
   // that transmit sections of the remote credits
   // but we'll wait until we run into that problem before we build it out

   // synopsys translate_off
   initial
      assert (width_p >= num_in_p*lg_remote_credits_lp)
        else $error("%m not enough room in packet to transmit all credit counters");
   // synopsys translate_on

   for (i = 0; i < num_in_p; i=i+1)
     begin: rof
        bsg_counter_up_down_variable #(.max_val_p  (remote_credits_p)
                                       ,.init_val_p(remote_credits_p)
                                       ,.max_step_p(remote_credits_p)
                                       ) bcudv
        (.clk_i
         ,.reset_i

         // credit return
         ,.up_i    ( credit_local_return_v_i
                     ? credit_local_return_data_i[i]
                     : (lg_remote_credits_lp ' (0))
                     )

         // sending
         ,.down_i  ( lg_remote_credits_lp '  (yumi_o  [i]) )
         ,.count_o (local_credits [i])
         );

        assign local_credits_avail [i] = |(local_credits[i]);
        assign remote_credits_avail[i]
               = | (credit_remote_return_data_i[i][lg_remote_credits_lp-1:lg_credit_decimation_p]);
     end

   wire credit_v_li = | remote_credits_avail;

   // we are going to round-robin choose between incoming channels,
   // adding a tag to the hi bits

   bsg_round_robin_n_to_1 #(.width_p  (width_p   )
                            ,.num_in_p(num_in_p+1)
                            ,.strict_p(0)
                            )
   rr
     (.clk_i
      ,.reset_i
      ,.data_i ({  width_p ' (credit_remote_return_data_i),  data_i  })

      // we present as v only if there are credits available to send
      ,.v_i    ({  credit_v_li,              v_i & local_credits_avail })
      ,.yumi_o ({  credit_remote_return_yumi_o,  yumi_o                        })

      ,.data_o (data_o[0+:width_p] )
      ,.tag_o  (data_o[width_p+:tag_width_lp])
      ,.v_o    (v_o)
      ,.yumi_i (yumi_i )
      );

endmodule
