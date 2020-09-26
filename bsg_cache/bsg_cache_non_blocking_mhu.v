/**
 *    bsg_cache_non_blocking_mhu.v
 *
 *    Miss Handling Unit.
 *
 *    @author tommy
 *
 */


`include "bsg_defines.v"

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

    , parameter data_mem_pkt_width_lp=
      `bsg_cache_non_blocking_data_mem_pkt_width(ways_p,sets_p,block_size_in_words_p,data_width_p) 
    , parameter stat_mem_pkt_width_lp=
      `bsg_cache_non_blocking_stat_mem_pkt_width(ways_p,sets_p)
    , parameter tag_mem_pkt_width_lp=
      `bsg_cache_non_blocking_tag_mem_pkt_width(ways_p,sets_p,data_width_p,tag_width_lp)

    , parameter miss_fifo_entry_width_lp=
      `bsg_cache_non_blocking_miss_fifo_entry_width(id_width_p,addr_width_p,data_width_p)
    , parameter dma_cmd_width_lp=
      `bsg_cache_non_blocking_dma_cmd_width(ways_p,sets_p,tag_width_lp)
  )
  (
    input clk_i
    , input reset_i

    // cache management interface
    , input mgmt_v_i
    , output logic mgmt_yumi_o
    , output logic mgmt_data_v_o
    , output logic [data_width_p-1:0] mgmt_data_o
    , output logic [id_width_p-1:0] mgmt_id_o
    , input mgmt_data_yumi_i

    , input bsg_cache_non_blocking_decode_s decode_tl_i
    , input [addr_width_p-1:0] addr_tl_i
    , input [id_width_p-1:0] id_tl_i

    , output logic idle_o
    , output logic recover_o
    , input tl_block_loading_i

    // data_mem
    , output logic data_mem_pkt_v_o
    , output logic [data_mem_pkt_width_lp-1:0] data_mem_pkt_o
    , output logic [id_width_p-1:0] data_mem_pkt_id_o
    , input data_mem_pkt_yumi_i
    
    // stat_mem
    , output logic stat_mem_pkt_v_o
    , output logic [stat_mem_pkt_width_lp-1:0] stat_mem_pkt_o
 
    , input [ways_p-1:0] dirty_i
    , input [ways_p-2:0] lru_bits_i
 
    // tag_mem
    , output logic tag_mem_pkt_v_o
    , output logic [tag_mem_pkt_width_lp-1:0] tag_mem_pkt_o
    , input [ways_p-1:0] valid_tl_i
    , input [ways_p-1:0] lock_tl_i
    , input [ways_p-1:0][tag_width_lp-1:0] tag_tl_i
    , input [lg_ways_lp-1:0] tag_hit_way_i
    , input tag_hit_found_i
    
    , output logic [lg_ways_lp-1:0] curr_mhu_way_id_o
    , output logic [lg_sets_lp-1:0] curr_mhu_index_o
    , output logic curr_mhu_v_o
   
    // miss FIFO
    , input miss_fifo_v_i
    , input [miss_fifo_entry_width_lp-1:0] miss_fifo_entry_i
    , output logic miss_fifo_yumi_o
    , output bsg_cache_non_blocking_miss_fifo_op_e miss_fifo_yumi_op_o
    , output logic miss_fifo_scan_not_dq_o
    , output logic miss_fifo_rollback_o
    , input miss_fifo_empty_i
   
    // DMA
    , output logic [dma_cmd_width_lp-1:0] dma_cmd_o
    , output logic dma_cmd_v_o

    , input [dma_cmd_width_lp-1:0] dma_cmd_return_i
    , input dma_done_i
    , input dma_pending_i
    , output logic dma_ack_o
  );


  // localparam
  //
  localparam block_offset_width_lp = lg_block_size_in_words_lp+byte_sel_width_lp;
  localparam mhu_dff_width_lp = `bsg_cache_non_blocking_mhu_dff_width(id_width_p,addr_width_p,tag_width_lp,ways_p);


  // declare structs
  //
  `declare_bsg_cache_non_blocking_data_mem_pkt_s(ways_p,sets_p,block_size_in_words_p,data_width_p);
  `declare_bsg_cache_non_blocking_stat_mem_pkt_s(ways_p,sets_p);
  `declare_bsg_cache_non_blocking_tag_mem_pkt_s(ways_p,sets_p,data_width_p,tag_width_lp);
  `declare_bsg_cache_non_blocking_miss_fifo_entry_s(id_width_p,addr_width_p,data_width_p);
  `declare_bsg_cache_non_blocking_dma_cmd_s(ways_p,sets_p,tag_width_lp);

  bsg_cache_non_blocking_data_mem_pkt_s data_mem_pkt;
  bsg_cache_non_blocking_stat_mem_pkt_s stat_mem_pkt;
  bsg_cache_non_blocking_tag_mem_pkt_s tag_mem_pkt;
  bsg_cache_non_blocking_miss_fifo_entry_s miss_fifo_entry;
  bsg_cache_non_blocking_dma_cmd_s dma_cmd_out, dma_cmd_return;

  assign data_mem_pkt_o = data_mem_pkt;
  assign stat_mem_pkt_o = stat_mem_pkt;
  assign tag_mem_pkt_o = tag_mem_pkt;
  assign miss_fifo_entry = miss_fifo_entry_i;
  assign dma_cmd_o = dma_cmd_out;
  assign dma_cmd_return = dma_cmd_return_i;


  // mhu_state
  //

  mhu_state_e mhu_state_r;
  mhu_state_e mhu_state_n;

  // During DQ or SCAN mode, when secondary store is encountered, this flop is
  // set to one. Later, when the stat_mem is being updated, set the dirty bit
  // if this is 1'b1.
  logic set_dirty_n, set_dirty_r; 

  // MHU flops
  //
  `declare_bsg_cache_non_blocking_mhu_dff_s(id_width_p,addr_width_p,tag_width_lp,ways_p);
  bsg_cache_non_blocking_mhu_dff_s mhu_dff_r;
  bsg_cache_non_blocking_mhu_dff_s mhu_dff_n;
  logic mhu_dff_en;

  bsg_dff_reset_en #(
    .width_p(mhu_dff_width_lp)
    ,.reset_val_p(0)
  ) mhu_dff (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.en_i(mhu_dff_en)
    ,.data_i(mhu_dff_n)
    ,.data_o(mhu_dff_r)
  );

  assign mhu_dff_n = '{
    decode : decode_tl_i,
    valid : valid_tl_i,
    lock : lock_tl_i,
    tag : tag_tl_i,
    tag_hit_way : tag_hit_way_i,
    tag_hit_found : tag_hit_found_i,
    id : id_tl_i,
    addr : addr_tl_i
  };

  wire [lg_ways_lp-1:0] addr_way_mhu = mhu_dff_r.addr[block_offset_width_lp+lg_sets_lp+:lg_ways_lp];
  wire [tag_width_lp-1:0] addr_tag_mhu = mhu_dff_r.addr[block_offset_width_lp+lg_sets_lp+:tag_width_lp];
  wire [lg_sets_lp-1:0] addr_index_mhu = mhu_dff_r.addr[block_offset_width_lp+:lg_sets_lp];

  // current dma_cmd
  //
  bsg_cache_non_blocking_dma_cmd_s curr_dma_cmd_r;
  bsg_cache_non_blocking_dma_cmd_s curr_dma_cmd_n;
  logic curr_dma_cmd_v_r, curr_dma_cmd_v_n;
  logic [tag_width_lp-1:0] curr_miss_tag;
  logic [lg_sets_lp-1:0] curr_miss_index;
  logic [tag_width_lp-1:0] miss_fifo_tag;
  logic [lg_sets_lp-1:0] miss_fifo_index;
  logic is_secondary;
  
  assign curr_miss_tag = curr_dma_cmd_r.refill_tag;
  assign curr_miss_index = curr_dma_cmd_r.index;
  assign miss_fifo_tag = miss_fifo_entry.addr[block_offset_width_lp+lg_sets_lp+:tag_width_lp];
  assign miss_fifo_index = miss_fifo_entry.addr[block_offset_width_lp+:lg_sets_lp];
  assign is_secondary = (curr_miss_tag == miss_fifo_tag) & (curr_miss_index == miss_fifo_index);


  assign curr_mhu_v_o = curr_dma_cmd_v_r;
  assign curr_mhu_index_o = curr_dma_cmd_r.index;
  assign curr_mhu_way_id_o = curr_dma_cmd_r.way_id;


  // Replacement Policy
  //
  // Try to find a way that is invalid and unlocked. There could be a way that is
  // invalid in tag_mem, BUT has a pending DMA request on it. Those are
  // considered to be NOT invalid.
  // If invalid does not exist, pick the LRU. It is also possible that the LRU
  // way has a pending DMA request, or it is locked. In such occasion, resort
  // to the backup LRU.

  logic invalid_exist;
  logic [lg_ways_lp-1:0] invalid_way_id;
  logic [lg_ways_lp-1:0] backup_lru_way_id;
  logic [lg_ways_lp-1:0] replacement_way_id;
  logic [ways_p-1:0] curr_miss_way_decode;
  logic [ways_p-1:0] disabled_ways;

  wire next_miss_index_match = curr_dma_cmd_v_r & (curr_dma_cmd_r.index == miss_fifo_index);

  bsg_decode_with_v #(
    .num_out_p(ways_p) 
  ) curr_miss_way_demux (
    .i(curr_dma_cmd_r.way_id)
    ,.v_i(next_miss_index_match)
    ,.o(curr_miss_way_decode)
  );

  bsg_priority_encode #(
    .width_p(ways_p)
    ,.lo_to_hi_p(1)
  ) invalid_way_pe (
    .i(~mhu_dff_r.valid & ~mhu_dff_r.lock & ~curr_miss_way_decode) // invalid and unlocked + not current miss
    ,.addr_o(invalid_way_id)
    ,.v_o(invalid_exist)
  );

  assign disabled_ways = mhu_dff_r.lock | curr_miss_way_decode;

  logic [ways_p-2:0] modify_data_lo;
  logic [ways_p-2:0] modify_mask_lo;
  logic [ways_p-2:0] modified_lru_bits;

  bsg_lru_pseudo_tree_backup #(
    .ways_p(ways_p)
  ) lru_backup (
    .disabled_ways_i(disabled_ways)
    ,.modify_data_o(modify_data_lo)
    ,.modify_mask_o(modify_mask_lo)
  );

  bsg_mux_bitwise #(
    .width_p(ways_p-1)
  ) mux (
    .data0_i(lru_bits_i)
    ,.data1_i(modify_data_lo)
    ,.sel_i(modify_mask_lo)
    ,.data_o(modified_lru_bits)
  );

  bsg_lru_pseudo_tree_encode #(
    .ways_p(ways_p)
  ) lru_encode (
    .lru_i(modified_lru_bits)
    ,.way_id_o(backup_lru_way_id)
  );

  assign replacement_way_id = invalid_exist
    ? invalid_way_id
    : backup_lru_way_id;

  logic replacement_dirty;
  logic replacement_valid;
  logic [tag_width_lp-1:0] replacement_tag;

  assign replacement_dirty = dirty_i[replacement_way_id];
  assign replacement_valid = mhu_dff_r.valid[replacement_way_id];
  assign replacement_tag = mhu_dff_r.tag[replacement_way_id];



  // block load counter
  //
  logic counter_clear;
  logic counter_up;
  logic [lg_block_size_in_words_lp-1:0] counter_r;
  logic counter_max;

  bsg_counter_clear_up #(
    .max_val_p(block_size_in_words_p-1)
    ,.init_val_p(0)
  ) block_ld_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(counter_clear)
    ,.up_i(counter_up)
    ,.count_o(counter_r)
  );
  
  assign counter_max = counter_r == (block_size_in_words_p-1);


  // FSM
  //
  always_comb begin

    mhu_state_n = mhu_state_r;
    curr_dma_cmd_n = curr_dma_cmd_r;
    curr_dma_cmd_v_n = curr_dma_cmd_v_r;
    set_dirty_n = set_dirty_r;

    mhu_dff_en = 1'b0;

    idle_o = 1'b0;
    recover_o = 1'b0;

    mgmt_yumi_o = 1'b0;
    mgmt_data_o = '0;
    mgmt_data_v_o = 1'b0;
    mgmt_id_o = mhu_dff_r.id;

    data_mem_pkt_v_o = 1'b0;
    data_mem_pkt.write_not_read = miss_fifo_entry.write_not_read;
    data_mem_pkt_id_o = miss_fifo_entry.id;

    data_mem_pkt.way_id = curr_dma_cmd_r.way_id;
    data_mem_pkt.addr = miss_fifo_entry.block_load
      ? {curr_miss_index, counter_r}
      : {curr_miss_index, miss_fifo_entry.addr[byte_sel_width_lp+:lg_block_size_in_words_lp]};

    data_mem_pkt.sigext_op = miss_fifo_entry.sigext_op;
    data_mem_pkt.size_op = miss_fifo_entry.block_load
      ? (2)'($clog2(data_width_p>>3))
      : miss_fifo_entry.size_op;
    data_mem_pkt.byte_sel = miss_fifo_entry.block_load
      ? {byte_sel_width_lp{1'b0}}
      : miss_fifo_entry.addr[0+:byte_sel_width_lp];

    data_mem_pkt.data = miss_fifo_entry.data;
    data_mem_pkt.mask = miss_fifo_entry.mask;
    data_mem_pkt.mask_op = miss_fifo_entry.mask_op;

    stat_mem_pkt_v_o = 1'b0;
    stat_mem_pkt = '0;

    tag_mem_pkt_v_o = 1'b0;
    tag_mem_pkt = '0;

    dma_cmd_v_o = 1'b0;
    dma_cmd_out = '0;
    dma_ack_o = 1'b0;

    miss_fifo_yumi_o = 1'b0;
    miss_fifo_yumi_op_o = e_miss_fifo_dequeue;
    miss_fifo_rollback_o = 1'b0;
    miss_fifo_scan_not_dq_o = 1'b0;

    counter_clear = 1'b0;
    counter_up = 1'b0;
  
    case (mhu_state_r)

      // When MHU is idle, and there is no pending miss, cache management op may come in.
      // Or MHU has just returned from completing the previous cache miss.
      // For the cache mgmt op that requires data_eviction, it reads the
      // stat_mem for dirty bits, as it moves to SEND_MGMT_DMA.
      // There could be a pending DMA transaction, or it has already
      // completed (dma_pending_i, dma_pending_o).
      // Switch to WAIT_DMA_DONE in that case. Or wait for the miss FIFO to
      // have a valid output.
      MHU_IDLE: begin

        // Flop the necesssary data coming from tl stage, and go to MGMT_OP.
        if (mgmt_v_i) begin
          mhu_dff_en = 1'b1;
          mhu_state_n = MGMT_OP;
        end
        // Go to WAIT_DMA_DONE to wait for a DMA request that was previous
        // sent out while transitioning out of DQ mode.
        else if (dma_pending_i | dma_done_i) begin
          mhu_state_n = WAIT_DMA_DONE; 
        end
        // Wait for miss FIFO output to be valid.
        // When TL block loading is in progress, then wait for it to finish.
        else begin
          idle_o = miss_fifo_empty_i;

          tag_mem_pkt_v_o = miss_fifo_v_i;
          tag_mem_pkt.index = miss_fifo_index;
          tag_mem_pkt.opcode = e_tag_read;

          stat_mem_pkt_v_o = miss_fifo_v_i;
          stat_mem_pkt.index = miss_fifo_index;
          stat_mem_pkt.opcode = e_stat_read;

          mhu_state_n = (miss_fifo_v_i & ~tl_block_loading_i)
            ? READ_TAG1
            : MHU_IDLE;
        end
      end

      // MGMT OP
      MGMT_OP: begin
          mgmt_data_o = '0;
          stat_mem_pkt.index = addr_index_mhu;
          tag_mem_pkt.index = addr_index_mhu;

          // TAGLA: return the tag address at the output.
          if (mhu_dff_r.decode.tagla_op) begin
            mgmt_yumi_o = mgmt_data_yumi_i;
            mgmt_data_o = {mhu_dff_r.tag[addr_way_mhu], addr_index_mhu, {block_offset_width_lp{1'b0}}};            
            mgmt_data_v_o = 1'b1;

            mhu_state_n = mgmt_data_yumi_i
              ? MHU_IDLE
              : MGMT_OP;
          end
          // TAGLV: return the tag valid and lock bit at the output.
          else if (mhu_dff_r.decode.taglv_op) begin
            mgmt_yumi_o = mgmt_data_yumi_i;
            mgmt_data_o = {{(data_width_p-2){1'b0}}, mhu_dff_r.lock[addr_way_mhu], mhu_dff_r.valid[addr_way_mhu]};
            mgmt_data_v_o = 1'b1;

            mhu_state_n = mgmt_data_yumi_i
              ? MHU_IDLE
              : MGMT_OP;
          end
          // TAGST: also clears the stat_mem (dirty/LRU bits).
          else if (mhu_dff_r.decode.tagst_op) begin
            mgmt_yumi_o = mgmt_data_yumi_i;
            mgmt_data_v_o = 1'b1;

            stat_mem_pkt_v_o = mgmt_data_yumi_i;
            stat_mem_pkt.opcode = e_stat_reset;
            stat_mem_pkt.way_id = addr_way_mhu;

            mhu_state_n = mgmt_data_yumi_i
              ? MHU_IDLE
              : MGMT_OP;
          end
          // TAGFL:
          // if the cache line is valid, read stat_mem to check dirty bit.
          // otherwise, return 0;
          else if (mhu_dff_r.decode.tagfl_op) begin
            mgmt_yumi_o = ~mhu_dff_r.valid[addr_way_mhu] & mgmt_data_yumi_i;
            mgmt_data_v_o = ~mhu_dff_r.valid[addr_way_mhu];
        
            stat_mem_pkt_v_o = mhu_dff_r.valid[addr_way_mhu];
            stat_mem_pkt.opcode = e_stat_read;

            mhu_state_n = mhu_dff_r.valid[addr_way_mhu]
              ? SEND_MGMT_DMA
              : MHU_IDLE;
          end
          // AFL/AFLINV:
          // If there is tag hit, it reads the stat_mem.
          // otherwise, return 0;
          else if (mhu_dff_r.decode.afl_op | mhu_dff_r.decode.aflinv_op) begin
            mgmt_yumi_o = ~mhu_dff_r.tag_hit_found & mgmt_data_yumi_i;
            mgmt_data_v_o = ~mhu_dff_r.tag_hit_found;
           
            stat_mem_pkt_v_o = mhu_dff_r.tag_hit_found;
            stat_mem_pkt.opcode = e_stat_read;
   
            mhu_state_n = mhu_dff_r.tag_hit_found
              ? SEND_MGMT_DMA
              : MHU_IDLE;
          end
          // AINV: If there is tag hit, invalidate the cache line.
          else if (mhu_dff_r.decode.ainv_op) begin
            mgmt_yumi_o = mgmt_data_yumi_i;
            mgmt_data_v_o = 1'b1;
            
            stat_mem_pkt_v_o = mhu_dff_r.tag_hit_found;
            stat_mem_pkt.way_id = mhu_dff_r.tag_hit_way;
            stat_mem_pkt.opcode = e_stat_clear_dirty; 

            tag_mem_pkt_v_o = mhu_dff_r.tag_hit_found;
            tag_mem_pkt.way_id = mhu_dff_r.tag_hit_way;
            tag_mem_pkt.opcode = e_tag_invalidate;

            mhu_state_n = mgmt_data_yumi_i
              ? MHU_IDLE
              : MGMT_OP;
          end
          // ALOCK: if there is tag hit, then lock the line.
          // If not, read stat_mem and send mgmt DMA.
          else if (mhu_dff_r.decode.alock_op) begin
            mgmt_yumi_o = mhu_dff_r.tag_hit_found & mgmt_data_yumi_i;
            mgmt_data_v_o = mhu_dff_r.tag_hit_found;

            stat_mem_pkt_v_o = ~mhu_dff_r.tag_hit_found;
            stat_mem_pkt.opcode = e_stat_read;

            tag_mem_pkt_v_o = mhu_dff_r.tag_hit_found & mgmt_data_yumi_i;
            tag_mem_pkt.way_id = mhu_dff_r.tag_hit_way;
            tag_mem_pkt.opcode = e_tag_lock;
        
            mhu_state_n = mhu_dff_r.tag_hit_found
              ? (mgmt_data_yumi_i ? MHU_IDLE : MGMT_OP)
              : SEND_MGMT_DMA;
          end
          // AUNLOCK: if there is tag hit, then unlock the line.
          else if (mhu_dff_r.decode.aunlock_op) begin
            mgmt_yumi_o = mgmt_data_yumi_i;
            mgmt_data_v_o = 1'b1;

            tag_mem_pkt_v_o = mhu_dff_r.tag_hit_found & mgmt_data_yumi_i;
            tag_mem_pkt.way_id = mhu_dff_r.tag_hit_way;
            tag_mem_pkt.opcode = e_tag_unlock;

            mhu_state_n = mgmt_data_yumi_i
              ? MHU_IDLE
              : MGMT_OP;
          end
          else begin
            // This would never happen by design.
            // Do nothing.
          end

      end
  
      // Sending DMA for TAGFL,AFL,AFLINV,ALOCK.
      // For TAGFL,AFL,AFLINV, if the block is dirty, then send out the dma
      // cmd. Otherwise, return 0;
      // For ALOCK, always send the dma cmd to bring in the missing block.
      SEND_MGMT_DMA: begin
  
        dma_cmd_v_o = mhu_dff_r.decode.alock_op
          ? 1'b1
          : (mhu_dff_r.decode.tagfl_op
            ? dirty_i[addr_way_mhu]
            : dirty_i[mhu_dff_r.tag_hit_way]);
        dma_cmd_out.way_id = mhu_dff_r.decode.alock_op
          ? replacement_way_id
          : (mhu_dff_r.decode.tagfl_op
            ? addr_way_mhu
            : mhu_dff_r.tag_hit_way);
        dma_cmd_out.index = addr_index_mhu;
        dma_cmd_out.refill = mhu_dff_r.decode.alock_op;
        dma_cmd_out.refill_tag = addr_tag_mhu; // don't care for flush ops.
        dma_cmd_out.evict = mhu_dff_r.decode.alock_op
          ? (replacement_dirty & replacement_valid)
          : 1'b1;
        dma_cmd_out.evict_tag = mhu_dff_r.decode.alock_op
          ? replacement_tag
          : (mhu_dff_r.decode.tagfl_op
            ? mhu_dff_r.tag[addr_way_mhu]
            : mhu_dff_r.tag[mhu_dff_r.tag_hit_way]);
        
        mgmt_yumi_o = mgmt_data_yumi_i
          & ~mhu_dff_r.decode.alock_op
          & (mhu_dff_r.decode.tagfl_op
            ? ~dirty_i[addr_way_mhu]
            : ~dirty_i[mhu_dff_r.tag_hit_way]);

        mgmt_data_v_o = ~mhu_dff_r.decode.alock_op
          & (mhu_dff_r.decode.tagfl_op
            ? ~dirty_i[addr_way_mhu]
            : ~dirty_i[mhu_dff_r.tag_hit_way]);

        tag_mem_pkt_v_o = mgmt_data_yumi_i & mhu_dff_r.decode.aflinv_op & ~dirty_i[mhu_dff_r.tag_hit_way];
        tag_mem_pkt.way_id = mhu_dff_r.tag_hit_way;
        tag_mem_pkt.index = addr_index_mhu;
        tag_mem_pkt.opcode = e_tag_invalidate;

        mhu_state_n = mhu_dff_r.decode.alock_op
          ? WAIT_MGMT_DMA
          : (mhu_dff_r.decode.tagfl_op
            ? (dirty_i[addr_way_mhu] 
              ? WAIT_MGMT_DMA 
              : (mgmt_data_yumi_i ? MHU_IDLE : SEND_MGMT_DMA))
            : (dirty_i[mhu_dff_r.tag_hit_way] 
              ? WAIT_MGMT_DMA 
              : (mgmt_data_yumi_i ? MHU_IDLE : SEND_MGMT_DMA)));

      end

      // Waiting DMA for TAGFL,AFL,AFLINV,ALOCK.
      WAIT_MGMT_DMA: begin
        mgmt_yumi_o = mgmt_data_yumi_i;
  
        stat_mem_pkt_v_o = dma_done_i & mgmt_data_yumi_i;
        stat_mem_pkt.index = addr_index_mhu;
        stat_mem_pkt.way_id = mhu_dff_r.decode.tagfl_op
          ? addr_way_mhu
          : (mhu_dff_r.decode.alock_op
            ? replacement_way_id
            : mhu_dff_r.tag_hit_way);
        stat_mem_pkt.opcode = e_stat_clear_dirty;

        tag_mem_pkt_v_o = mgmt_data_yumi_i & dma_done_i & (mhu_dff_r.decode.alock_op | mhu_dff_r.decode.aflinv_op);
        tag_mem_pkt.way_id = mhu_dff_r.decode.alock_op
          ? replacement_way_id
          : mhu_dff_r.tag_hit_way;
        tag_mem_pkt.index = addr_index_mhu;
        tag_mem_pkt.tag = addr_tag_mhu; // dont care for AFLINV.
        tag_mem_pkt.opcode = mhu_dff_r.decode.alock_op
          ? e_tag_set_tag_and_lock
          : e_tag_invalidate;

        dma_ack_o = mgmt_data_yumi_i;
        mgmt_data_v_o = dma_done_i;
     
        mhu_state_n = (dma_done_i & mgmt_data_yumi_i)
          ? MHU_IDLE
          : WAIT_MGMT_DMA;

      end

      // READ TAG1
      READ_TAG1: begin
        mhu_dff_en = 1'b1;
        recover_o = 1'b1;
        mhu_state_n = SEND_DMA_REQ1;
      end

      // sending DMA request for the first primary miss.
      // This recover may seem redundant, but we want to stall TL until the
      // dma_cmd has been sent out.
      SEND_DMA_REQ1: begin
        recover_o = 1'b1;
        dma_cmd_v_o = 1'b1;
        dma_cmd_out.way_id = replacement_way_id;
        dma_cmd_out.index = miss_fifo_index; 
        dma_cmd_out.refill = 1'b1;
        dma_cmd_out.evict = replacement_valid & replacement_dirty;
        dma_cmd_out.refill_tag = miss_fifo_tag;
        dma_cmd_out.evict_tag = replacement_tag;
 
        mhu_state_n = WAIT_DMA_DONE;
      end

      // Wait for DMA to be done for load/store miss
      // It might already be done.
      WAIT_DMA_DONE: begin
        dma_ack_o = dma_done_i;

        curr_dma_cmd_n = dma_done_i
          ? dma_cmd_return
          : curr_dma_cmd_r;

        curr_dma_cmd_v_n = dma_done_i;

        set_dirty_n = 1'b0;
        counter_clear = 1'b1;

        mhu_state_n = dma_done_i
          ? DEQUEUE_MODE
          : WAIT_DMA_DONE;
      end 

      // Dequeue and process secondary miss.
      // When non-secondary is encounter, send out the next DMA.
      // At this time, there is no pending DMA.
      // If the FIFO is empty, then move to RECOVER, and update tag_and
      // stat_mem.
      // When the TL stage is block loading, we don't want to pause until it's
      // over.
      DEQUEUE_MODE: begin

        data_mem_pkt_v_o = miss_fifo_v_i & is_secondary & ~tl_block_loading_i;
        
        miss_fifo_yumi_o = data_mem_pkt_yumi_i
          & (miss_fifo_entry.block_load
            ? counter_max
            : 1'b1);

        miss_fifo_yumi_op_o = e_miss_fifo_dequeue;
 
        counter_up = data_mem_pkt_yumi_i
          & miss_fifo_entry.block_load & ~counter_max;
        counter_clear = data_mem_pkt_yumi_i
          & miss_fifo_entry.block_load & counter_max;

        stat_mem_pkt_v_o = ~tl_block_loading_i & (miss_fifo_empty_i | (miss_fifo_v_i & ~is_secondary));
        stat_mem_pkt.way_id = curr_dma_cmd_r.way_id; // dont care for read
        stat_mem_pkt.index = miss_fifo_empty_i
          ? curr_miss_index
          : miss_fifo_index;
        stat_mem_pkt.opcode = miss_fifo_empty_i  // dont care for read
          ? (set_dirty_r
            ? e_stat_set_lru_and_dirty
            : e_stat_set_lru_and_clear_dirty)
          : e_stat_read;

        tag_mem_pkt_v_o = ~tl_block_loading_i & (miss_fifo_empty_i | (miss_fifo_v_i & ~is_secondary));
        tag_mem_pkt.way_id = curr_dma_cmd_r.way_id; // dont care for read
        tag_mem_pkt.index = miss_fifo_empty_i
          ? curr_miss_index
          : miss_fifo_index;
        tag_mem_pkt.tag = curr_miss_tag; // dont care for read
        tag_mem_pkt.opcode = miss_fifo_empty_i
          ? e_tag_set_tag
          : e_tag_read;

        set_dirty_n = set_dirty_r 
          ? 1'b1
          : data_mem_pkt_yumi_i & miss_fifo_entry.write_not_read;

        mhu_state_n = tl_block_loading_i
          ? DEQUEUE_MODE
          : (miss_fifo_empty_i
            ? RECOVER
            : (miss_fifo_v_i
              ? (is_secondary ? DEQUEUE_MODE : READ_TAG2)
              : DEQUEUE_MODE));

      end

      // READ TAG2
      READ_TAG2: begin
        mhu_dff_en = 1'b1;
        recover_o = 1'b1;
        mhu_state_n = SEND_DMA_REQ2;
      end
      
      // Send the DMA for the next miss.
      // This recover may seem redundant, but we want to stall TL until the
      // dma_cmd has been sent out.
      SEND_DMA_REQ2: begin
        recover_o = 1'b1;
        dma_cmd_v_o = 1'b1;
        dma_cmd_out.way_id = replacement_way_id;
        dma_cmd_out.index = miss_fifo_index;
        dma_cmd_out.refill = 1'b1;
        dma_cmd_out.evict = replacement_dirty & replacement_valid;
        dma_cmd_out.refill_tag = miss_fifo_tag;
        dma_cmd_out.evict_tag = replacement_tag;

        counter_clear = 1'b1;

        mhu_state_n = SCAN_MODE;

      end

      // Scan for secondary misses, which is invalidated.
      // non-secondary misses are skipped instead.
      SCAN_MODE: begin

        data_mem_pkt_v_o = miss_fifo_v_i & is_secondary & ~tl_block_loading_i;

        miss_fifo_scan_not_dq_o = 1'b1;
        miss_fifo_yumi_o = miss_fifo_v_i & (is_secondary
          ? (data_mem_pkt_yumi_i
            & (miss_fifo_entry.block_load ? counter_max : 1'b1))
          : 1'b1);
        miss_fifo_yumi_op_o = is_secondary
          ? e_miss_fifo_invalidate
          : e_miss_fifo_skip;
 
        counter_up = data_mem_pkt_yumi_i
          & miss_fifo_entry.block_load & ~counter_max;
        counter_clear = data_mem_pkt_yumi_i
          & miss_fifo_entry.block_load & counter_max;
       
        stat_mem_pkt_v_o = miss_fifo_empty_i & ~tl_block_loading_i;
        stat_mem_pkt.way_id = curr_dma_cmd_r.way_id;
        stat_mem_pkt.index = curr_miss_index;
        stat_mem_pkt.opcode = set_dirty_r
          ? e_stat_set_lru_and_dirty
          : e_stat_set_lru_and_clear_dirty;

        tag_mem_pkt_v_o = miss_fifo_empty_i & ~tl_block_loading_i;
        tag_mem_pkt.way_id = curr_dma_cmd_r.way_id;
        tag_mem_pkt.index = curr_miss_index;
        tag_mem_pkt.tag = curr_miss_tag;
        tag_mem_pkt.opcode = e_tag_set_tag;
      
        set_dirty_n = set_dirty_r 
          ? 1'b1
          : data_mem_pkt_yumi_i & miss_fifo_entry.write_not_read;
 
        mhu_state_n = tl_block_loading_i
          ? SCAN_MODE
          : (miss_fifo_empty_i
            ? RECOVER
            : SCAN_MODE);

      end

      // Recover
      // TL stage will read the tag_mem.
      RECOVER: begin
        recover_o = 1'b1;
        miss_fifo_rollback_o = 1'b1;
        curr_dma_cmd_v_n = 1'b0;
        mhu_state_n = MHU_IDLE;
      end
      
      // this should never happen.
      default: begin
        mhu_state_n = MHU_IDLE;
      end

    endcase
       
  end


  // synopsys sync_set_reset "reset_i"
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      mhu_state_r <= MHU_IDLE; 
      curr_dma_cmd_r <= '0;
      curr_dma_cmd_v_r <= 1'b0;
      set_dirty_r <= 1'b0;
    end
    else begin
      mhu_state_r <= mhu_state_n;
      curr_dma_cmd_r <= curr_dma_cmd_n;
      curr_dma_cmd_v_r <= curr_dma_cmd_v_n;
      set_dirty_r <= set_dirty_n;
    end
  end

  // synopsys translate_off

  always_ff @ (negedge clk_i) begin
    if (~reset_i) begin
      if (dma_cmd_v_o)
        assert(~mhu_dff_r.lock[replacement_way_id]) 
          else $error("[BSG_ERROR] MHU cannot replace a locked way.");

      if (mhu_state_r == MHU_IDLE & mgmt_v_i)
        assert(~dma_done_i & ~dma_pending_i & ~miss_fifo_v_i)
          else $error("[BSG_ERROR] cache management op cannot enter the pipeline, when there is a pending load/store miss");
    
    end
  end

  // synopsys translate_on


endmodule
