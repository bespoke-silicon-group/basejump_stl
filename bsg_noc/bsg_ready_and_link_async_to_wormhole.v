
//
// Paul Gao 06/2019
//
// This is an adapter from bsg_noc_ready_and_link to bsg_wormhole_link
// It assumes that wormhole link and bsg_noc link are in different clock regions, two
// asynchronous fifos are instantiated in this adapter to cross the clock domain.
//
// It also assumes that the ral (ready_and_link) packet always have fixed width
//
// Note: Just because you can connect the wormhole network to the mesh network does not 
// mean that it will not deadlock if traffic classes are not correctly separated.
//

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_ready_and_link_async_to_wormhole

 #(// ral link parameters
   parameter ral_link_width_p = "inv"
  
  // Wormhole link parameters
  ,parameter flit_width_p                     = "inv"
  ,parameter dims_p                           = 2
  ,parameter int cord_markers_pos_p[dims_p:0] = '{5, 4, 0}
  ,parameter len_width_p                      = "inv"
  
  ,localparam ral_link_sif_width_lp = `bsg_ready_and_link_sif_width(ral_link_width_p)
  ,localparam wormhole_link_sif_width_lp = `bsg_ready_and_link_sif_width(flit_width_p)
  
  ,localparam cord_width_lp = cord_markers_pos_p[dims_p]
  )

  (// ral (ready_and_link) side
   input ral_clk_i
  ,input ral_reset_i
  
  ,input  [ral_link_sif_width_lp-1:0] ral_link_i
  ,output [ral_link_sif_width_lp-1:0] ral_link_o
  
  // ral_dest_cord_i is logically associated with ral_link_i, and that the value must 
  // be held constant until the element is removed from ral_link_i.
  ,input  [cord_width_lp-1:0] ral_dest_cord_i
  
  // Wormhole side
  ,input wh_clk_i
  ,input wh_reset_i

  ,input  [wormhole_link_sif_width_lp-1:0] wh_link_i
  ,output [wormhole_link_sif_width_lp-1:0] wh_link_o
  );

  // 8 elements should be enough to handle roundtrip latency across async clock domain
  localparam lg_fifo_depth_lp = 3;
  genvar i;
  
  /********************* Packet definition *********************/
  
  // Define wormhole packet
  `declare_bsg_wormhole_router_header_s(cord_width_lp, len_width_p, bsg_wormhole_hdr_s);
  
  typedef struct packed {
    logic [ral_link_width_p-1:0] data;
    bsg_wormhole_hdr_s            hdr;
  } wormhole_packet_s;
  
  // Determine PISO and SIPOF convertion ratio
  localparam wormhole_width_lp = $bits(wormhole_packet_s);
  localparam wormhole_ratio_lp = `BSG_CDIV(wormhole_width_lp, flit_width_p);
  
  // synopsys translate_off
  initial
  begin
    assert (len_width_p >= `BSG_SAFE_CLOG2(wormhole_ratio_lp))
    else $error("Wormhole packet len width %d is too narrow for convertion ratio %d. Please increase len width.", len_width_p, wormhole_ratio_lp);
  end
  // synopsys translate_on
  
  
  /********************* Interfacing ral and wh link *********************/
  
  `declare_bsg_ready_and_link_sif_s(ral_link_width_p, bsg_ral_link_s);
  bsg_ral_link_s ral_link_i_cast, ral_link_o_cast;
  
  assign ral_link_i_cast = ral_link_i;
  assign ral_link_o      = ral_link_o_cast;
  
  // declare wormhole packet
  wormhole_packet_s ral_piso_data_li_cast, ral_sipof_data_lo_cast;
  
  always_comb 
  begin
    // to wormhole
    ral_piso_data_li_cast.hdr.cord = ral_dest_cord_i;
    ral_piso_data_li_cast.hdr.len  = wormhole_ratio_lp-1;
    ral_piso_data_li_cast.data     = ral_link_i_cast.data;
    
    // from wormhole
    ral_link_o_cast.data           = ral_sipof_data_lo_cast.data;
  end
  
  `declare_bsg_ready_and_link_sif_s(flit_width_p, wormhole_link_sif_s);
  wormhole_link_sif_s wh_link_i_cast, wh_link_o_cast;
  
  assign wh_link_i_cast = wh_link_i;
  assign wh_link_o      = wh_link_o_cast;
  
  
  /********************* ral -> wormhole link *********************/
  
  // PISO signals
  logic [wormhole_ratio_lp*flit_width_p-1:0] ral_piso_data_li;
  assign ral_piso_data_li       = (wormhole_ratio_lp*flit_width_p)'(ral_piso_data_li_cast);
  
  // Async fifo signals
  logic ral_async_fifo_valid_li, ral_async_fifo_yumi_lo;
  logic [flit_width_p-1:0] ral_async_fifo_data_li;
  
  // piso
  bsg_parallel_in_serial_out 
 #(.width_p(flit_width_p)
  ,.els_p  (wormhole_ratio_lp)
  ) piso
  (.clk_i  (ral_clk_i  )
  ,.reset_i(ral_reset_i)
  ,.valid_i(ral_link_i_cast.v            )
  ,.data_i (ral_piso_data_li             )
  ,.ready_o(ral_link_o_cast.ready_and_rev)
  ,.valid_o(ral_async_fifo_valid_li      )
  ,.data_o (ral_async_fifo_data_li       )
  ,.yumi_i (ral_async_fifo_yumi_lo       )
  );

  // ral side async fifo input
  logic ral_async_fifo_full_lo;
  assign ral_async_fifo_yumi_lo = ~ral_async_fifo_full_lo & ral_async_fifo_valid_li;
  
  // This async fifo crosses from ral clock to wormhole clock
  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (flit_width_p    )
  ) ral_to_wh
  (.w_clk_i  (ral_clk_i  )
  ,.w_reset_i(ral_reset_i)
  ,.w_enq_i  (ral_async_fifo_yumi_lo)
  ,.w_data_i (ral_async_fifo_data_li)
  ,.w_full_o (ral_async_fifo_full_lo)

  ,.r_clk_i  (wh_clk_i  )
  ,.r_reset_i(wh_reset_i)
  ,.r_deq_i  (wh_link_o_cast.v & wh_link_i_cast.ready_and_rev)
  ,.r_data_o (wh_link_o_cast.data)
  ,.r_valid_o(wh_link_o_cast.v   )
  );
  
  
  /********************* wormhole -> ral link *********************/
  
  // Async fifo signals
  logic ral_async_fifo_valid_lo, ral_async_fifo_ready_li;
  logic [flit_width_p-1:0] ral_async_fifo_data_lo;
  
  // ral side async fifo output
  logic ral_async_fifo_deq_li;
  assign ral_async_fifo_deq_li = ral_async_fifo_ready_li & ral_async_fifo_valid_lo;
  
  // Wormhole side async fifo input
  logic wh_async_fifo_full_lo;
  assign wh_link_o_cast.ready_and_rev = ~wh_async_fifo_full_lo;
  
  // This async fifo crosses from wormhole clock to ral clock
  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (flit_width_p    )
  ) wh_to_ral
  (.w_clk_i  (wh_clk_i  )
  ,.w_reset_i(wh_reset_i)
  ,.w_enq_i  (wh_link_i_cast.v & wh_link_o_cast.ready_and_rev)
  ,.w_data_i (wh_link_i_cast.data  )
  ,.w_full_o (wh_async_fifo_full_lo)

  ,.r_clk_i  (ral_clk_i  )
  ,.r_reset_i(ral_reset_i)
  ,.r_deq_i  (ral_async_fifo_deq_li  )
  ,.r_data_o (ral_async_fifo_data_lo )
  ,.r_valid_o(ral_async_fifo_valid_lo)
  );
  
  // SIPOF signals
  logic [wormhole_ratio_lp*flit_width_p-1:0] ral_sipof_data_lo;
  assign ral_sipof_data_lo_cast = ral_sipof_data_lo[wormhole_width_lp-1:0];
  
  // sipof
  bsg_serial_in_parallel_out_full
 #(.width_p(flit_width_p)
  ,.els_p  (wormhole_ratio_lp)
  ) sipof
  (.clk_i  (ral_clk_i              )
  ,.reset_i(ral_reset_i            )
  ,.v_i    (ral_async_fifo_valid_lo)
  ,.ready_o(ral_async_fifo_ready_li)
  ,.data_i (ral_async_fifo_data_lo )
  ,.data_o (ral_sipof_data_lo      )
  ,.v_o    (ral_link_o_cast.v      )
  ,.yumi_i (ral_link_o_cast.v & ral_link_i_cast.ready_and_rev)
  );
  

endmodule