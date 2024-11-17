/**
 *  bsg_wormhole_router_adapter_out.sv
 *
 *  packet = {payload, length, cord}
 *
 *  Basic module that deserializes an incoming wormhole packet into a wide register.
 *  This is especially useful for testbenches. (For hardware,
 *  full deserialization adds latency and area, this is often undesireable, but for
 *  small packets, it may make sense to use it.)
 */

`include "bsg_defines.sv"

`include "bsg_noc_links.svh"
`include "bsg_wormhole_router.svh"

module bsg_wormhole_router_adapter_out
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

    , input                                        link_v_i
    , input  [max_payload_width_p-1:0]             link_data_i
    , output                                       link_ready_and_o

    , output [bsg_wormhole_packet_width_lp-1:0]    packet_o
    , output                                       packet_v_o
    , input                                        packet_yumi_i
    );

  `declare_bsg_wormhole_router_header_s(cord_width_p, len_width_p, bsg_wormhole_header_s);
  bsg_wormhole_header_s header_li;
  assign header_li = link_data_i;

  `declare_bsg_wormhole_router_packet_s(cord_width_p,len_width_p,max_payload_width_p,bsg_wormhole_packet_s);

  localparam max_num_flits_lp = `BSG_CDIV($bits(bsg_wormhole_packet_s), flit_width_p);
  localparam protocol_len_lp  = `BSG_SAFE_CLOG2(max_num_flits_lp);
  logic [max_num_flits_lp*flit_width_p-1:0] packet_padded_lo;
  bsg_serial_in_parallel_out_dynamic
   #(.width_p(flit_width_p)
     ,.max_els_p(max_num_flits_lp)
     )
   sipo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(link_data_i)
     ,.len_i(protocol_len_lp'(header_li.len))
     ,.ready_and_o(link_ready_and_o)
     ,.len_ready_o(/* unused */)
     ,.v_i(link_v_i)

     ,.v_o(packet_v_o)
     ,.data_o(packet_padded_lo)
     ,.yumi_i(packet_yumi_i)
     );
  assign packet_o = packet_padded_lo[0+:bsg_wormhole_packet_width_lp];



`ifndef BSG_HIDE_FROM_SYNTHESIS
  logic recv_r;
  bsg_dff_reset_en
   #(.width_p(1))
   recv_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(link_v_i || packet_yumi_i)

     ,.data_i(link_v_i)
     ,.data_o(recv_r)
     );
  wire new_header_li = ~recv_r & link_v_i;

  // TODO: This assertion is buggy and fires erroneously
  //always_ff @(negedge clk_i)
  //  assert(reset_i || ~new_header_li || (header_li.len <= max_num_flits_lp))
  //    else 
  //      $error("Header received with len: %x > max_num_flits: %x", header_li.len, max_num_flits_lp);
`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_wormhole_router_adapter_out)

