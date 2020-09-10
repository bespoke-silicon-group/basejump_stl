// MBT 8-18-2014
//
// BSG Assembler In (Channels --> Ring)
//
// prefer ready_o to yumi_o
// prefer yumi_i to ready_i
//
// takes a number of input channels and
// round-robin assemblers them into a single
// wide channel.
//
// most of the heavy lifting is done by
// bsg_round_robin_fifo_to_fifo. this module
// places a set of fifos between the wide channel
// and the bsg_round_robin_fifo_to_fifo to support
// atomic deque of an entire wide channel at a time.
//
//

`include "bsg_defines.v"

module bsg_assembler_in #(parameter width_p="inv"
                           ,parameter num_in_p="inv"
                           ,parameter num_out_p="inv"
                           ,parameter in_channel_count_mask_p=(1 << (num_in_p-1)))
   (input clk
    , input  reset
    , input  calibration_done_i
    , input         [num_in_p-1:0] valid_i
    , input         [width_p-1 :0] data_i [num_in_p]
    , output        [num_in_p-1:0] yumi_o

    // i.e. if we have 4 active channels, input 3
    , input         [`BSG_MAX(0,$clog2(num_in_p)-1):0]  in_top_channel_i
    , input         [`BSG_MAX(0,$clog2(num_out_p)-1):0] out_top_channel_i

    , output                          valid_o
    , output  [num_out_p*width_p-1:0] data_o
    , input                           yumi_i

    );

   wire [num_out_p-1:0] fifo_enq_vec, fifo_not_full_vec, fifo_valid_vec;
   wire [width_p-1:0]   fifo_data_vec [num_out_p-1:0];

   bsg_round_robin_fifo_to_fifo #(.width_p(width_p)
                                  ,. num_in_p(num_in_p)
                                  ,. num_out_p(num_out_p)
                                  ,. in_channel_count_mask_p(in_channel_count_mask_p)
                                  ) rr_fifo_to_fifo
     (.clk(clk)
      ,.reset(reset)
      ,.valid_i(valid_i & { num_in_p {calibration_done_i } })
      ,.data_i(data_i)
      ,.yumi_o(yumi_o)

      ,.in_top_channel_i(in_top_channel_i)
      ,.out_top_channel_i(out_top_channel_i)
      ,.valid_o(fifo_enq_vec)
      ,.data_o(fifo_data_vec)
      ,.ready_i(fifo_not_full_vec)
      );

   genvar               i;

   // generate fifos to hold words of input packet

   for (i = 0; i < num_out_p; i=i+1)
     begin : fifos
        bsg_two_fifo #(.width_p(width_p)) ring_packet_fifo
            (.clk_i   (clk)
             ,.reset_i(reset)

             // input side
             ,.ready_o(fifo_not_full_vec[i])
             ,.v_i    (fifo_enq_vec     [i])
             ,.data_i (fifo_data_vec    [i])

             // output side
             ,.v_o    (fifo_valid_vec   [i]      )
             ,.data_o (data_o[width_p*i+:width_p])
             ,.yumi_i (yumi_i                    )
             );

     end // for (i = 0; i < num_in_p; i=i+1)

   assign valid_o = (& fifo_valid_vec) & calibration_done_i;

endmodule // bsg_assembler_in

