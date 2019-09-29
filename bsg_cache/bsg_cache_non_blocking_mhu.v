/**
 *    bsg_cache_non_blocking_mhu.v
 *
 *    Miss Handling Unit
 *
 *    @author tommy
 */




module bsg_cache_non_blocking_mhu
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
    , parameter byte_sel_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    , parameter tag_width_lp=(addr_width_p-lg_sets_lp-lg_block_size_in_words_lp-byte_sel_width_lp)

    , parameter miss_fifo_entry_width_lp=
      `bsg_cache_non_blocking_miss_fifo_entry_width(id_width_p,addr_width_p,data_width_p)
  )
  (
    input clk_i
    , input reset_i

    // tl_stage
    , input [ways_p-1:0] valid_tl_i
    , input [ways_p-1:0] lock_tl_i
    , input [ways_p-1:0][tag_width_lp-1:0] tag_tl_i
   
    // data_mem
    
    // stat_mem
 
    // miss FIFO
    , input miss_fifo_entry_v_i
    , input [miss_fifo_entry_width_lp-1:0] miss_fifo_entry_i
    , output logic miss_fifo_entry_yumi_o
    , output bsg_cache_non_blocking_miss_fifo_op_e miss_fifo_entry_yumi_op_o
    , output logic miss_fifo_rollback_o
    , input miss_fifo_empty_i
    
    // DMA
    
  );



endmodule
