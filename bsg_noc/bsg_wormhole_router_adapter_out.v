/**
 *  bsg_wormhole_router_adapter_out.v
 *
 *  packet = {payload, length, cord}
 */

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_wormhole_router_adapter_out
  #(parameter max_payload_width_p = "inv"
    , parameter len_width_p       = "inv"
    , parameter cord_width_p      = "inv"
    , parameter link_width_p      = "inv"

    , parameter buffered_p = 0

    , localparam bsg_ready_and_link_sif_width_lp =
        `bsg_ready_and_link_sif_width(link_width_p)
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
  `declare_bsg_ready_and_link_sif_s(link_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_cast_i, link_cast_o;

  assign link_cast_i = link_i;
  assign link_o = link_cast_o;

  `declare_bsg_wormhole_router_header_s(cord_width_p, len_width_p, bsg_wormhole_header_s);
  bsg_wormhole_header_s header_li;
  assign header_li = link_cast_i.data;

  `declare_bsg_wormhole_router_packet_s(cord_width_p,len_width_p,max_payload_width_p,bsg_wormhole_packet_s);
  bsg_wormhole_packet_s packet_lo;
  logic ready_li, v_lo;

  localparam max_num_flits_lp = 2**len_width_p;
  logic [max_num_flits_lp*link_width_p-1:0] packet_padded_lo;
  bsg_serial_in_parallel_out_dynamic
   #(.width_p(link_width_p)
     ,.max_els_p(max_num_flits_lp)
     )
   sipo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(link_cast_i.data)
     ,.len_i(header_li.len)
     ,.ready_o(link_cast_o.ready_and_rev)
     ,.len_ready_o(/* unused */)
     ,.v_i(link_cast_i.v)

     ,.v_o(v_lo)
     ,.data_o(packet_padded_lo)
     ,.yumi_i(yumi_li)
     );
  assign packet_lo = packet_padded_lo[0+:bsg_wormhole_packet_width_lp];

  if (buffered_p)
    begin : buffer
      logic ready_li;
      assign yumi_li = ready_li & v_lo;
      bsg_two_fifo
       #(.width_p(bsg_wormhole_packet_width_lp))
       buffer
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(packet_lo)
         ,.v_i(v_lo)
         ,.ready_o(ready_li)

         ,.data_o(packet_o)
         ,.v_o(v_o)
         ,.yumi_i(yumi_i)
         );
    end
  else
    begin : no_buffer
      assign packet_o = packet_lo;
      assign v_o      = v_lo;
      assign yumi_li  = yumi_i;
    end

  // Stub the output data dna valid, since this is an output
  assign link_cast_o.data = '0;
  assign link_cast_o.v    = '0;

endmodule

