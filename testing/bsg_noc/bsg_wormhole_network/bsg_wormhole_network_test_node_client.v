
//
// Paul Gao 06/2019
//
//

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_wormhole_router_test_node_client

 #(// Wormhole link parameters
   parameter flit_width_p = "inv"
  ,parameter dims_p = 2
  ,parameter int cord_markers_pos_p[dims_p:0] = '{5, 4, 0}
  ,parameter len_width_p = "inv"

  ,localparam num_nets_lp = 2
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(flit_width_p)  
  ,localparam cord_width_lp = cord_markers_pos_p[dims_p]
  )

  (input clk_i
  ,input reset_i

  ,input [cord_width_lp-1:0] dest_cord_i

  ,input  [num_nets_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [num_nets_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o
  );

  genvar i;

  /********************* Packet definition *********************/
  
  `declare_bsg_wormhole_router_header_s(cord_width_lp,len_width_p,bsg_wormhole_router_header_s);
  
  typedef struct packed {
    logic [flit_width_p-$bits(bsg_wormhole_router_header_s)-1:0] data;
    bsg_wormhole_router_header_s  hdr;
  } wormhole_network_header_flit_s;


  /********************* Interfacing bsg_noc link *********************/

  `declare_bsg_ready_and_link_sif_s(flit_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [num_nets_lp-1:0] link_i_cast, link_o_cast;
  
  for (i = 0; i < num_nets_lp; i++)
  begin: noc_cast
    assign link_i_cast[i]               = link_i[i];
    assign link_o[i]                    = link_o_cast[i];
  end  
  

  /********************* Client nodes (two of them) *********************/
  
  // ATTENTION: This loopback node is not using fwd and rev networks as usual.
  // rev_link_i receives fwd packets, fwd_link_o sends out loopback packets.
  // fwd_link_i also receives fwd packets, rev_link_o sends out loopback packets.

  for (i = 0; i < num_nets_lp; i++)
  begin: client
  
    logic                          req_in_v;
    wormhole_network_header_flit_s req_in_data;
    logic                          req_in_yumi;

    logic                          resp_out_ready;
    wormhole_network_header_flit_s resp_out_data;
    logic                          resp_out_v;

    bsg_one_fifo
   #(.width_p(flit_width_p)
    ) req_in_fifo
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(link_o_cast[i].ready_and_rev)
    ,.v_i    (link_i_cast[i].v)
    ,.data_i (link_i_cast[i].data)

    ,.v_o    (req_in_v)
    ,.data_o (req_in_data)
    ,.yumi_i (req_in_yumi)
    );

    bsg_one_fifo
   #(.width_p(flit_width_p)
    ) resp_out_fifo
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(resp_out_ready)
    ,.v_i    (resp_out_v)
    ,.data_i (resp_out_data)

    ,.v_o    (link_o_cast[i].v)
    ,.data_o (link_o_cast[i].data)
    ,.yumi_i (link_o_cast[i].v & link_i_cast[i].ready_and_rev)
    );

    // loopback any data received, replace cord in flit hdr
    assign resp_out_data.hdr.cord   = dest_cord_i;
    assign resp_out_data.hdr.len    = req_in_data.hdr.len;
    assign resp_out_data.data       = req_in_data.data;

    assign resp_out_v  = req_in_v;
    assign req_in_yumi = resp_out_v & resp_out_ready;
  
  end  

endmodule
