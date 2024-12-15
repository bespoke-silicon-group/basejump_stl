//
// bsg_wormhole_concentrator_out.sv
// 
// 08/2019
//
// This is an adapter from 1 concentrated wormhole link to N unconcentrated wormhole links.
// The field CID in the header determines which of the unconcentrated links the packet is routed to,
// this is set by the sender.
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

module bsg_wormhole_concentrator_out

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
  ,output  [num_in_p-1:0]                                                  links_v_o
  ,output  [num_in_p-1:0][flit_width_p-1:0]                                links_data_o
  ,input   [num_in_p-1:0]                                                  links_ready_and_rev_i

  // concentrated single link
  ,input                                                    concentrated_link_v_i
  ,input  [flit_width_p-1:0]                                concentrated_link_data_i
  ,output                                                   concentrated_link_ready_and_rev_o
  );

  `declare_bsg_wormhole_concentrator_header_s(cord_width_p, len_width_p, cid_width_p, bsg_wormhole_concentrator_header_s);
  
  genvar i,j;

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
    ,.ready_param_o (concentrated_link_ready_and_rev_o)
    ,.data_i        (concentrated_link_data_i)
    ,.v_i           (concentrated_link_v_i)
    ,.v_o           (concentrated_fifo_valid_lo)
    ,.data_o        (concentrated_fifo_data_lo )
    ,.yumi_i        (concentrated_any_yumi)
     );

  bsg_wormhole_concentrator_header_s concentrated_hdr;
  assign concentrated_hdr = concentrated_fifo_data_lo[$bits(bsg_wormhole_concentrator_header_s)-1:0];
  
  wire [num_in_p-1:0] concentrated_decoded_dest_lo;
  bsg_decode #(.num_out_p(num_in_p)) concentrated_decoder
    (.i(concentrated_hdr.cid[0+:`BSG_SAFE_CLOG2(num_in_p)])
    ,.o(concentrated_decoded_dest_lo)
    );

  bsg_wormhole_router_input_control #(.output_dirs_p(num_in_p), .payload_len_bits_p($bits(concentrated_hdr.len))) concentrated_wic
    (.clk_i
    ,.reset_i
    ,.fifo_v_i           (concentrated_fifo_valid_lo)
    ,.fifo_yumi_i        (concentrated_any_yumi)
    ,.fifo_decoded_dest_i(concentrated_decoded_dest_lo)
    ,.fifo_payload_len_i (concentrated_hdr.len)
    ,.reqs_o             (concentrated_reqs)
    ,.release_o          (concentrated_releases) // broadcast to all
    ,.detected_header_o  ()
    );

  // iterate through each output channel
  for (i = 0; i < num_in_p; i=i+1)
    begin: out_ch

      bsg_wormhole_router_output_control
      #(.input_dirs_p(1), .hold_on_valid_p(hold_on_valid_p)) concentrated_woc
        (.clk_i
        ,.reset_i
        ,.reqs_i    (concentrated_reqs[i] )
        ,.release_i (concentrated_releases)
        ,.valid_i   (concentrated_fifo_valid_lo)
        ,.yumi_o    (concentrated_yumis[i])
        ,.ready_and_i   (links_ready_and_rev_i[i])
        ,.valid_o   (links_v_o[i])
        ,.data_sel_o()
        );
      
      assign links_data_o[i] = concentrated_fifo_data_lo;
      
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_wormhole_concentrator_out)
