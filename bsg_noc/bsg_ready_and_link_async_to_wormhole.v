
//
// Paul Gao 06/2019
//
// This is an adapter from bsg_noc_ready_and_link to bsg_wormhole_link
// It assumes that wormhole link and bsg_noc link are in different clock regions, two
// asynchronous fifos are instantiated in this adapter to cross the clock domain.
//
// It also assumes that the wide packet always have fixed width
//
// Note: Just because you can connect the wormhole network to the mesh network does not 
// mean that it will not deadlock if traffic classes are not correctly separated.
//

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_ready_and_link_async_to_wormhole

 #(// Wide link parameters
   parameter wide_link_width_p = "inv"
  
  // Wormhole link parameters
  ,parameter flit_width_p                     = "inv"
  ,parameter dims_p                           = 2
  ,parameter int cord_markers_pos_p[dims_p:0] = '{5, 4, 0}
  ,parameter len_width_p                      = "inv"
  
  ,localparam wide_link_sif_width_lp = `bsg_ready_and_link_sif_width(wide_link_width_p)
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(flit_width_p)
  
  ,localparam cord_width_lp = cord_markers_pos_p[dims_p]
  )

  (// Wide side
   input wide_clk_i
  ,input wide_reset_i
  
  ,input  [wide_link_sif_width_lp-1:0] wide_link_i
  ,output [wide_link_sif_width_lp-1:0] wide_link_o
  
  // The wormhole destination IDs should either be connected to a register (whose value is
  // initialized before reset is deasserted), or set to a constant value.
  ,input  [cord_width_lp-1:0] wide_dest_cord_i
  
  // Wormhole side
  ,input wh_clk_i
  ,input wh_reset_i

  ,input  [bsg_ready_and_link_sif_width_lp-1:0] wh_link_i
  ,output [bsg_ready_and_link_sif_width_lp-1:0] wh_link_o
  );

  localparam lg_fifo_depth_lp = 3;
  genvar i;
  
  /********************* Packet definition *********************/
  
  // Define wormhole packet
  `declare_bsg_wormhole_router_header_s(cord_width_lp, len_width_p, bsg_wormhole_hdr_s);
  
  typedef struct packed {
    logic [wide_link_width_p-1:0] data;
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
  
  
  /********************* Interfacing wide link *********************/
  
  `declare_bsg_ready_and_link_sif_s(wide_link_width_p, bsg_wide_link_s);
  bsg_wide_link_s wide_link_i_cast, wide_link_o_cast;
  
  assign wide_link_i_cast = wide_link_i;
  assign wide_link_o      = wide_link_o_cast;
  
  // declare wormhole packet
  wormhole_packet_s wide_piso_data_li_cast, wide_sipof_data_lo_cast;
  
  always_comb 
  begin
    // to wormhole
    wide_piso_data_li_cast.hdr.cord = wide_dest_cord_i;
    wide_piso_data_li_cast.hdr.len  = wormhole_ratio_lp-1;
    wide_piso_data_li_cast.data     = wide_link_i_cast.data;
    
    // from wormhole
    wide_link_o_cast.data           = wide_sipof_data_lo_cast.data;
  end
  
  
  /********************* SIPOF and PISO *********************/
  
  // PISO and SIPOF signals
  logic [wormhole_ratio_lp*flit_width_p-1:0] wide_piso_data_li, wide_sipof_data_lo;
  
  assign wide_piso_data_li       = (wormhole_ratio_lp*flit_width_p)'(wide_piso_data_li_cast);
  assign wide_sipof_data_lo_cast = wide_sipof_data_lo[wormhole_width_lp-1:0];
  
  // Async fifo signals
  logic wide_async_fifo_valid_li, wide_async_fifo_yumi_lo;
  logic wide_async_fifo_valid_lo, wide_async_fifo_ready_li;
  
  logic [flit_width_p-1:0] wide_async_fifo_data_li;
  logic [flit_width_p-1:0] wide_async_fifo_data_lo;
  
  // piso and sipof
  bsg_parallel_in_serial_out 
 #(.width_p(flit_width_p)
  ,.els_p  (wormhole_ratio_lp)
  ) piso
  (.clk_i  (wide_clk_i  )
  ,.reset_i(wide_reset_i)
  ,.valid_i(wide_link_i_cast.v            )
  ,.data_i (wide_piso_data_li             )
  ,.ready_o(wide_link_o_cast.ready_and_rev)
  ,.valid_o(wide_async_fifo_valid_li      )
  ,.data_o (wide_async_fifo_data_li       )
  ,.yumi_i (wide_async_fifo_yumi_lo       )
  );
  
  bsg_serial_in_parallel_out_full
 #(.width_p(flit_width_p)
  ,.els_p  (wormhole_ratio_lp)
  ) sipof
  (.clk_i  (wide_clk_i              )
  ,.reset_i(wide_reset_i            )
  ,.v_i    (wide_async_fifo_valid_lo)
  ,.ready_o(wide_async_fifo_ready_li)
  ,.data_i (wide_async_fifo_data_lo )
  ,.data_o (wide_sipof_data_lo      )
  ,.v_o    (wide_link_o_cast.v      )
  ,.yumi_i (wide_link_o_cast.v & wide_link_i_cast.ready_and_rev)
  );
  
  
  /********************* Async fifo to wormhole link *********************/
  
  `declare_bsg_ready_and_link_sif_s(flit_width_p, bsg_ready_and_link_sif_s);
  
  bsg_ready_and_link_sif_s wh_link_i_cast, wh_link_o_cast;
  assign wh_link_i_cast = wh_link_i;
  assign wh_link_o      = wh_link_o_cast;

  // Wide side async fifo input
  logic wide_async_fifo_full_lo;
  assign wide_async_fifo_yumi_lo = ~wide_async_fifo_full_lo & wide_async_fifo_valid_li;
  
  // Wide side async fifo output
  logic wide_async_fifo_deq_li;
  assign wide_async_fifo_deq_li = wide_async_fifo_ready_li & wide_async_fifo_valid_lo;
  
  // Wormhole side async fifo input
  logic wh_async_fifo_full_lo;
  assign wh_link_o_cast.ready_and_rev = ~wh_async_fifo_full_lo;
  
  // This async fifo crosses from wormhole clock to wide clock
  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (flit_width_p    )
  ) wh_to_wide
  (.w_clk_i  (wh_clk_i  )
  ,.w_reset_i(wh_reset_i)
  ,.w_enq_i  (wh_link_i_cast.v & wh_link_o_cast.ready_and_rev)
  ,.w_data_i (wh_link_i_cast.data  )
  ,.w_full_o (wh_async_fifo_full_lo)

  ,.r_clk_i  (wide_clk_i  )
  ,.r_reset_i(wide_reset_i)
  ,.r_deq_i  (wide_async_fifo_deq_li  )
  ,.r_data_o (wide_async_fifo_data_lo )
  ,.r_valid_o(wide_async_fifo_valid_lo)
  );
  
  // This async fifo crosses from wide clock to wormhole clock
  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (flit_width_p    )
  ) wide_to_wh
  (.w_clk_i  (wide_clk_i  )
  ,.w_reset_i(wide_reset_i)
  ,.w_enq_i  (wide_async_fifo_yumi_lo)
  ,.w_data_i (wide_async_fifo_data_li)
  ,.w_full_o (wide_async_fifo_full_lo)

  ,.r_clk_i  (wh_clk_i  )
  ,.r_reset_i(wh_reset_i)
  ,.r_deq_i  (wh_link_o_cast.v & wh_link_i_cast.ready_and_rev)
  ,.r_data_o (wh_link_o_cast.data)
  ,.r_valid_o(wh_link_o_cast.v   )
  );
  
endmodule