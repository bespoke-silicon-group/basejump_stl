/**
 *  bsg_wormhole_router_adapter_in.v
 *
 *  packet = {payload, length, cord}
 */

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_wormhole_router_adapter_in
  #(parameter max_payload_width_p = "inv"
    , parameter len_width_p       = "inv"
    , parameter cord_width_p      = "inv"
    , parameter link_width_p      = "inv"

    , localparam bsg_ready_and_link_sif_width_lp =
        `bsg_ready_and_link_sif_width(link_width_p)
    , localparam bsg_wormhole_packet_width_lp = 
        `bsg_wormhole_router_packet_width(cord_width_p, len_width_p, max_payload_width_p)
    )
   (input                                          clk_i
    , input                                        reset_i

    , input [bsg_wormhole_packet_width_lp-1:0]     packet_i
    , input                                        v_i
    , output                                       ready_o

    , output [bsg_ready_and_link_sif_width_lp-1:0] link_o
    // Used for ready_i signal, the rest should be stubbed, since this an input adapter
    , input [bsg_ready_and_link_sif_width_lp-1:0]  link_i 
  );

  // Casting ports
  `declare_bsg_ready_and_link_sif_s(link_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_cast_i, link_cast_o;

  `declare_bsg_wormhole_router_packet_s(cord_width_p, len_width_p, max_payload_width_p, bsg_wormhole_packet_s);
  bsg_wormhole_packet_s packet_cast_i;

  localparam max_num_flits_lp = 2**len_width_p;
  wire [max_num_flits_lp*link_width_p-1:0] packet_padded_li = packet_i;

  assign link_cast_i   = link_i;
  assign link_o        = link_cast_o;
  assign packet_cast_i = packet_i;

  assign link_cast_o.ready_and_rev = 1'b0;
  bsg_parallel_in_serial_out_dynamic
   #(.width_p(link_width_p)
     ,.max_els_p(max_num_flits_lp)
     )
   piso
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.v_i(v_i)
     ,.len_i(packet_cast_i.len)
     ,.data_i(packet_padded_li)
     ,.ready_o(ready_o)

     ,.v_o(link_cast_o.v)
     ,.len_v_o(/* unused */)
     ,.data_o(link_cast_o.data)
     ,.yumi_i(link_cast_i.ready_and_rev & link_cast_o.v)
     );

endmodule

