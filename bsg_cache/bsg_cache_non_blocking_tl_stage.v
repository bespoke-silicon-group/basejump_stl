/**
 *  bsg_cache_non_blocking_tl_stage.v
 *
 *  tag-lookup stage
 *
 *  @author tommy
 *
 */


module bsg_cache_non_blocking_tl_stage
  import bsg_cache_non_blocking_pkg::*;
  #(parameter id_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter ways_p="inv"
    , parameter sets_p="inv"
    , parameter block_size_in_words_p="inv"

    , parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    , parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    , parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    , parameter data_mask_width_lp=(data_width_p>>3)
    , parameter byte_sel_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    , parameter tag_width_lp=(addr_width_p-lg_sets_lp-lg_block_size_in_words_lp-byte_sel_width_lp)

    , parameter data_mem_pkt_width_lp=
      `bsg_cache_non_blocking_data_mem_pkt_width(id_width_p,ways_p,sets_p,block_size_in_words_p,data_width_p) 

    , parameter miss_fifo_entry_width_lp=
      `bsg_cache_non_blocking_miss_fifo_entry_width(id_width_p,addr_width_p,data_width_p)
  )
  (
    input clk_i
    , input reset_i

    // from input
    , input v_i
    , input [id_width_p-1:0] id_i
    , input [addr_width_p-1:0] addr_i
    , input [data_width_p-1:0] data_i
    , input bsg_cache_non_blocking_decode_s decode_i
    , output logic ready_o  

    // data_mem access (hit)
    , output logic data_mem_pkt_v_o
    , output logic [data_mem_pkt_width_lp-1:0] data_mem_pkt_o
    , input data_mem_pkt_yumi_i

    // stat_mem access (hit)

    // miss FIFO (miss)
    , output logic miss_fifo_entry_v_o
    , output logic [miss_fifo_entry_width_lp-1:0] miss_fifo_entry_o
    , input miss_fifo_entry_ready_i
  
    // cache management
 
    // to MHU 
    , output logic [ways_p-1:0] valid_tl_o
    , output logic [ways_p-1:0] lock_tl_o
    , output logic [ways_p-1:0][tag_width_lp-1:0] tag_tl_o
    
    // from MHU
  );


  // tag_mem
  //
  logic tag_mem_v_li;
  logic [lg_ways_lp-1:0] tag_mem_way_li;
  logic [lg_sets_lp-1:0] tag_mem_addr_li;
  logic [tag_width_lp-1:0] tag_mem_tag_li;
  bsg_cache_non_blocking_tag_op_e tag_mem_tag_op_li;

  logic [ways_p-1:0] valid_tl;
  logic [ways_p-1:0] lock_tl;
  logic [ways_p-1:0][tag_width_lp-1:0] tag_tl;

  bsg_cache_non_blocking_tag_mem #(
    .sets_p(sets_p)
    ,.ways_p(ways_p)
    ,.data_width_p(data_width_p)
    ,.tag_width_p(tag_width_lp)
  ) tag_mem0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(tag_mem_v_li)
    ,.way_i(tag_mem_way_li)
    ,.addr_i(tag_mem_addr_li)
    ,.data_i(data_i)
    ,.tag_i(tag_mem_tag_li)
    ,.tag_op_i(tag_mem_tag_op_li)

    ,.valid_o(valid_tl)
    ,.lock_o(lock_tl)
    ,.tag_o(tag_tl)
  );

  assign valid_tl_o = valid_tl;
  assign lock_tl_o = lock_tl;
  assign tag_tl_o = tag_tl;


endmodule
