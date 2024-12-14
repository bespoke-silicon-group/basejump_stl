//
// bsg_wormhole_concentrator.sv
// 
// 08/2019
//
// This is an adapter between 1 concentrated wormhole link and N unconcentrated wormhole links.
// Extra bits (cid) are used in wormhole header to indicate wormhole packet destination.
//
// From implementation perspective this is a simplified version bsg_wormhole_router.
// Wormhole_router relies on 2D routing_matrix, while wormhole_concentrator has fixed 1-to-n 
// and n-to-1 routing. This concentrator reuses most of the building blocks of wormhole_router, 
// concentrator header struct is defined in bsg_wormhole_router.svh.
//
// This concentrator has 1-cycle delay from input wormhole link(s) to output wormhole link(s).
// It has zero bubble between wormhole packets.
//
//

`include "bsg_defines.sv"
`include "bsg_noc_links.svh"
`include "bsg_wormhole_router.svh"

module bsg_wormhole_concentrator

  #(parameter `BSG_INV_PARAM(flit_width_p)
    ,parameter `BSG_INV_PARAM(len_width_p)
    ,parameter `BSG_INV_PARAM(cid_width_p)
    ,parameter `BSG_INV_PARAM(cord_width_p)
    ,parameter num_in_p            = 1
    ,parameter debug_lp            = 0
    ,parameter link_width_lp       = `bsg_ready_and_link_sif_width(flit_width_p)
    // Hold on valid sets the arbitration policy such that once an output tag is selected, it
    // remains selected until it is acked, then the round-robin scheduler continues cycling
    // from the selected tag. This is consistent with BaseJump STL handshake assumptions.
    // Notably, this parameter is required to work with bsg_parallel_in_serial_out_passthrough.
    // This policy has a slight throughput degradation but effectively arbitrates based on age,
    // so minimizes worst case latency.
    ,parameter hold_on_valid_p     = 0
   )

  (input clk_i
  ,input reset_i

  // unconcentrated multiple links
  ,input  [num_in_p-1:0][link_width_lp-1:0] links_i
  ,output [num_in_p-1:0][link_width_lp-1:0] links_o

  // concentrated single link
  ,input  [link_width_lp-1:0] concentrated_link_i
  ,output [link_width_lp-1:0] concentrated_link_o
  );


   logic [num_in_p-1:0] links_v_li;
   logic [num_in_p-1:0][flit_width_p-1:0] links_data_li;
   
  `declare_bsg_ready_and_link_sif_s(flit_width_p,bsg_ready_and_link_sif_s);
  
  bsg_ready_and_link_sif_s [num_in_p-1:0] links_i_cast, links_o_cast;
  logic [num_in_p-1:0] links_ready_and_rev_lo, links_ready_and_rev_li;
   
  bsg_ready_and_link_sif_s concentrated_link_i_cast, concentrated_link_o_cast;

  logic [num_in_p-1:0][flit_width_p-1:0] links_data_lo;
  logic [num_in_p-1:0] 	          	 links_v_lo;
 
  logic 	       concentrated_link_ready_and_rev_lo;
   
  assign links_i_cast = links_i;
  assign links_o = links_o_cast;

  assign concentrated_link_i_cast = concentrated_link_i;
  assign concentrated_link_o = concentrated_link_o_cast;
  
  for (genvar i = 0; i < num_in_p; i++)
    begin : cast
       assign links_o_cast[i].v             = links_v_lo   [i];
       assign links_o_cast[i].data          = links_data_lo[i];

       assign links_o_cast[i].ready_and_rev = links_ready_and_rev_lo[i];

       assign links_ready_and_rev_li[i]        = links_i_cast[i].ready_and_rev;

       assign links_v_li[i]    = links_i_cast[i].v;
       assign links_data_li[i] = links_i_cast[i].data;       
    end

  assign concentrated_link_o_cast.ready_and_rev = concentrated_link_ready_and_rev_lo;

  bsg_wormhole_concentrator_in
   #(.flit_width_p(flit_width_p)
     ,.len_width_p(len_width_p)
     ,.cid_width_p(cid_width_p)
     ,.num_in_p(num_in_p)
     ,.cord_width_p(cord_width_p)
     ,.debug_lp(debug_lp)
     ,.hold_on_valid_p(hold_on_valid_p)
     )
   concentrator_in
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.links_v_i            (links_v_li)
     ,.links_data_i         (links_data_li)
     ,.links_ready_and_rev_o(links_ready_and_rev_lo)

     ,.concentrated_link_ready_and_rev_i(concentrated_link_i_cast.ready_and_rev)
     ,.concentrated_link_v_o            (concentrated_link_o_cast.v)
     ,.concentrated_link_data_o         (concentrated_link_o_cast.data)
     );

  bsg_wormhole_concentrator_out
   #(.flit_width_p(flit_width_p)
     ,.len_width_p(len_width_p)
     ,.cid_width_p(cid_width_p)
     ,.num_in_p(num_in_p)
     ,.cord_width_p(cord_width_p)
     ,.debug_lp(debug_lp)
     ,.hold_on_valid_p(hold_on_valid_p)
     )
   concentrator_out
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.links_v_o            (links_v_lo)
     ,.links_data_o         (links_data_lo)
     ,.links_ready_and_rev_i(links_ready_and_rev_li)

     ,.concentrated_link_v_i            (concentrated_link_i_cast.v        )
     ,.concentrated_link_data_i         (concentrated_link_i_cast.data     )     
     ,.concentrated_link_ready_and_rev_o(concentrated_link_ready_and_rev_lo)
     );

endmodule


`BSG_ABSTRACT_MODULE(bsg_wormhole_concentrator)
