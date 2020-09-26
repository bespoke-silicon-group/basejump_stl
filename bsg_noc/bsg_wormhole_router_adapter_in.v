/**
 *  bsg_wormhole_router_adapter_in.v
 *
 *  packet = {payload, length, cord}
 */

`include "bsg_defines.v"

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_wormhole_router_adapter_in
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

    , output [bsg_ready_and_link_sif_width_lp-1:0] link_o
    , input [bsg_ready_and_link_sif_width_lp-1:0]  link_i 
    );

  // Casting ports
  `declare_bsg_ready_and_link_sif_s(flit_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_cast_i, link_cast_o;

  `declare_bsg_wormhole_router_packet_s(cord_width_p, len_width_p, max_payload_width_p, bsg_wormhole_packet_s);
  bsg_wormhole_packet_s packet_cast_i;
  assign packet_cast_i = packet_i;

  localparam max_num_flits_lp = `BSG_CDIV($bits(bsg_wormhole_packet_s), flit_width_p);
  localparam protocol_len_lp  = `BSG_SAFE_CLOG2(max_num_flits_lp);
  wire [max_num_flits_lp*flit_width_p-1:0] packet_padded_li = packet_i;

  assign link_cast_i   = link_i;
  assign link_o        = link_cast_o;

  bsg_parallel_in_serial_out_dynamic
   #(.width_p(flit_width_p)
     ,.max_els_p(max_num_flits_lp)
     )
   piso
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.v_i(v_i)
     ,.len_i(protocol_len_lp'(packet_cast_i.len))
     ,.data_i(packet_padded_li)
     ,.ready_o(ready_o)

     ,.v_o(link_cast_o.v)
     ,.len_v_o(/* unused */)
     ,.data_o(link_cast_o.data)
     ,.yumi_i(link_cast_i.ready_and_rev & link_cast_o.v)
     );

   // Stub the input ready, since this is an input adapter
   assign link_cast_o.ready_and_rev = 1'b0;

`ifndef SYNTHESIS
  always_ff @(negedge clk_i)
    assert(reset_i || ~v_i || (packet_cast_i.len <= max_num_flits_lp))
      else 
        $error("Packet received with len: %x > max_num_flits: %x", packet_cast_i.len, max_num_flits_lp);
`endif

endmodule

