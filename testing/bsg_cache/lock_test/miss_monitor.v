module miss_monitor
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="inv"
    ,parameter ways_p="inv"

    ,localparam lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,localparam lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,localparam lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    ,localparam block_offset_width_lp=(block_size_in_words_p > 1) ? lg_data_mask_width_lp+lg_block_size_in_words_lp : lg_data_mask_width_lp
    ,localparam tag_width_lp=(addr_width_p-lg_sets_lp-block_offset_width_lp)
    ,localparam tag_info_width_lp=`bsg_cache_tag_info_width(tag_width_lp)
    ,localparam lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    ,localparam stat_info_width_lp=`bsg_cache_stat_info_width(ways_p)
    )
  (
    input clk_i
    ,input reset_i

    // from tv stage
    ,input miss_v_i
    ,input bsg_cache_decode_s decode_v_i
    ,input [addr_width_p-1:0] addr_v_i
    ,input [ways_p-1:0][tag_width_lp-1:0] tag_v_i
    ,input [ways_p-1:0] valid_v_i
    ,input [ways_p-1:0] lock_v_i
    ,input [ways_p-1:0] tag_hit_v_i
    ,input [lg_ways_lp-1:0] tag_hit_way_id_i
    ,input tag_hit_found_i

    // from store buffer
    ,input sbuf_empty_i

    // to dma engine
    ,input bsg_cache_dma_cmd_e dma_cmd_o
    ,input [lg_ways_lp-1:0] dma_way_o
    ,input [addr_width_p-1:0] dma_addr_o
    ,input dma_done_i

    // from stat_mem
    ,input [stat_info_width_lp-1:0] stat_info_i

    // to stat_mem
    ,input stat_mem_v_o
    ,input stat_mem_w_o
    ,input [lg_sets_lp-1:0] stat_mem_addr_o
    ,input [stat_info_width_lp-1:0] stat_mem_data_o
    ,input [stat_info_width_lp-1:0] stat_mem_w_mask_o

    // to tag_mem
    ,input tag_mem_v_o
    ,input tag_mem_w_o
    ,input [lg_sets_lp-1:0] tag_mem_addr_o
    ,input [ways_p-1:0][tag_info_width_lp-1:0] tag_mem_data_o
    ,input [ways_p-1:0][tag_info_width_lp-1:0] tag_mem_w_mask_o

    // to pipeline
    ,input done_o
    ,input recover_o
    ,input [lg_ways_lp-1:0] chosen_way_o
    ,input select_snoop_data_r_o

    ,input ack_i
  );

  
  logic a;
  assign a = done_o;

endmodule