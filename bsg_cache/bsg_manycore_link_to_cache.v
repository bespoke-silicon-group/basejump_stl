/**
 *  bsg_manycore_link_to_cache.v
 *
 *  @author Tommy Jung
 *
 *  @param addr_width_p address bit-width of global (remote) address.
 *  @param data_width_p data bit-width. (32-bit)
 *  @param x_cord_width_p x-coord bit-width.
 *  @param y_cord_width_p y-coord bit_width.
 *  @param tag_mem_boundary_p address greater or equal to this maps to TAGST, TAGLA.
 */

`include "bsg_manycore_packet.vh"
`include "bsg_cache_pkt.vh"

module bsg_manycore_link_to_cache
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter x_cord_width_p="inv"
    ,parameter y_cord_width_p="inv"
    ,parameter tag_mem_boundary_p="inv"
    ,parameter fifo_els_p = 4
    ,parameter max_out_credits_lp = 16
    ,parameter link_sif_width_lp=`bsg_manycore_link_sif_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p)
    ,parameter cache_addr_width_lp=addr_width_p+`BSG_SAFE_CLOG2(data_width_p>>3)
    ,parameter bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(cache_addr_width_lp,data_width_p)
    ,parameter packet_width_lp=`bsg_manycore_packet_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p))
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

  ,input v_we_i
);

  logic endpoint_v_lo;
  logic endpoint_yumi_li;
  logic [data_width_p-1:0] endpoint_data_lo;
  logic [(data_width_p>>3)-1:0] endpoint_mask_lo;
  logic [addr_width_p-1:0] endpoint_addr_lo;
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
    ,.fifo_els_p(fifo_els_p)
    ,.data_width_p(data_width_p)
    ,.addr_width_p(addr_width_p)
    ,.max_out_credits_p(max_out_credits_lp)
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

    ,.out_v_i(1'b0)
    ,.out_packet_i((packet_width_lp'(0)))
    ,.out_ready_o()
  
    ,.returned_data_r_o()
    ,.returned_v_r_o()

    ,.returning_data_i(data_i)
    ,.returning_v_i(endpoint_returning_v_li)

    ,.out_credits_o()
    ,.freeze_r_o()
    ,.reverse_arb_pr_o()

    ,.my_x_i(my_x_i)
    ,.my_y_i(my_y_i)
  );


  `declare_bsg_cache_pkt_s(cache_addr_width_lp, data_width_p);
  bsg_cache_pkt_s packet_cast;
  assign cache_pkt_o = packet_cast;
  assign packet_cast.sigext = 1'b0;
  assign packet_cast.mask = endpoint_mask_lo;
  assign packet_cast.opcode = (endpoint_addr_lo >= (addr_width_p)'(tag_mem_boundary_p))
    ? (endpoint_we_lo ? TAGST : TAGLA)
    : (endpoint_we_lo ? SM : LM);

  assign packet_cast.addr = {
    endpoint_addr_lo,
    (`BSG_SAFE_CLOG2(data_width_p>>3))'(0)
  };

  assign packet_cast.data = endpoint_data_lo;
  assign v_o = endpoint_v_lo;
  assign endpoint_yumi_li = endpoint_v_lo & ready_i;

  assign yumi_o = v_i;
  assign endpoint_returning_v_li = v_i & ~we_v_r; 


  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      we_tl_r <= 1'b0;
      we_v_r <= 1'b0;
    end
    else begin
      if (v_we_i) begin
        we_v_r <= we_tl_r;
      end

      if (endpoint_v_lo & ready_i) begin
        we_tl_r <= endpoint_we_lo;
      end
    end
  end


endmodule
