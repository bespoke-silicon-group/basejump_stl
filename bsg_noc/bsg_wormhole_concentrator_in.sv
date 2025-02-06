//
// bsg_wormhole_concentrator_in.sv
// 
// 08/2019
//
// This is an adapter from N unconcentrated wormhole links to one concentrated wormhole link.
// Extra bits (cid) are used in wormhole header to indicate wormhole packet destination, but these
// are set by the sender and not by the concentrator. This field can be set to zero width.
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

module bsg_wormhole_concentrator_in

  #(parameter `BSG_INV_PARAM(flit_width_p)
    ,parameter `BSG_INV_PARAM(len_width_p)
    ,parameter `BSG_INV_PARAM(cid_width_p)
    ,parameter `BSG_INV_PARAM(cord_width_p)
    ,parameter num_in_p            = 1
    ,parameter debug_lp            = 0
    ,parameter hold_on_valid_p     = 0
   )

  (input clk_i
  ,input reset_i

  // unconcentrated multiple links
  ,input  [num_in_p-1:0]                   links_v_i
  ,input  [num_in_p-1:0][flit_width_p-1:0] links_data_i
  ,output [num_in_p-1:0]                   links_ready_and_rev_o

  // concentrated single link
  ,input                     concentrated_link_ready_and_rev_i
  ,output                    concentrated_link_v_o
  ,output [flit_width_p-1:0] concentrated_link_data_o
  );

  // we use bsg_wormhole_router_header_s here instead of bsg_wormhole_concentrator_header_s to allow for cid_width_p=0
  // this requires that they have the same layout
  `declare_bsg_wormhole_header_s(cord_width_p, len_width_p, bsg_wormhole_router_header_s);
  
  
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

        ,.v_i           (links_v_i   [i])
        ,.data_i        (links_data_i[i])
        ,.ready_param_o (links_ready_and_rev_o[i])

        ,.v_o           (fifo_valid_lo[i])
        ,.data_o        (fifo_data_lo [i])
        ,.yumi_i        (yumis[i])
        );

      bsg_wormhole_router_header_s concentrated_hdr;
      assign concentrated_hdr = fifo_data_lo[i][$bits(bsg_wormhole_router_header_s)-1:0];

      bsg_wormhole_router_input_control #(.output_dirs_p(1), .payload_len_bits_p($bits(concentrated_hdr.len))) wic
        (.clk_i
        ,.reset_i
        ,.fifo_v_i           (fifo_valid_lo[i])
        ,.fifo_yumi_i        (yumis[i])
        ,.fifo_decoded_dest_i(1'b1)
        ,.fifo_payload_len_i (concentrated_hdr.len)
        ,.reqs_o             (reqs[i])
        ,.release_o          (releases[i]) // broadcast to all
        ,.detected_header_o  ()
        );

    end

  wire [num_in_p-1:0] data_sel_lo;

  bsg_wormhole_router_output_control
  #(.input_dirs_p(num_in_p), .hold_on_valid_p(hold_on_valid_p)) woc
    (.clk_i
    ,.reset_i
    ,.reqs_i      (reqs         )
    ,.release_i   (releases     )
    ,.valid_i     (fifo_valid_lo)
    ,.yumi_o      (yumis        )
    ,.ready_and_i (concentrated_link_ready_and_rev_i)
    ,.valid_o     (concentrated_link_v_o)
    ,.data_sel_o  (data_sel_lo)
    );
  
  bsg_mux_one_hot #(.width_p(flit_width_p)
                   ,.els_p  (num_in_p)
                   ) data_mux
    (.data_i       (fifo_data_lo)
    ,.sel_one_hot_i(data_sel_lo)
    ,.data_o       (concentrated_link_data_o)
    );

endmodule // bsg_wormhole_concentrator_in

`BSG_ABSTRACT_MODULE(bsg_wormhole_concentrator_in)
