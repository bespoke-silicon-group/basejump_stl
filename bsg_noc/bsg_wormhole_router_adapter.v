/**
 *  bsg_wormhole_router_adapter.v
 *
 *  This is a full duplex link to wormhole
 *
 *  packet = {payload, length, cord}
 */

`include "bsg_defines.v"

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_wormhole_router_adapter
  #(parameter max_payload_width_p = "inv"
    , parameter len_width_p       = "inv"
    , parameter cord_width_p      = "inv"
    , parameter flit_width_p      = "inv"

    , localparam bsg_ready_and_link_sif_width_lp =
        `bsg_ready_and_link_sif_width(flit_width_p)
    , localparam bsg_wormhole_packet_width_lp =
        `bsg_wormhole_router_packet_width(cord_width_p, len_width_p, max_payload_width_p)
    )
   (input                                          clk_i
    , input                                        reset_i

    , input [bsg_wormhole_packet_width_lp-1:0]     packet_i
    , input                                        v_i
    , output                                       ready_o
 
    // From the wormhole router
    , input [bsg_ready_and_link_sif_width_lp-1:0]  link_i 
    // To the wormhole router
    , output [bsg_ready_and_link_sif_width_lp-1:0] link_o

    , output [bsg_wormhole_packet_width_lp-1:0]    packet_o
    , output                                       v_o
    , input                                        yumi_i
    );

  // Casting ports
  `declare_bsg_ready_and_link_sif_s(flit_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_cast_i, link_cast_o;
  bsg_ready_and_link_sif_s link_o_stubbed_v, link_o_stubbed_ready;

  assign link_cast_i = link_i;
  assign link_o = link_cast_o;

  assign link_cast_o.data          = link_o_stubbed_ready.data;
  assign link_cast_o.v             = link_o_stubbed_ready.v;
  assign link_cast_o.ready_and_rev = link_o_stubbed_v.ready_and_rev;

  `declare_bsg_wormhole_router_packet_s(cord_width_p,len_width_p,max_payload_width_p,bsg_wormhole_packet_s);
  bsg_wormhole_packet_s packet_li, packet_lo;

  assign packet_li = packet_i;
  bsg_wormhole_router_adapter_in
   #(.max_payload_width_p(max_payload_width_p)
     ,.len_width_p(len_width_p)
     ,.cord_width_p(cord_width_p)
     ,.flit_width_p(flit_width_p)
     )
   adapter_in
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.packet_i(packet_li)
     ,.v_i(v_i)
     ,.ready_o(ready_o)

     ,.link_i(link_i)
     ,.link_o(link_o_stubbed_ready)
     );

  bsg_wormhole_router_adapter_out
   #(.max_payload_width_p(max_payload_width_p)
     ,.len_width_p(len_width_p)
     ,.cord_width_p(cord_width_p)
     ,.flit_width_p(flit_width_p)
     )
   adapter_out
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.link_i(link_i)
     ,.link_o(link_o_stubbed_v)

     ,.packet_o(packet_lo)
     ,.v_o(v_o)
     ,.yumi_i(yumi_i)
     );
   assign packet_o = packet_lo;

endmodule

