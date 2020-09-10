/**
 *  bsg_wormhole_router_adapter_out.v
 *
 *  packet = {payload, length, cord}
 */

`include "bsg_defines.v"

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_wormhole_router_adapter_out
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

    , input [bsg_ready_and_link_sif_width_lp-1:0]  link_i 
    , output [bsg_ready_and_link_sif_width_lp-1:0] link_o

    , output [bsg_wormhole_packet_width_lp-1:0]    packet_o
    , output                                       v_o
    , input                                        yumi_i
    );

  // Casting ports
  `declare_bsg_ready_and_link_sif_s(flit_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_cast_i, link_cast_o;

  assign link_cast_i = link_i;
  assign link_o = link_cast_o;

  `declare_bsg_wormhole_router_header_s(cord_width_p, len_width_p, bsg_wormhole_header_s);
  bsg_wormhole_header_s header_li;
  assign header_li = link_cast_i.data;

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

     ,.data_i(link_cast_i.data)
     ,.len_i(protocol_len_lp'(header_li.len))
     ,.ready_o(link_cast_o.ready_and_rev)
     ,.len_ready_o(/* unused */)
     ,.v_i(link_cast_i.v)

     ,.v_o(v_o)
     ,.data_o(packet_padded_lo)
     ,.yumi_i(yumi_i)
     );
  assign packet_o = packet_padded_lo[0+:bsg_wormhole_packet_width_lp];

  // Stub the output data dna valid, since this is an output
  assign link_cast_o.data = '0;
  assign link_cast_o.v    = '0;

`ifndef SYNTHESIS
  logic recv_r;
  bsg_dff_reset_en
   #(.width_p(1))
   recv_reg
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.en_i(link_cast_i.v || yumi_i)

     ,.data_i(link_cast_i.v)
     ,.data_o(recv_r)
     );
  wire new_header_li = ~recv_r & link_cast_i.v;

  // TODO: This assertion is buggy and fires erroneously
  //always_ff @(negedge clk_i)
  //  assert(reset_i || ~new_header_li || (header_li.len <= max_num_flits_lp))
  //    else 
  //      $error("Header received with len: %x > max_num_flits: %x", header_li.len, max_num_flits_lp);
`endif

endmodule

