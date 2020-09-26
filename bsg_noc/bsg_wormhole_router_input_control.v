`include "bsg_defines.v"

module bsg_wormhole_router_input_control #(parameter output_dirs_p=-1, parameter payload_len_bits_p=-1)
   (input clk_i
    , input reset_i
    , input fifo_v_i
    , input [output_dirs_p-1:0]      fifo_decoded_dest_i
    , input [payload_len_bits_p-1:0] fifo_payload_len_i

    // a word was sent by the output channel
    , input fifo_yumi_i

    // a wire is high only if there is a header flit at the head of the fifo
    // that is targeted to the output channel
    // only a single wire can be high

    , output [output_dirs_p-1:0] reqs_o

    // we transferred all of the words on the previous cycle
    , output release_o

    , output detected_header_o
    );

   wire [payload_len_bits_p-1:0] payload_ctr_r;
   wire                       counter_expired    = (!payload_ctr_r);
   wire                       fifo_has_hdr = counter_expired & fifo_v_i;

   bsg_counter_set_down #(.width_p(payload_len_bits_p), .set_and_down_exclusive_p(1'b1)) ctr
   (.clk_i
    ,.reset_i
    ,.set_i    (fifo_yumi_i & counter_expired)   // somebody accepted our header
                                                // note: reset puts the counter in expired state
    ,.val_i    (fifo_payload_len_i)
    ,.down_i   (fifo_yumi_i & ~counter_expired) // we decrement if somebody grabbed a word and it was not a header
    ,.count_r_o(payload_ctr_r)                  // decrement after we no longer have a header
    );

   assign reqs_o    = fifo_has_hdr ? fifo_decoded_dest_i : '0;
   assign release_o = counter_expired;
   assign detected_header_o = fifo_has_hdr;

endmodule
