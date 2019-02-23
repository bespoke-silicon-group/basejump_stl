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
    , parameter data_width_p="inv"
    , parameter x_cord_width_p="inv"
    , parameter y_cord_width_p="inv"
    , parameter load_id_width_p="inv"

    , parameter sets_p="inv"
    , parameter ways_p="inv"
    , parameter block_size_in_words_p="inv"

    , parameter fifo_els_p=4
    , parameter max_out_credits_p = 16

    , parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    , parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    , parameter word_offset_width_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter byte_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    , parameter cache_addr_width_lp=(link_addr_width_p-1+byte_offset_width_lp) 
    , parameter block_offset_width_lp=(word_offset_width_lp+byte_offset_width_lp)
  
    , parameter link_sif_width_lp=
      `bsg_manycore_link_sif_width(link_addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p,load_id_width_p)
    , parameter bsg_cache_pkt_width_lp=
      `bsg_cache_pkt_width(cache_addr_width_lp,data_width_p)
    , parameter manycore_packet_width_lp=
      `bsg_manycore_packet_width(link_addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p,load_id_width_p)
  )
  (
    input clk_i
    , input reset_i

    // manycore-side
    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i

    , input [link_sif_width_lp-1:0] link_sif_i
    , output logic [link_sif_width_lp-1:0] link_sif_o

    // cache-side
    , output [bsg_cache_pkt_width_lp-1:0] cache_pkt_o
    , output logic v_o
    , input ready_i

    , input [data_width_p-1:0] data_i
    , input v_i
    , output logic yumi_o
  );


  // instantiate endpoint_standard
  //
  logic endpoint_v_lo;
  logic endpoint_yumi_li;
  logic [data_width_p-1:0] endpoint_data_lo;
  logic [data_mask_width_lp-1:0] endpoint_mask_lo;
  logic [link_addr_width_p-1:0] endpoint_addr_lo;
  logic endpoint_we_lo;
  logic endpoint_returning_v_li;

  bsg_manycore_endpoint_standard #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.data_width_p(data_width_p)
    ,.addr_width_p(link_addr_width_p)
    ,.fifo_els_p(fifo_els_p)
    ,.max_out_credits_p(max_out_credits_p)
    ,.load_id_width_p(load_id_width_p)
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

  // at the reset, this module intializes all the tags and valid bits to zero.
  // After all the tags are completedly initialized, this module starts
  // accepting packets from manycore network.
  `declare_bsg_cache_pkt_s(cache_addr_width_lp, data_width_p);
  bsg_cache_pkt_s cache_pkt;
  assign cache_pkt_o = cache_pkt;

  typedef enum logic [1:0] {
    RESET
    ,CLEAR_TAG
    ,READY
  } state_e;

  state_e state_r, state_n;
  logic [lg_sets_lp+lg_ways_lp:0] tagst_sent_r, tagst_sent_n;
  logic [lg_sets_lp+lg_ways_lp:0] tagst_received_r, tagst_received_n;

  always_comb begin
    cache_pkt.sigext = 1'b0;
    cache_pkt.mask = endpoint_mask_lo;
    cache_pkt.data = '0;
    cache_pkt.addr = '0;
    tagst_sent_n = tagst_sent_r;
    tagst_received_n = tagst_received_r;
    v_o = 1'b0;
    yumi_o = 1'b0;
    endpoint_yumi_li = '0;
    endpoint_returning_v_li = 1'b0;
    state_n = state_r;

    case (state_r)
      RESET: begin
        v_o = 1'b0;
        yumi_o = 1'b0;
        state_n = CLEAR_TAG;
      end
      CLEAR_TAG: begin
        v_o = tagst_sent_r != (ways_p*sets_p);
        
        cache_pkt.opcode = TAGST;
        cache_pkt.data = '0;
        cache_pkt.addr = {
          {(cache_addr_width_lp-lg_sets_lp-lg_ways_lp-block_offset_width_lp){1'b0}},
          tagst_sent_r[0+:lg_sets_lp+lg_ways_lp],
          {(block_offset_width_lp){1'b0}}
        };

        endpoint_yumi_li = 1'b0;

        tagst_sent_n = (v_o & ready_i)
          ? tagst_sent_r + 1
          : tagst_sent_r;
        tagst_received_n = v_i
          ? tagst_received_r + 1
          : tagst_received_r;

        yumi_o = v_i;
        endpoint_returning_v_li = 1'b0; 

        state_n = (tagst_sent_r == ways_p*sets_p) & (tagst_received_r == ways_p*sets_p)
          ? READY
          : CLEAR_TAG;
      end

      READY: begin
        v_o = endpoint_v_lo;
        endpoint_yumi_li = endpoint_v_lo & ready_i;
    
        // if MSB of addr is one, then it maps to tag_mem
        // otherwise it's regular access to data_mem.
        // we want to expose read/write access to tag_mem on NPA
        // for extra debugging capability.
        cache_pkt.opcode = endpoint_addr_lo[link_addr_width_p-1]
          ? (endpoint_we_lo ? TAGST : TAGLA)
          : (endpoint_we_lo ? SM : LM);
        cache_pkt.data = endpoint_data_lo;
        cache_pkt.addr = {
          endpoint_addr_lo[0+:link_addr_width_p-1],
          {byte_offset_width_lp{1'b0}} 
        };

        yumi_o = v_i;
        endpoint_returning_v_li = v_i;

        state_n = READY;
      end
    endcase
  end
  
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      state_r <= RESET;
      tagst_sent_r <= '0;
      tagst_received_r <= '0;
    end
    else begin
      state_r <= state_n;
      tagst_sent_r <= tagst_sent_n;
      tagst_received_r <= tagst_received_n;
    end
  end

endmodule
