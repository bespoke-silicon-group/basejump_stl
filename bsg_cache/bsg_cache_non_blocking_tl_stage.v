/**
 *  bsg_cache_non_blocking_tl_stage.v
 *
 *  tag-lookup stage
 *
 *  @author tommy
 *
 */


`include "bsg_defines.v"

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
    , input [data_mask_width_lp-1:0] mask_i
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
    , output logic miss_fifo_v_o
    , output logic [miss_fifo_entry_width_lp-1:0] miss_fifo_entry_o
    , input miss_fifo_ready_i
  
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

    , input [lg_ways_lp-1:0] curr_mhu_way_id_i
    , input [lg_sets_lp-1:0] curr_mhu_index_i
    , input curr_mhu_v_i

    , input [lg_ways_lp-1:0] curr_dma_way_id_i
    , input [lg_sets_lp-1:0] curr_dma_index_i
    , input curr_dma_v_i
  );


  // localparam
  //
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
  logic v_tl_r, v_tl_n;
  logic block_mode_r, block_mode_n;
  logic tl_we;
  bsg_cache_non_blocking_decode_s decode_tl_r;
  logic [id_width_p-1:0] id_tl_r;
  logic [addr_width_p-1:0] addr_tl_r;
  logic [data_width_p-1:0] data_tl_r;
  logic [data_mask_width_lp-1:0] mask_tl_r;
  logic mgmt_op_v;

  assign decode_tl_o = decode_tl_r;
  assign id_tl_o = id_tl_r;
  assign addr_tl_o = addr_tl_r;
  assign data_tl_o = data_tl_r;
  assign mgmt_op_v = decode_i.mgmt_op & v_i;

  logic [lg_sets_lp-1:0] addr_index;
  logic [lg_ways_lp-1:0] addr_way;

  assign addr_index = addr_i[block_offset_width_lp+:lg_sets_lp];
  assign addr_way = addr_i[block_offset_width_lp+lg_sets_lp+:lg_ways_lp];

  logic [tag_width_lp-1:0] addr_tag_tl;
  logic [lg_sets_lp-1:0] addr_index_tl;

  assign addr_tag_tl = addr_tl_r[block_offset_width_lp+lg_sets_lp+:tag_width_lp];
  assign addr_index_tl = addr_tl_r[block_offset_width_lp+:lg_sets_lp];

  assign block_loading_o = block_mode_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_tl_r <= 1'b0;
      block_mode_r <= 1'b0;
    end
    else begin
      v_tl_r <= v_tl_n;
      block_mode_r <= block_mode_n;
    end
    
    if (reset_i) begin
      {decode_tl_r
      ,id_tl_r
      ,addr_tl_r
      ,data_tl_r
      ,mask_tl_r} <= '0;
    end
    else begin
      if (tl_we) begin
        decode_tl_r <= decode_i;
        id_tl_r <= id_i;
        addr_tl_r <= addr_i;
        data_tl_r <= data_i;
        mask_tl_r <= mask_i;
      end
    end
  end 


  // block_load counter
  //
  logic counter_clear;
  logic counter_up;
  logic [lg_block_size_in_words_lp-1:0] counter_r;
  logic counter_max;

  bsg_counter_clear_up #(
    .max_val_p(block_size_in_words_p-1)
    ,.init_val_p(0)
  ) block_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(counter_clear)
    ,.up_i(counter_up)
    ,.count_o(counter_r)
  );

  assign counter_max = counter_r == (block_size_in_words_p-1);


  // tag_mem
  //
  logic tag_mem_v_li;
  bsg_cache_non_blocking_tag_mem_pkt_s tag_mem_pkt;

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
    ,.tag_mem_pkt_i(tag_mem_pkt)

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
  
  bsg_priority_encode #(
    .width_p(ways_p)
    ,.lo_to_hi_p(1)
  ) tag_hit_pe (
    .i(tag_hit)
    ,.addr_o(tag_hit_way)
    ,.v_o() // too slow
  );
  
  assign tag_hit_way_o = tag_hit_way;

  wire tag_hit_found = |tag_hit;
  assign tag_hit_found_o = tag_hit_found;


  // miss detection logic

  wire mhu_miss_match = curr_mhu_v_i & (tag_hit_way == curr_mhu_way_id_i) & (curr_mhu_index_i == addr_index_tl);
  wire dma_miss_match = curr_dma_v_i & (tag_hit_way == curr_dma_way_id_i) & (curr_dma_index_i == addr_index_tl);


  // TL stage output logic
  //
  assign data_mem_pkt.write_not_read = decode_tl_r.st_op;
  assign data_mem_pkt.way_id = tag_hit_way;
  assign data_mem_pkt.addr = decode_tl_r.block_ld_op
    ? {addr_tl_r[block_offset_width_lp+:lg_sets_lp], counter_r}
    : addr_tl_r[byte_sel_width_lp+:lg_block_size_in_words_lp+lg_sets_lp];

  assign data_mem_pkt.sigext_op = decode_tl_r.sigext_op;
  assign data_mem_pkt.size_op = decode_tl_r.block_ld_op
    ? (2)'($clog2(data_width_p>>3))
    : decode_tl_r.size_op;
  assign data_mem_pkt.byte_sel = decode_tl_r.block_ld_op
    ? {byte_sel_width_lp{1'b0}}
    : addr_tl_r[0+:byte_sel_width_lp];

  assign data_mem_pkt.data = data_tl_r;
  assign data_mem_pkt.mask = mask_tl_r;
  assign data_mem_pkt.mask_op = decode_tl_r.mask_op;

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
  assign miss_fifo_entry.sigext_op = decode_tl_r.sigext_op;
  assign miss_fifo_entry.mask = mask_tl_r;
  assign miss_fifo_entry.mask_op = decode_tl_r.mask_op;


  // pipeline logic
  //
  logic miss_tl;
  logic ld_st_hit;
  logic block_ld_hit;
  logic ld_st_miss;
  logic ld_st_ready;
  logic mgmt_op_tl;

  assign miss_tl = tag_hit_found
    ? (mhu_miss_match | dma_miss_match)
    : 1'b1;

  assign ld_st_hit = v_tl_r & (decode_tl_r.ld_op | decode_tl_r.st_op) & ~miss_tl;
  assign block_ld_hit = v_tl_r & decode_tl_r.block_ld_op & ~miss_tl;
  assign ld_st_miss = v_tl_r & (decode_tl_r.ld_op | decode_tl_r.st_op | decode_tl_r.block_ld_op) & miss_tl;
  assign ld_st_ready = data_mem_pkt_ready_i & stat_mem_pkt_ready_i;
  assign mgmt_op_tl = v_tl_r & decode_tl_r.mgmt_op;
  assign mgmt_v_o = mgmt_op_tl;

  always_comb begin

    ready_o = 1'b0;
    data_mem_pkt_v_o = 1'b0;
    stat_mem_pkt_v_o = 1'b0;
    miss_fifo_v_o = 1'b0;
    v_tl_n = v_tl_r;
    tl_we = 1'b0;
    tag_mem_v_li = 1'b0;
    tag_mem_pkt = mhu_tag_mem_pkt;
    block_mode_n = block_mode_r;
    counter_up = 1'b0;
    counter_clear = 1'b0;

    // If there is cache management op, wait for MHU to yumi.
    // Either mgmt or load/store op can come in next.
    if (mgmt_op_tl) begin
      ready_o = mgmt_yumi_i & ~mhu_tag_mem_pkt_v_i;
      v_tl_n = mgmt_yumi_i
        ? (mhu_tag_mem_pkt_v_i
          ? 1'b0
          : v_i)
        : v_tl_r;

      tl_we = mgmt_yumi_i & v_i & ~mhu_tag_mem_pkt_v_i;
  
      tag_mem_v_li = mgmt_yumi_i & (v_i | mhu_tag_mem_pkt_v_i);

      if (mhu_tag_mem_pkt_v_i) begin
        tag_mem_pkt = mhu_tag_mem_pkt;
      end
      else begin
        tag_mem_pkt.way_id = addr_way;
        tag_mem_pkt.index = addr_index;
        tag_mem_pkt.data = data_i;
        tag_mem_pkt.opcode = decode_i.tagst_op
          ? e_tag_store
          : e_tag_read;
      end
    end
    // The recover signal from MHU forces the TL stage to read the tag_mem
    // again using addr_tl. Recover logic is necessary, because when the MHU
    // updates the tag, the tag_mem output may be stale, or the tag_mem output
    // is perturbed, because the MHU also reads the tag_mem to make
    // replacement decision to send out the next DMA request.
    else if (recover_i) begin
      tag_mem_v_li = v_tl_r;
      tag_mem_pkt.index = addr_index_tl;
      tag_mem_pkt.opcode = e_tag_read;
    end
    // When MHU reads the tag_mem, the TL stage is stalled.
    else if (mhu_tag_mem_pkt_v_i) begin
      tag_mem_v_li = 1'b1;
      tag_mem_pkt = mhu_tag_mem_pkt;
    end
    // If there is a load/store hit, it waits for both data_mem and
    // stat_mem to be ready.
    else if (ld_st_hit) begin
      data_mem_pkt_v_o = ld_st_ready;
      stat_mem_pkt_v_o = ld_st_ready;
      ready_o = ld_st_ready & ~mgmt_op_v;
      v_tl_n = ld_st_ready
        ? (mgmt_op_v ? 1'b0 : v_i)
        : v_tl_r;
      tl_we = ld_st_ready & v_i & ~decode_i.mgmt_op;
      tag_mem_v_li = ld_st_ready & v_i & ~decode_i.mgmt_op;
      tag_mem_pkt.index = addr_index;
      tag_mem_pkt.opcode = e_tag_read;
    end
    // If there is a load/store miss, it enques a new miss FIFO entry.
    // If the miss FIFO is full, then the TL stage is stalled.
    else if (ld_st_miss) begin
      miss_fifo_v_o = 1'b1;
      ready_o = miss_fifo_ready_i & ~mgmt_op_v;
      v_tl_n = miss_fifo_ready_i
        ? (mgmt_op_v ? 1'b0 : v_i)
        : v_tl_r;
      tl_we = miss_fifo_ready_i & v_i & ~decode_i.mgmt_op;
      tag_mem_v_li = miss_fifo_ready_i & v_i & ~decode_i.mgmt_op;
      tag_mem_pkt.index = addr_index;
      tag_mem_pkt.opcode = e_tag_read;
    end
    // If there is a block_load hit, it reads the data_mem word by word,
    // whenever the data_mem is available. When it's time to read the last
    // word in the block, it also updates the LRU bits.
    // Once it reads the first word in the block, the block_mode signal goes
    // on. During this time, the MHU cannot make any replacement decision or
    // process any secondary miss.
    else if (block_ld_hit) begin
      data_mem_pkt_v_o = counter_max
        ? ld_st_ready
        : data_mem_pkt_ready_i; 
      stat_mem_pkt_v_o = counter_max
        ? ld_st_ready
        : 1'b0; 
      ready_o = ld_st_ready & ~mgmt_op_v & counter_max;
      v_tl_n = (ld_st_ready & counter_max)
        ? (mgmt_op_v ? 1'b0 : v_i)
        : v_tl_r;
      tl_we = ld_st_ready & v_i & ~decode_i.mgmt_op & counter_max;

      tag_mem_v_li = ld_st_ready & v_i & ~decode_i.mgmt_op & counter_max;
      tag_mem_pkt.index = addr_index;
      tag_mem_pkt.opcode = e_tag_read;

      counter_up = ld_st_ready & ~counter_max;
      counter_clear = ld_st_ready & counter_max;

      block_mode_n = (counter_max ? ld_st_ready : data_mem_pkt_ready_i)
        ? (block_mode_r ? ~counter_max : 1'b1)
        : block_mode_r;
    end
    else begin
      // TL stage empty.
      // cache management op cannot enter, if there is load/store in TL stage,
      // or MHU is not idle.
      ready_o = mgmt_op_v
        ? mhu_idle_i
        : 1'b1;
      v_tl_n = mgmt_op_v
        ? (mhu_idle_i ? v_i : 1'b0)
        : v_i;
      tl_we = mgmt_op_v
        ? (mhu_idle_i ? v_i : 1'b0)
        : v_i;
      tag_mem_v_li = mgmt_op_v
        ? (mhu_idle_i ? v_i : 1'b0)
        : v_i;

      tag_mem_pkt.way_id = addr_way;
      tag_mem_pkt.index = addr_index;
      tag_mem_pkt.data = data_i;
      tag_mem_pkt.opcode = decode_i.tagst_op
        ? e_tag_store
        : e_tag_read;
    end
  end


  // synopsys translate_off
  always_ff @ (negedge clk_i) begin
    if (~reset_i & v_tl_r) begin
      assert($countones(tag_hit) <= 1) 
        else $error("[BSG_ERROR] %m. t=%t. multiple hits detected.", $time); 
    end
    if (~reset_i & v_tl_r) begin
      assert($countones(lock_tl) <= ways_p-2)
        else $error("[BSG_ERROR] %m. t=%t. There needs to be at least 2 unlocked ways.]", $time);
    end
  end
  // synopsys translate_on



endmodule
