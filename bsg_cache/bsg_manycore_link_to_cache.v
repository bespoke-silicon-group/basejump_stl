/**
 *  bsg_manycore_link_to_cache.v
 *
 *  @author tommy
 */

`include "bsg_manycore_packet.vh"
`include "bsg_cache_pkt.vh"

module bsg_manycore_link_to_cache
  import bsg_cache_pkg::*;
  #(parameter link_addr_width_p="inv"
    ,parameter link_lo_addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter x_cord_width_p="inv"
    ,parameter y_cord_width_p="inv"
    ,parameter load_id_width_p="inv"

    ,parameter fifo_els_p=4
    ,parameter max_out_credits_p = 16

    ,parameter data_mask_width_lp=(data_width_p>>3)
    ,parameter lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_mask_width_lp)
  
    ,parameter link_sif_width_lp=`bsg_manycore_link_sif_width(link_addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p,load_id_width_p)
    ,parameter cache_addr_width_lp=(link_addr_width_p+lg_data_mask_width_lp)
    ,parameter bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(cache_addr_width_lp,data_width_p)
    ,parameter manycore_packet_width_lp=`bsg_manycore_packet_width(link_addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p,load_id_width_p)
  )
  (
    input clk_i
    ,input reset_i

    // manycore-side
    ,input [x_cord_width_p-1:0] my_x_i
    ,input [y_cord_width_p-1:0] my_y_i
    ,input [link_sif_width_lp-1:0] link_sif_i
    ,output logic [link_sif_width_lp-1:0] link_sif_o

    // cache-side
    ,output [bsg_cache_pkt_width_lp-1:0] cache_pkt_o
    ,output logic v_o
    ,input ready_i

    ,input [data_width_p-1:0] data_i
    ,input v_i
    ,output logic yumi_o
  );

  logic endpoint_v_lo;
  logic endpoint_yumi_li;
  logic [data_width_p-1:0] endpoint_data_lo;
  logic [(data_width_p>>3)-1:0] endpoint_mask_lo;
  logic [link_addr_width_p-1:0] endpoint_addr_lo;
  logic endpoint_we_lo;
  logic endpoint_returning_v_li;

  logic we_tl_r;
  logic we_v_r;

  // instantiate endpoint_standards.
  // last one maps to tag_mem.
  //
  bsg_manycore_endpoint_standard #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.data_width_p(data_width_p)
    ,.addr_width_p(link_addr_width_p)
    ,.fifo_els_p(fifo_els_p)
    ,.max_out_credits_p(max_out_credits_p)
  ) dram_endpoint_standard (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
     
    ,.link_sif_i(link_sif_i)
    ,.link_sif_o(link_sif_o)

    ,.in_v_o(endpoint_v_lo)
    ,.in_yumi_i(endpoint_yumi_li)
    ,.in_data_o(endpoint_data_lo)
    ,.in_mask_o(endpoint_mask_lo)
    ,.in_addr_o(endpoint_addr_lo)
    ,.in_we_o(endpoint_we_lo)
    ,.in_src_x_cord_o()
    ,.in_src_y_cord_o()

    ,.out_v_i(1'b0)
    ,.out_packet_i({(manycore_packet_width_lp){1'b0}})
    ,.out_ready_o()
  
    ,.returned_data_r_o()
    ,.returned_load_id_r_o()
    ,.returned_v_r_o()
    ,.returned_fifo_full_o()
    ,.returned_yumi_i(1'b0)

    ,.returning_data_i(data_i)
    ,.returning_v_i(endpoint_returning_v_li)

    ,.out_credits_o()

    ,.my_x_i(my_x_i)
    ,.my_y_i(my_y_i)
  );


  // to cache
  //
  `declare_bsg_cache_pkt_s(cache_addr_width_lp, data_width_p);
  bsg_cache_pkt_s cache_pkt;
  assign cache_pkt_o = cache_pkt;
  assign cache_pkt.sigext = 1'b0;
  assign cache_pkt.mask = endpoint_mask_lo;
  assign cache_pkt.opcode = endpoint_addr_lo[link_lo_addr_width_p]
    ? (endpoint_we_lo ? TAGST : TAGLA)
    : (endpoint_we_lo ? SM : LM);

  assign cache_pkt.addr = {
    {(cache_addr_width_lp-link_lo_addr_width_p-lg_data_mask_width_lp){1'b0}},
    endpoint_addr_lo[link_lo_addr_width_p-1:0],
    {lg_data_mask_width_lp{1'b0}}
  };

  assign cache_pkt.data = endpoint_data_lo;
  assign v_o = endpoint_v_lo;
  assign endpoint_yumi_li = endpoint_v_lo & ready_i;

  // from cache
  //
  assign yumi_o = v_i;
  assign endpoint_returning_v_li = v_i; 

endmodule
