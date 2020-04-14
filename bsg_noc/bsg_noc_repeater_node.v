//
// This module instantiates num_nodes_p two-element-fifos in chains
// It supports multiple bsg_noc_links in parallel
//
// Insert this module into long routings on chip, which can become critical path
//
// Node that side_A_reset_i signal shoule be close to side A
// If reset happens to be close to side B, please swap side A and side B connection, 
// since side A and side B are symmetric, functionality will not be affected.
//

`include "bsg_defines.v"
`include "bsg_noc_links.vh"

module bsg_noc_repeater_node

#(parameter width_p = -1
, parameter bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(width_p)
)

( input  clk_i
, input  reset_i

, input  [bsg_ready_and_link_sif_width_lp-1:0] side_A_links_i
, output [bsg_ready_and_link_sif_width_lp-1:0] side_A_links_o

, input  [bsg_ready_and_link_sif_width_lp-1:0] side_B_links_i
, output [bsg_ready_and_link_sif_width_lp-1:0] side_B_links_o
);

  // declare the bsg_ready_and_link_sif_s struct
  `declare_bsg_ready_and_link_sif_s(width_p, bsg_ready_and_link_sif_s);
  
  // noc links
  bsg_ready_and_link_sif_s links_A_cast_i, links_B_cast_i;
  bsg_ready_and_link_sif_s links_A_cast_o, links_B_cast_o;
 
  assign links_A_cast_i = side_A_links_i;
  assign links_B_cast_i = side_B_links_i;

  assign side_A_links_o = links_A_cast_o;
  assign side_B_links_o = links_B_cast_o;

  bsg_two_fifo #(.width_p(width_p))
   A_to_B
    (.clk_i    ( clk_i   )
     ,.reset_i ( reset_i )

     ,.v_i     ( links_A_cast_i.v    )
     ,.data_i  ( links_A_cast_i.data )
     ,.ready_o ( links_A_cast_o.ready_and_rev )

     ,.v_o     ( links_B_cast_o.v    )
     ,.data_o  ( links_B_cast_o.data )
     ,.yumi_i  ( links_B_cast_i.ready_and_rev & links_B_cast_o.v )
     );

  bsg_two_fifo #(.width_p(width_p))
   B_to_A
    (.clk_i    ( clk_i   )
     ,.reset_i ( reset_i )

     ,.v_i     ( links_B_cast_i.v    )
     ,.data_i  ( links_B_cast_i.data )
     ,.ready_o ( links_B_cast_o.ready_and_rev )

     ,.v_o     ( links_A_cast_o.v    )
     ,.data_o  ( links_A_cast_o.data )
     ,.yumi_i  ( links_A_cast_i.ready_and_rev & links_A_cast_o.v )
     );

endmodule
