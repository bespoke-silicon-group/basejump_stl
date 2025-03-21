`include "bsg_defines.sv"

// This module parses a packet as it comes in from a fifo
// indicating where the first and last flits are
//
// A typical use case is to build an endpoint for a wormhole network
// which might deque the header (first flit) and put it in a register
// or fifo, and then deque some data words and process them in a streaming
// fashion rather than reading out the entire packet into a wide register, such
// as done in bsg_wormhole_router_adapter_out.
//
// Another common pattern is to use a bsg_serial_in_parallel_out_fifo_full or
// bsg_serial_in_parallel_out_fifo_passthrough if the header info is more than 1 flit
// or if the data words are going to get paired up for a wide write into a memory or
// wide processing.

module bsg_wormhole_router_packet_parser #(parameter `BSG_INV_PARAM(payload_len_bits_p))
   (input clk_i
    , input reset_i
    , input fifo_v_i
    , input [payload_len_bits_p-1:0] fifo_payload_len_i

    // this cycle's word was requested to deque
    , input fifo_yumi_i

    // if fifo_v_i is high, it is a header
    , output expecting_header_r_o
    );

  bsg_wormhole_router_input_control #(.output_dirs_p(1)
                                      ,.payload_len_bits_p(payload_len_bits_p)
                                     ) ic
  (.clk_i(clk_i)
  ,.reset_i(reset_i)
  ,.fifo_v_i(fifo_v_i)
  ,.fifo_decoded_dest_i(1'b0)
  ,.fifo_payload_len_i(fifo_payload_len_i)
  ,.fifo_yumi_i(fifo_yumi_i)
  ,.reqs_o()
   ,.release_o(expecting_header_r_o)
  );

endmodule

`BSG_ABSTRACT_MODULE(bsg_wormhole_router_packet_parser)
