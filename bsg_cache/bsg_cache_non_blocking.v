/**
 *    bsg_cache_non_blocking.v
 *
 *    Non-blocking cache.
 *
 *    @author tommy
 *
 */


module bsg_cache_non_blocking 
  import bsg_cache_non_blocking_pkg::*;
  #(parameter id_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter sets_p="inv"
    , parameter ways_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter miss_fifo_els_p="inv"
    
    , parameter cache_pkt_width_lp=`bsg_cache_non_blocking_pkt_width(id_width_p,addr_width_p,data_width_p)
    , parameter dma_pkt_width_lp=`bsg_cache_non_blocking_dma_pkt_width(addr_width_p)
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [cache_pkt_width_lp-1:0] cache_pkt_i
    , output logic ready_o 

    , output logic v_o
    , output logic [id_width_p-1:0] id_o
    , output logic [data_width_p-1:0] data_o

    , output logic [dma_pkt_width_lp-1:0] dma_pkt_o
    , output logic dma_pkt_v_o
    , input dma_pkt_yumi_i

    , input [data_width_p-1:0] dma_data_i
    , input dma_data_v_i
    , output logic dma_data_ready_o

    , output logic [data_width_p-1:0] dma_data_o
    , output logic dma_data_v_o
    , input dma_data_yumi_i
  );


  // localparam
  //
  localparam lg_ways_lp = `BSG_SAFE_CLOG2(ways_p);
  localparam lg_sets_lp = `BSG_SAFE_CLOG2(sets_p);
  localparam lg_block_size_in_words_lp = `BSG_SAFE_CLOG2(block_size_in_words_p);
  localparam byte_sel_width_lp = `BSG_SAFE_CLOG2(data_width_p>>3);
  localparam tag_width_lp = (addr_width_p-lg_sets_lp-lg_block_size_in_words_lp-byte_sel_width_lp);


  // declare structs
  //
  `declare_bsg_cache_non_blocking_data_mem_pkt_s(ways_p,sets_p,block_size_in_words_p,data_width_p);
  `declare_bsg_cache_non_blocking_stat_mem_pkt_s(ways_p,sets_p);
  `declare_bsg_cache_non_blocking_miss_fifo_entry_s(id_width_p,addr_width_p,data_width_p);
  `declare_bsg_cache_non_blocking_dma_cmd_s(ways_p,sets_p,tag_width_lp);
  

  // cache pkt
  //
  `declare_bsg_cache_non_blocking_pkt_s(id_width_p,addr_width_p,data_width_p);

  bsg_cache_non_blocking_pkt_s cache_pkt;
  assign cache_pkt = cache_pkt_i;


  // decode
  //
  bsg_cache_non_blocking_decode_s decode;

  bsg_cache_non_blocking_decode decode0 (
    .opcode_i(cache_pkt.opcode)
    ,.decode_o(decode)
  );


  // TL stage
  //
  bsg_cache_non_blocking_data_mem_pkt_s tl_data_mem_pkt_lo;
  logic tl_data_mem_pkt_v_lo;
  logic tl_data_mem_pkt_yumi_li;

  bsg_cache_non_blocking_stat_mem_pkt_s tl_stat_mem_pkt_lo;
  logic tl_stat_mem_pkt_v_lo;
  logic tl_stat_mem_pkt_yumi_li;

  bsg_cache_non_blocking_miss_fifo_entry_s tl_miss_fifo_entry_lo;
  logic tl_miss_fifo_entry_v_lo;
  logic tl_miss_fifo_entry_ready_li;
  
  logic [ways_p-1:0] valid_tl_lo;
  logic [ways_p-1:0] lock_tl_lo;
  logic [ways_p-1:0][tag_width_lp-1:0] tag_tl_lo;

  bsg_cache_non_blocking_tl_stage #(
    .id_width_p(id_width_p)
    ,.addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.ways_p(ways_p)
    ,.sets_p(sets_p)
    ,.block_size_in_words_p(block_size_in_words_p)
  ) tl0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(v_i)
    ,.id_i(cache_pkt.id)
    ,.addr_i(cache_pkt.addr)
    ,.data_i(cache_pkt.data)
    ,.decode_i(decode)
    ,.ready_o(ready_o)

    ,.data_mem_pkt_v_o(tl_data_mem_pkt_v_lo)
    ,.data_mem_pkt_o(tl_data_mem_pkt_lo)
    ,.data_mem_pkt_yumi_i(tl_data_mem_pkt_yumi_li)

    ,.stat_mem_pkt_v_o(tl_stat_mem_pkt_v_lo)
    ,.stat_mem_pkt_o(tl_stat_mem_pkt_lo)
    ,.stat_mem_pkt_yumi_i(tl_stat_mem_pkt_yumi_li)

    ,.miss_fifo_entry_v_o(tl_miss_fifo_entry_v_lo)
    ,.miss_fifo_entry_o(tl_miss_fifo_entry_lo)
    ,.miss_fifo_entry_ready_i(tl_miss_fifo_entry_ready_li)

    ,.valid_tl_o(valid_tl_lo)
    ,.lock_tl_o(lock_tl_lo)
    ,.tag_tl_o(tag_tl_lo)
  );


  // miss FIFO
  //
  bsg_cache_non_blocking_miss_fifo_entry_s miss_fifo_data_li;
  logic miss_fifo_v_li;
  logic miss_fifo_ready_lo;

  bsg_cache_non_blocking_miss_fifo_entry_s miss_fifo_data_lo;
  logic miss_fifo_v_lo;
  logic miss_fifo_yumi_li;

  bsg_cache_non_blocking_miss_fifo_op_e miss_fifo_yumi_op_li; 
  logic miss_fifo_rollback_li;
  logic miss_fifo_empty_lo;

  bsg_cache_non_blocking_miss_fifo #(
    .width_p($bits(bsg_cache_non_blocking_miss_fifo_entry_s))
    ,.els_p(miss_fifo_els_p)
  ) miss_fifo0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(miss_fifo_v_li)
    ,.data_i(miss_fifo_data_li)
    ,.ready_o(miss_fifo_ready_lo)

    ,.v_o(miss_fifo_v_lo)
    ,.data_o(miss_fifo_data_lo)
    ,.yumi_i(miss_fifo_yumi_li)
    ,.yumi_op_i(miss_fifo_yumi_op_li)

    ,.rollback_i(miss_fifo_rollback_li)
    ,.empty_o(miss_fifo_empty_lo)
  );

  assign miss_fifo_v_li = tl_miss_fifo_entry_v_lo;
  assign miss_fifo_data_li = tl_miss_fifo_entry_lo;
  assign tl_miss_fifo_entry_ready_li = miss_fifo_ready_lo;


  // data_mem
  //
  bsg_cache_non_blocking_data_mem_pkt_s data_mem_pkt_li;
  logic data_mem_v_li;
  logic [data_width_p-1:0] data_mem_data_lo;
  
  bsg_cache_non_blocking_data_mem #(
    .data_width_p(data_width_p)
    ,.ways_p(ways_p)
    ,.sets_p(sets_p)
    ,.block_size_in_words_p(block_size_in_words_p)
  ) data_mem0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i(data_mem_v_li)
    ,.data_mem_pkt_i(data_mem_pkt_li)
    ,.data_o(data_mem_data_lo)
  );


  // stat_mem
  //
  bsg_cache_non_blocking_stat_mem_pkt_s stat_mem_pkt_li;
  logic stat_mem_v_li;
  logic [ways_p-1:0] dirty_lo;
  logic [lg_ways_lp-1:0] lru_way_lo;

  bsg_cache_non_blocking_stat_mem #(
    .ways_p(ways_p)
    ,.sets_p(sets_p)
  ) stat_mem0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(stat_mem_v_li)
    ,.stat_mem_pkt_i(stat_mem_pkt_li)

    ,.dirty_o(dirty_lo)
    ,.lru_way_o(lru_way_lo)
  );


  // MHU
  //
  bsg_cache_non_blocking_dma_cmd_s dma_cmd_lo;
  logic dma_cmd_v_lo;
  logic dma_cmd_ready_li;

  bsg_cache_non_blocking_dma_cmd_s dma_cmd_return_li;
  logic dma_done_li;
  logic dma_pending_li;
  logic dma_ack_lo;
  

  bsg_cache_non_blocking_mhu #(
    .id_width_p(id_width_p)
    ,.addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.ways_p(ways_p)
    ,.sets_p(sets_p)
    ,.block_size_in_words_p(block_size_in_words_p)
  ) mhu0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
  
    ,.valid_tl_i(valid_tl_lo)
    ,.lock_tl_i(lock_tl_lo)
    ,.tag_tl_i(tag_tl_lo) 

    ,.miss_fifo_entry_v_i(miss_fifo_v_lo)
    ,.miss_fifo_entry_i(miss_fifo_data_lo)
    ,.miss_fifo_entry_yumi_o(miss_fifo_yumi_li)
    ,.miss_fifo_entry_yumi_op_o(miss_fifo_yumi_op_li)
    ,.miss_fifo_rollback_o(miss_fifo_rollback_li)
    ,.miss_fifo_empty_i(miss_fifo_empty_lo)

    ,.dma_cmd_o(dma_cmd_lo)
    ,.dma_cmd_v_o(dma_cmd_v_lo)
    ,.dma_cmd_ready_i(dma_cmd_ready_li)

    ,.dma_cmd_return_i(dma_cmd_return_li)
    ,.dma_done_i(dma_done_li)
    ,.dma_pending_i(dma_pending_li)
    ,.dma_ack_o(dma_ack_lo)
  );
  

  // DMA engine
  //
  logic dma_data_mem_pkt_v_lo;
  bsg_cache_non_blocking_data_mem_pkt_s dma_data_mem_pkt_lo;

  bsg_cache_non_blocking_dma #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
  ) dma0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
  
    ,.dma_cmd_i(dma_cmd_lo)
    ,.dma_cmd_v_i(dma_cmd_v_lo)
    ,.dma_cmd_ready_o(dma_cmd_ready_li)

    ,.dma_cmd_return_o(dma_cmd_return_li)
    ,.done_o(dma_done_li)
    ,.pending_o(dma_pending_li)
    ,.ack_i(dma_ack_lo)

    ,.data_mem_pkt_v_o(dma_data_mem_pkt_v_lo)
    ,.data_mem_pkt_o(dma_data_mem_pkt_lo)
    ,.data_mem_data_i(data_mem_data_lo)
    
    ,.dma_pkt_o(dma_pkt_o)
    ,.dma_pkt_v_o(dma_pkt_v_o)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_i)

    ,.dma_data_i(dma_data_i)
    ,.dma_data_v_i(dma_data_v_i)
    ,.dma_data_ready_o(dma_data_ready_o)
    
    ,.dma_data_o(dma_data_o)
    ,.dma_data_v_o(dma_data_v_o)
    ,.dma_data_yumi_i(dma_data_yumi_i)
  );


endmodule
