// MBT 8-18-2014
//
// BSG Assembler Out (Ring --> Assembler)
//
// prefer ready_o to yumi_o
// prefer yumi_i to ready_i
//
//
// takes a single wide channel and strict round-robin
// distributes it across a number of input channels.
//
// most of the heavy lifting is done by
// bsg_round_robin_fifo_to_fifo. this module
// places a set of fifos between the wide channel
// and the bsg_round_robin_fifo_to_fifo to support
// partial dequeuing from the wide channel.
//

`include "bsg_defines.v"

module bsg_assembler_out #(parameter width_p    ="inv"
                           ,parameter num_in_p  ="inv"
                           ,parameter num_out_p ="inv"
                           ,parameter out_channel_count_mask_p=(1 << (num_out_p-1)))
   (input clk
    , input  reset
    , input  calibration_done_i
    , input  valid_i
    , input  [num_in_p*width_p-1:0] data_i
    , output ready_o                // more permissive than yumi_o

    , input         [`BSG_MAX($clog2(num_in_p)-1,0):0]  in_top_channel_i
    , input         [`BSG_MAX($clog2(num_out_p)-1,0):0] out_top_channel_i

    , output [num_out_p-1:0] valid_o
    , output [width_p-1:0]   data_o [num_out_p-1:0]
    , input  [num_out_p-1:0] ready_i  // we need to peek before deciding what to do.
    );

   wire [num_in_p-1:0]  fifo_valid_vec, fifo_not_full_vec, fifo_deq_vec;
   wire [width_p-1:0]   fifo_data_vec [num_in_p-1:0];

   wire ready_o_tmp = (& fifo_not_full_vec) & calibration_done_i;

   // enque if not fifo is full
   assign ready_o = ready_o_tmp;

   // generate fifos to hold words of input packet

   genvar               i;

   for (i = 0; i < num_in_p; i=i+1)
     begin : fifos
       bsg_two_fifo #(.width_p(width_p)
                      ,.ready_THEN_valid_p(1)
                      ) ring_packet_fifo
            (.clk_i   (clk)
             ,.reset_i(reset)

             // input side
             ,.ready_o(fifo_not_full_vec[i])
             ,.v_i    (valid_i & ready_o_tmp)
             ,.data_i (data_i[width_p*i+:width_p])

             // output side
             ,.v_o    (fifo_valid_vec[i])
             ,.data_o (fifo_data_vec [i])
             ,.yumi_i (fifo_deq_vec  [i])
             );
     end

   bsg_round_robin_fifo_to_fifo #(.width_p(width_p)
                                  ,. num_in_p(num_in_p)
                                  ,. num_out_p(num_out_p)
                                  ,. out_channel_count_mask_p(out_channel_count_mask_p)
                                  ) rr_fifo_to_fifo
     (.clk(clk)
      ,.reset(reset)
      ,.in_top_channel_i (in_top_channel_i)
      ,.out_top_channel_i(out_top_channel_i)
      ,.valid_i(fifo_valid_vec)
      ,.data_i(fifo_data_vec)
      ,.yumi_o(fifo_deq_vec)
      ,.valid_o(valid_o)
      ,.data_o(data_o)
      ,.ready_i(ready_i)
      );



endmodule // bsg_assembler_out

