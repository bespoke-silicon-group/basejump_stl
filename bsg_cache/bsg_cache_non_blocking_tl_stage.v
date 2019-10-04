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
      `bsg_cache_non_blocking_data_mem_pkt_width(ways_p,sets_p,block_size_in_words_p,data_width_p) 
    , parameter stat_mem_pkt_width_lp=
      `bsg_cache_non_blocking_stat_mem_pkt_width(ways_p,sets_p)
    , parameter tag_mem_pkt_width_lp=
      `bsg_cache_non_blocking_tag_mem_pkt_width(ways_p,sets_p,data_width_p,tag_width_lp)

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
    , input data_mem_pkt_ready_i
    , output logic block_loading_o

    // stat_mem access (hit)
    , output logic stat_mem_pkt_v_o
    , output logic [stat_mem_pkt_width_lp-1:0] stat_mem_pkt_o
    , input stat_mem_pkt_ready_i

    // miss FIFO (miss)
    , output logic miss_fifo_entry_v_o
    , output logic [miss_fifo_entry_width_lp-1:0] miss_fifo_entry_o
    , input miss_fifo_entry_ready_i
  
    // to MHU (cache management)
    , output logic mgmt_v_o
    , output logic [ways_p-1:0] valid_tl_o
    , output logic [ways_p-1:0] lock_tl_o
    , output logic [ways_p-1:0][tag_width_lp-1:0] tag_tl_o
    , output bsg_cache_non_blocking_decode_s decode_tl_o
    , output logic [addr_width_p-1:0] addr_tl_o
    , output logic [id_width_p-1:0] id_tl_o
    , output logic [data_width_p-1:0] data_tl_o
    , output logic [lg_ways_lp-1:0] tag_hit_way_o
    , output logic tag_hit_found_o
    , input mgmt_yumi_i

    // from MHU
    , input mhu_tag_mem_pkt_v_i
    , input [tag_mem_pkt_width_lp-1:0] mhu_tag_mem_pkt_i
    , input mhu_idle_i
    , input recover_i

    , input [addr_width_p-1:0] mhu_evict_addr_i
    , input mhu_evict_v_i
    , input [addr_width_p-1:0] dma_evict_addr_i
    , input dma_evict_v_i
  );


  // localparam
  //
  localparam counter_width_lp = `BSG_SAFE_CLOG2(block_size_in_words_p+1);
  localparam block_offset_width_lp = byte_sel_width_lp+lg_block_size_in_words_lp;


  // declare structs
  //
  `declare_bsg_cache_non_blocking_tag_mem_pkt_s(ways_p,sets_p,data_width_p,tag_width_lp);
  `declare_bsg_cache_non_blocking_stat_mem_pkt_s(ways_p,sets_p);
  `declare_bsg_cache_non_blocking_data_mem_pkt_s(ways_p,sets_p,block_size_in_words_p,data_width_p);
  `declare_bsg_cache_non_blocking_miss_fifo_entry_s(id_width_p,addr_width_p,data_width_p);

  bsg_cache_non_blocking_data_mem_pkt_s data_mem_pkt;
  bsg_cache_non_blocking_stat_mem_pkt_s stat_mem_pkt;
  bsg_cache_non_blocking_tag_mem_pkt_s mhu_tag_mem_pkt;
  bsg_cache_non_blocking_miss_fifo_entry_s miss_fifo_entry;

  assign data_mem_pkt_o = data_mem_pkt;
  assign stat_mem_pkt_o = stat_mem_pkt;
  assign mhu_tag_mem_pkt = mhu_tag_mem_pkt_i;
  assign miss_fifo_entry_o = miss_fifo_entry;


  // TL stage
  //
  typedef enum logic {
    START
    ,BLOCK_MODE
  } tl_state_e;

  tl_state_e tl_state_n;
  tl_state_e tl_state_r;

  logic v_tl_r, v_tl_n;
  bsg_cache_non_blocking_decode_s decode_tl_r, decode_tl_n;
  logic [id_width_p-1:0] id_tl_r, id_tl_n;
  logic [addr_width_p-1:0] addr_tl_r, addr_tl_n;
  logic [data_width_p-1:0] data_tl_r, data_tl_n;

  assign decode_tl_o = decode_tl_r;
  assign id_tl_o = id_tl_r;
  assign addr_tl_o = addr_tl_r;
  assign data_tl_o = data_tl_r;

  logic [tag_width_lp-1:0] addr_tag_tl;
  logic [lg_sets_lp-1:0] addr_index_tl;

  assign addr_tag_tl = addr_tl_r[block_offset_width_lp+lg_sets_lp+:tag_width_lp];
  assign addr_index_tl = addr_tl_r[block_offset_width_lp+:lg_sets_lp];


  // block_load counter
  //
  logic counter_clear;
  logic counter_up;
  logic [counter_width_lp-1:0] counter_r;

  bsg_counter_clear_up #(
    .max_val_p(block_size_in_words_p)
  ) block_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(counter_clear)
    ,.up_i(counter_up)
    ,.count_o(counter_r)
  );


  // tag_mem
  //
  logic tag_mem_v_li;
  bsg_cache_non_blocking_tag_mem_pkt_s tag_mem_pkt_li;

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
    ,.tag_mem_pkt_i(tag_mem_pkt_li)

    ,.valid_o(valid_tl)
    ,.lock_o(lock_tl)
    ,.tag_o(tag_tl)
  );

  assign valid_tl_o = valid_tl;
  assign lock_tl_o = lock_tl;
  assign tag_tl_o = tag_tl;


  // tag hit detection
  //
  logic [ways_p-1:0] tag_hit;

  for (genvar i = 0; i < ways_p; i++) begin
    assign tag_hit[i] = (tag_tl[i] == addr_tag_tl) & valid_tl[i];
  end

  logic [lg_ways_lp-1:0] tag_hit_way;
  logic tag_hit_found;
  
  bsg_priority_encode #(
    .width_p(ways_p)
    ,.lo_to_hi_p(1)
  ) tag_hit_pe (
    .i(tag_hit)
    ,.addr_o(tag_hit_way)
    ,.v_o(tag_hit_found)
  );
  
  assign tag_hit_way_o = tag_hit_way;
  assign tag_hit_found_o = tag_hit_found;


  // TL stage output logic
  //
  assign data_mem_pkt.write_not_read = decode_tl_r.st_op;
  assign data_mem_pkt.sigext_op = decode_tl_r.sigext_op;
  assign data_mem_pkt.size_op = decode_tl_r.size_op;
  assign data_mem_pkt.byte_sel = addr_tl_r[0+:byte_sel_width_lp];
  assign data_mem_pkt.way_id = tag_hit_way;
  assign data_mem_pkt.addr = addr_tl_r[byte_sel_width_lp+:lg_block_size_in_words_lp+lg_sets_lp];
  assign data_mem_pkt.data = data_tl_r;

  assign stat_mem_pkt.way_id = tag_hit_way;
  assign stat_mem_pkt.index = addr_index_tl;
  assign stat_mem_pkt.opcode = decode_tl_r.st_op
    ? e_stat_set_lru_and_dirty
    : e_stat_set_lru;

  assign miss_fifo_entry.write_not_read = decode_tl_r.st_op;
  assign miss_fifo_entry.block_load = decode_tl_r.block_ld_op;
  assign miss_fifo_entry.size_op = decode_tl_r.size_op;
  assign miss_fifo_entry.id = id_tl_r;
  assign miss_fifo_entry.addr = addr_tl_r;
  assign miss_fifo_entry.data = data_tl_r;


  // miss detection logic
  //
  logic mhu_evict_match;
  logic dma_evict_match;

  assign mhu_evict_match = 
    mhu_evict_v_i & (mhu_evict_addr_i == {addr_tag_tl, addr_index_tl, {block_offset_width_lp{1'b0}}});
  assign dma_evict_match = 
    dma_evict_v_i & (dma_evict_addr_i == {addr_tag_tl, addr_index_tl, {block_offset_width_lp{1'b0}}});


  // pipeline logic
  //



  // synopsys sync_set_reset "reset_i"
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      tl_state_r <= START;
      v_tl_r <= 1'b0;
      decode_tl_r <= '0;
      id_tl_r <= '0;
      addr_tl_r <= '0;
      data_tl_r <= '0;
    end
    else begin
      tl_state_r <= tl_state_n;
      v_tl_r <= v_tl_n;
      decode_tl_r <= decode_tl_n;
      id_tl_r <= id_tl_n;
      addr_tl_r <= addr_tl_n;
      data_tl_r <= data_tl_n;
    end
  end  


endmodule
