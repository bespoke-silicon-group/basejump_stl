/**
 *    bsg_cache_non_blocking_mhu.v
 *
 *    Miss Handling Unit
 *
 *    @author tommy
 */




module bsg_cache_non_blocking_mhu
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
    
    // DMA
    
  );



endmodule
