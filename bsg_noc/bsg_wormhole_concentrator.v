//
// bsg_wormhole_concentrator.v
// 
// 08/2019
//
// This is an adapter between 1 concentrated wormhole link and N unconcentrated wormhole links.
// Extra bits (cid) are used in wormhole header to indicate wormhole packet destination.
//
// From implementation perspective this is a simplified version bsg_wormhole_router_generalized.
// Wormhole_router relies on 2D routing_matrix, while wormhole_concentrator has fixed 1-to-n 
// and n-to-1 routing. This concentrator reuses most of the building blocks of wormhole_router, 
// concentrator header struct is defined in bsg_wormhole_router.vh.
//
// This concentrator has 1-cycle delay from input wormhole link(s) to output wormhole link(s).
//
//

`include "bsg_defines.v"
`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_wormhole_concentrator

  #(parameter flit_width_p        = "inv"
   ,parameter num_in_p            = 1
   ,parameter dims_p              = 2
   ,parameter int cord_markers_pos_p[dims_p:0] = '{ 5, 4, 0 }
   ,parameter len_width_p         = "inv"
   // concentration id (cid) width, depends on num_in_p
   ,parameter cid_width_lp        = `BSG_SAFE_CLOG2(num_in_p)
   ,parameter debug_lp            = 0
   )

  (input clk_i
  ,input reset_i

  // unconcentrated multiple links
  ,input  [num_in_p-1:0][`bsg_ready_and_link_sif_width(flit_width_p)-1:0] links_i
  ,output [num_in_p-1:0][`bsg_ready_and_link_sif_width(flit_width_p)-1:0] links_o

  // concentrated single link
  ,input  [`bsg_ready_and_link_sif_width(flit_width_p)-1:0] concentrated_link_i
  ,output [`bsg_ready_and_link_sif_width(flit_width_p)-1:0] concentrated_link_o
  );

  `declare_bsg_ready_and_link_sif_s(flit_width_p,bsg_ready_and_link_sif_s);
  `declare_bsg_wormhole_router_header_s(cord_markers_pos_p[dims_p], len_width_p, bsg_wormhole_router_header_s);
  `declare_bsg_wormhole_concentrator_header_s(cid_width_lp, bsg_wormhole_router_header_s, bsg_wormhole_concentrator_header_s);
  
  bsg_ready_and_link_sif_s [num_in_p-1:0] links_i_cast, links_o_cast;
  bsg_ready_and_link_sif_s concentrated_link_i_cast, concentrated_link_o_cast;
  
  assign links_i_cast = links_i;
  assign links_o = links_o_cast;
  
  assign concentrated_link_i_cast = concentrated_link_i;
  assign concentrated_link_o = concentrated_link_o_cast;
  
  genvar i,j;

  /********** From unconcentrated side to concentrated side **********/
  
  wire [num_in_p-1:0][flit_width_p-1:0] fifo_data_lo;
  wire [num_in_p-1:0]                   fifo_valid_lo;

  // one for each input channel; it broadcasts that it is finished to all of the outputs
  wire [num_in_p-1:0] releases;

  // from each input to concentrated output
  wire [num_in_p-1:0] reqs;

  // from concentrated output to each input
  wire [num_in_p-1:0] yumis;

  for (i = 0; i < num_in_p; i=i+1)
    begin: in_ch

      bsg_two_fifo #(.width_p(flit_width_p)) twofer
        (.clk_i
        ,.reset_i
        ,.ready_o(links_o_cast[i].ready_and_rev)
        ,.data_i (links_i_cast[i].data)
        ,.v_i    (links_i_cast[i].v)
        ,.v_o    (fifo_valid_lo[i])
        ,.data_o (fifo_data_lo [i])
        ,.yumi_i (yumis[i])
        );

      bsg_wormhole_router_header_s hdr;
      assign hdr = fifo_data_lo[i][$bits(bsg_wormhole_router_header_s)-1:0];

      bsg_wormhole_router_input_control #(.output_dirs_p(1), .payload_len_bits_p($bits(hdr.len))) wic
        (.clk_i
        ,.reset_i
        ,.fifo_v_i           (fifo_valid_lo[i])
        ,.fifo_yumi_i        (yumis[i])
        ,.fifo_decoded_dest_i(1'b1)
        ,.fifo_payload_len_i (hdr.len)
        ,.reqs_o             (reqs[i])
        ,.release_o          (releases[i]) // broadcast to all
        ,.detected_header_o  ()
        );

    end

  wire [num_in_p-1:0] data_sel_lo;

  bsg_wormhole_router_output_control #(.input_dirs_p(num_in_p)) woc
    (.clk_i
    ,.reset_i
    ,.reqs_i    (reqs         )
    ,.release_i (releases     )
    ,.valid_i   (fifo_valid_lo)
    ,.yumi_o    (yumis        )
    ,.ready_i   (concentrated_link_i_cast.ready_and_rev)
    ,.valid_o   (concentrated_link_o_cast.v)
    ,.data_sel_o(data_sel_lo)
    );
  
  bsg_mux_one_hot #(.width_p(flit_width_p)
                   ,.els_p  (num_in_p)
                   ) data_mux
    (.data_i       (fifo_data_lo)
    ,.sel_one_hot_i(data_sel_lo)
    ,.data_o       (concentrated_link_o_cast.data)
    );
    
  /********** From concentrated side to unconcentrated side **********/
  
  wire [flit_width_p-1:0] concentrated_fifo_data_lo;
  wire                    concentrated_fifo_valid_lo;

  // one for each input channel; it broadcasts that it is finished to all of the outputs
  wire concentrated_releases;

  // from concentrated input to each output
  wire [num_in_p-1:0] concentrated_reqs;

  // from each output to concentrated input
  wire [num_in_p-1:0] concentrated_yumis;

  wire concentrated_any_yumi = | concentrated_yumis;

  bsg_two_fifo #(.width_p(flit_width_p)) concentrated_twofer
    (.clk_i
    ,.reset_i
    ,.ready_o(concentrated_link_o_cast.ready_and_rev)
    ,.data_i (concentrated_link_i_cast.data)
    ,.v_i    (concentrated_link_i_cast.v)
    ,.v_o    (concentrated_fifo_valid_lo)
    ,.data_o (concentrated_fifo_data_lo )
    ,.yumi_i (concentrated_any_yumi)
     );

  bsg_wormhole_concentrator_header_s concentrated_hdr;
  assign concentrated_hdr = concentrated_fifo_data_lo[$bits(bsg_wormhole_concentrator_header_s)-1:0];
  
  wire [num_in_p-1:0] concentrated_decoded_dest_lo;
  bsg_decode #(.num_out_p(num_in_p)) concentrated_decoder
    (.i(concentrated_hdr.cid)
    ,.o(concentrated_decoded_dest_lo)
    );

  bsg_wormhole_router_input_control #(.output_dirs_p(num_in_p), .payload_len_bits_p($bits(concentrated_hdr.hdr.len))) concentrated_wic
    (.clk_i
    ,.reset_i
    ,.fifo_v_i           (concentrated_fifo_valid_lo)
    ,.fifo_yumi_i        (concentrated_any_yumi)
    ,.fifo_decoded_dest_i(concentrated_decoded_dest_lo)
    ,.fifo_payload_len_i (concentrated_hdr.hdr.len)
    ,.reqs_o             (concentrated_reqs)
    ,.release_o          (concentrated_releases) // broadcast to all
    ,.detected_header_o  ()
    );

  // iterate through each output channel
  for (i = 0; i < num_in_p; i=i+1)
    begin: out_ch

      bsg_wormhole_router_output_control #(.input_dirs_p(1)) concentrated_woc
        (.clk_i
        ,.reset_i
        ,.reqs_i    (concentrated_reqs[i] )
        ,.release_i (concentrated_releases)
        ,.valid_i   (concentrated_fifo_valid_lo)
        ,.yumi_o    (concentrated_yumis[i])
        ,.ready_i   (links_i_cast[i].ready_and_rev)
        ,.valid_o   (links_o_cast[i].v)
        ,.data_sel_o()
        );
      
      assign links_o_cast[i].data = concentrated_fifo_data_lo;
      
    end

endmodule
