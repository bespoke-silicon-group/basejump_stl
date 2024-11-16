`include "bsg_defines.sv"

// This module is primarily used by the wormhole router, but can also be used 
// as an endpoint decoder with output_dirs_p=1, fifo_decoder_dest_i = '0, and reqs_o ignored, and release_o
// signaling the end of the packet.

module bsg_wormhole_router_input_control #(parameter `BSG_INV_PARAM(output_dirs_p), parameter `BSG_INV_PARAM(payload_len_bits_p))
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

`BSG_ABSTRACT_MODULE(bsg_wormhole_router_input_control)
