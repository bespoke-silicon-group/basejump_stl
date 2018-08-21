/**
 *  bsg_manycore_links_to_cache.v
 *
 *  the last link_sif maps to tag memory, where you can call TAGST, TAGLA.
 * 
 *  @author Tommy Jung
 *
 *  @param addr_width_p address bit-width of global (remote) address.
 *  @param data_width_p data bit-width. (32-bit)
 *  @param x_cord_width_p x-coord bit-width.
 *  @param y_cord_width_p y-coord bit_width.
 *  @param num_links_p the number of link_sif that connects to this converter.
 */

`include "bsg_manycore_packet.vh"
`include "bsg_cache_pkt.vh"

module bsg_manycore_links_to_cache
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter x_cord_width_p="inv"
    ,parameter y_cord_width_p="inv"
    ,parameter num_links_p="inv"
    ,parameter fifo_els_p = 4
    ,parameter max_out_credits_lp = 16
    ,parameter link_sif_width_lp=`bsg_manycore_link_sif_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p)
    ,parameter cache_addr_width_lp=`BSG_SAFE_CLOG2(num_links_p-1)+addr_width_p+`BSG_SAFE_CLOG2(data_width_p>>3)
    ,parameter bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(cache_addr_width_lp,data_width_p)
    ,parameter packet_width_lp=`bsg_manycore_packet_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p))
(
  input clock_i
  ,input reset_i

  // manycore-side
  ,input [num_links_p-1:0][x_cord_width_p-1:0] my_x_i
  ,input [num_links_p-1:0][y_cord_width_p-1:0] my_y_i
  ,input [num_links_p-1:0][link_sif_width_lp-1:0] links_sif_i
  ,output logic [num_links_p-1:0][link_sif_width_lp-1:0] links_sif_o

  // cache-side
  ,output [bsg_cache_pkt_width_lp-1:0] packet_o
  ,output logic v_o
  ,input ready_i

  ,input [data_width_p-1:0] data_i
  ,input v_i
  ,output logic yumi_o

  ,input v_v_we_i
);

  logic [num_links_p-1:0] endpoint_v_lo;
  logic [num_links_p-1:0] endpoint_yumi_li;
  logic [num_links_p-1:0][data_width_p-1:0] endpoint_data_lo;
  logic [num_links_p-1:0][(data_width_p>>3)-1:0] endpoint_mask_lo;
  logic [num_links_p-1:0][addr_width_p-1:0] endpoint_addr_lo;
  logic [num_links_p-1:0] endpoint_we_lo;
  logic [num_links_p-1:0] endpoint_returning_v_li;

  // instantiate endpoint_standards.
  // last one maps to tag_mem.
  //
  genvar i;
  for (i = 0; i < num_links_p; i++) begin
    bsg_manycore_endpoint_standard #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.fifo_els_p(fifo_els_p)
      ,.data_width_p(data_width_p)
      ,.addr_width_p(addr_width_p)
      ,.max_out_credits_p(max_out_credits_lp)
    ) dram_endpoint_standard (
      .clk_i(clock_i)
      ,.reset_i(reset_i)
      
      ,.link_sif_i(links_sif_i[i])
      ,.link_sif_o(links_sif_o[i])

      ,.in_v_o(endpoint_v_lo[i])
      ,.in_yumi_i(endpoint_yumi_li[i])
      ,.in_data_o(endpoint_data_lo[i])
      ,.in_mask_o(endpoint_mask_lo[i])
      ,.in_addr_o(endpoint_addr_lo[i])
      ,.in_we_o(endpoint_we_lo[i])

      ,.out_v_i(1'b0)
      ,.out_packet_i((packet_width_lp'(0)))
      ,.out_ready_o()
  
      ,.returned_data_r_o()
      ,.returned_v_r_o()

      ,.returning_data_i(data_i)
      ,.returning_v_i(endpoint_returning_v_li[i])

      ,.out_credits_o()
      ,.freeze_r_o()
      ,.reverse_arb_pr_o()

      ,.my_x_i(my_x_i[i])
      ,.my_y_i(my_y_i[i])
    );
  end

  // data that goes into round robin is packed into an array of struct.
  //
  typedef struct packed {
    logic [data_width_p-1:0] data;
    logic [(data_width_p>>3)-1:0] mask;
    logic [addr_width_p-1:0] addr;
    logic we;
  } rr_data_t;

  rr_data_t [num_links_p-1:0]  rr_data_li ;
  for (i = 0; i < num_links_p; i++) begin
    assign rr_data_li[i].data = endpoint_data_lo[i];
    assign rr_data_li[i].mask = endpoint_mask_lo[i];
    assign rr_data_li[i].addr = endpoint_addr_lo[i];
    assign rr_data_li[i].we = endpoint_we_lo[i]; 
  end

  rr_data_t rr_data_lo_cast;

  logic rr_v_lo;
  logic [$bits(rr_data_t)-1:0] rr_data_lo;
  logic [`BSG_SAFE_CLOG2(num_links_p)-1:0] rr_tag_lo;
  logic rr_yumi_li;
  
  // round robin on incoming packets.
  //
  bsg_round_robin_n_to_1 #(
    .width_p($bits(rr_data_t))
    ,.num_in_p(num_links_p)
    ,.strict_p(0)
  ) endpoint_standard_rr (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    
    ,.data_i(rr_data_li)
    ,.v_i(endpoint_v_lo)
    ,.yumi_o(endpoint_yumi_li)

    ,.v_o(rr_v_lo)
    ,.data_o(rr_data_lo)
    ,.tag_o(rr_tag_lo)
    ,.yumi_i(rr_yumi_li)
  );

  assign rr_yumi_li = ready_i & rr_v_lo;
  assign rr_data_lo_cast = rr_data_lo;

  // tracking round-robin tag and write enable.
  // we track these so that we know which links to return packet,
  // and whether the operation was store or load
  //
  logic [`BSG_SAFE_CLOG2(num_links_p)-1:0] tag_tl_r, tag_v_r;
  logic we_tl_r, we_v_r;
  
  always_ff @ (posedge clock_i) begin
    if (reset_i) begin
      tag_tl_r <= '0;
      tag_v_r <= '0;
      we_tl_r <= '0;
      we_v_r <= '0;
    end
    else begin
      if (v_v_we_i) begin
        tag_v_r <= tag_tl_r;
        we_v_r <= we_tl_r;
      end
      
      if (rr_v_lo & ready_i) begin
        tag_tl_r <= rr_tag_lo; 
        we_tl_r <= rr_data_lo_cast.we;
      end
    end
  end

  // to cache
  //
  `declare_bsg_cache_pkt_s(cache_addr_width_lp, data_width_p);
  bsg_cache_pkt_s packet_cast;
  assign packet_o = packet_cast;
  assign packet_cast.sigext = 1'b0;
  assign packet_cast.mask = rr_data_lo_cast.mask;
  assign packet_cast.opcode = (rr_tag_lo == num_links_p-1)
    ? (rr_data_lo_cast.we ? TAGST : TAGLA)
    : (rr_data_lo_cast.we ? SM : LM);
  assign packet_cast.addr = {
    rr_tag_lo == (num_links_p-1) ? (`BSG_SAFE_CLOG2(num_links_p)'(0)) : rr_tag_lo, 
    rr_data_lo_cast.addr,
    (`BSG_SAFE_CLOG2(data_width_p>>3))'(0)};
  assign packet_cast.data = rr_data_lo_cast.data;
  assign v_o = rr_v_lo;
  assign yumi_o = v_i;
 
  // from cache
  //
  bsg_decode_with_v #(
    .num_out_p(num_links_p)
  ) decode_with_v (
    .i(tag_v_r)
    ,.v(v_i & ~we_v_r)
    ,.o(endpoint_returning_v_li)
  );

endmodule
