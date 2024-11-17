/**
 *  bsg_wormhole_router_adapter_in.sv
 *
 *  packet = {payload, length, cord}
 *
 *  Goes from a wide register containing an entire packet to a serialized packet.
 *  Most useful for testbenches, and in hardware, shorter packets where the data is
 *  not naturally serialized.
 */

`include "bsg_defines.sv"

`include "bsg_noc_links.svh"
`include "bsg_wormhole_router.svh"

module bsg_wormhole_router_adapter_in
  #(parameter `BSG_INV_PARAM(max_payload_width_p )
    , parameter `BSG_INV_PARAM(len_width_p       )
    , parameter `BSG_INV_PARAM(cord_width_p      )
    , parameter `BSG_INV_PARAM(flit_width_p      )

    , localparam bsg_ready_and_link_sif_width_lp =
        `bsg_ready_and_link_sif_width(flit_width_p)
    , localparam bsg_wormhole_packet_width_lp = 
        `bsg_wormhole_router_packet_width(cord_width_p, len_width_p, max_payload_width_p)
    )
   (input                                          clk_i
    , input                                        reset_i

    , input [bsg_wormhole_packet_width_lp-1:0]     packet_i
    , input                                        packet_v_i
    , output                                       packet_ready_and_o

    , output [flit_width_p-1:0]                    link_data_o
    , output                                       link_v_o
    , input                                        link_ready_and_i
    );

  `declare_bsg_wormhole_router_packet_s(cord_width_p, len_width_p, max_payload_width_p, bsg_wormhole_packet_s);
  bsg_wormhole_packet_s packet_cast_i;
  assign packet_cast_i = packet_i;

  localparam max_num_flits_lp = `BSG_CDIV($bits(bsg_wormhole_packet_s), flit_width_p);
  localparam protocol_len_lp  = `BSG_SAFE_CLOG2(max_num_flits_lp);
  wire [max_num_flits_lp*flit_width_p-1:0] packet_padded_li = packet_i;

  bsg_parallel_in_serial_out_dynamic
   #(.width_p(flit_width_p)
     ,.max_els_p(max_num_flits_lp)
     )
   piso
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.v_i(packet_v_i)
     ,.len_i(protocol_len_lp'(packet_cast_i.len))
     ,.data_i(packet_padded_li)
     ,.ready_and_o(packet_ready_and_o)

     ,.v_o(link_v_o)
     ,.len_v_o(/* unused */)
     ,.data_o(link_data_o)
     ,.yumi_i(link_ready_and_i & link_v_o)
     );

`ifndef BSG_HIDE_FROM_SYNTHESIS
  always_ff @(negedge clk_i)
    assert(reset_i || ~packet_v_i || (packet_cast_i.len <= max_num_flits_lp))
      else 
        $error("Packet received with len: %x > max_num_flits: %x", packet_cast_i.len, max_num_flits_lp);
`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_wormhole_router_adapter_in)
