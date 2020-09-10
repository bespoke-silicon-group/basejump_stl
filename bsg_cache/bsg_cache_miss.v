/**
 *  bsg_cache_miss.v
 *
 *  miss handling unit.
 *
 *  @author tommy
 *
 */

`include "bsg_defines.v"

module bsg_cache_miss
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="inv"
    ,parameter ways_p="inv"

    ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,parameter lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    ,parameter tag_width_lp=(addr_width_p-lg_data_mask_width_lp-lg_sets_lp-lg_block_size_in_words_lp)
    ,parameter tag_info_width_lp=`bsg_cache_tag_info_width(tag_width_lp)
    ,parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    ,parameter stat_info_width_lp=`bsg_cache_stat_info_width(ways_p)
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
    ,output bsg_cache_dma_cmd_e dma_cmd_o
    ,output logic [lg_ways_lp-1:0] dma_way_o
    ,output logic [addr_width_p-1:0] dma_addr_o
    ,input dma_done_i

    // from stat_mem
    ,input [stat_info_width_lp-1:0] stat_info_i

    // to stat_mem
    ,output logic stat_mem_v_o
    ,output logic stat_mem_w_o
    ,output logic [lg_sets_lp-1:0] stat_mem_addr_o
    ,output logic [stat_info_width_lp-1:0] stat_mem_data_o
    ,output logic [stat_info_width_lp-1:0] stat_mem_w_mask_o

    // to tag_mem
    ,output logic tag_mem_v_o
    ,output logic tag_mem_w_o
    ,output logic [lg_sets_lp-1:0] tag_mem_addr_o
    ,output logic [ways_p-1:0][tag_info_width_lp-1:0] tag_mem_data_o
    ,output logic [ways_p-1:0][tag_info_width_lp-1:0] tag_mem_w_mask_o

    // to pipeline
    ,output logic done_o
    ,output logic recover_o
    ,output logic [lg_ways_lp-1:0] chosen_way_o
    ,output logic select_snoop_data_r_o

    ,input ack_i
  );

  // stat/tag info
  //
  `declare_bsg_cache_tag_info_s(tag_width_lp);
  `declare_bsg_cache_stat_info_s(ways_p);

  bsg_cache_stat_info_s stat_info_in;
  assign stat_info_in = stat_info_i;

  bsg_cache_tag_info_s [ways_p-1:0] tag_mem_data_out, tag_mem_w_mask_out;
  bsg_cache_stat_info_s stat_mem_data_out, stat_mem_w_mask_out;
  
  assign tag_mem_data_o = tag_mem_data_out;
  assign stat_mem_data_o = stat_mem_data_out;

  assign tag_mem_w_mask_o = tag_mem_w_mask_out;
  assign stat_mem_w_mask_o = stat_mem_w_mask_out;

  // Find the way that is invalid.
  //
  logic [lg_ways_lp-1:0] invalid_way_id;
  logic invalid_exist;

  bsg_priority_encode #(
    .width_p(ways_p)
    ,.lo_to_hi_p(1)
  ) invalid_way_pe (
    .i(~valid_v_i & ~lock_v_i) // invalid and unlocked
    ,.addr_o(invalid_way_id)
    ,.v_o(invalid_exist)
  );

  // Encode lru bits
  //
  logic [lg_ways_lp-1:0] lru_way_id;

  bsg_lru_pseudo_tree_encode #(
    .ways_p(ways_p)
  ) lru_encode (
    .lru_i(stat_info_in.lru_bits)
    ,.way_id_o(lru_way_id)
  );

  // miss handler FSM
  //
  typedef enum logic [3:0] {
    START
    ,FLUSH_OP
    ,LOCK_OP
    ,SEND_EVICT_ADDR
    ,SEND_FILL_ADDR
    ,SEND_EVICT_DATA
    ,GET_FILL_DATA
    ,RECOVER
    ,DONE
  } miss_state_e;

  miss_state_e miss_state_r;
  miss_state_e miss_state_n;
  logic [lg_ways_lp-1:0] chosen_way_r, chosen_way_n;
  logic [lg_ways_lp-1:0] flush_way_r, flush_way_n;
  logic select_snoop_data_r, select_snoop_data_n;


  // for flush/inv ops, go to FLUSH_OP.
  // for AUNLOCK, or ALOCK with tag hit, to go LOCK_OP.
  logic goto_flush_op;
  logic goto_lock_op;

  assign goto_flush_op = decode_v_i.tagfl_op| decode_v_i.ainv_op| decode_v_i.afl_op| decode_v_i.aflinv_op;
  assign goto_lock_op = decode_v_i.aunlock_op | (decode_v_i.alock_op & tag_hit_found_i);

  logic [tag_width_lp-1:0] addr_tag_v;
  logic [lg_sets_lp-1:0] addr_index_v;
  logic [lg_ways_lp-1:0] addr_way_v;
  logic [lg_block_size_in_words_lp-1:0] addr_block_offset_v;

  assign addr_index_v
    = addr_v_i[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  assign addr_tag_v
    = addr_v_i[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp+:tag_width_lp];
  assign addr_way_v
    = addr_v_i[lg_sets_lp+lg_block_size_in_words_lp+lg_data_mask_width_lp+:lg_ways_lp];
  assign addr_block_offset_v
    = addr_v_i[lg_data_mask_width_lp+:lg_block_size_in_words_lp];

  assign stat_mem_addr_o = addr_index_v;
  assign tag_mem_addr_o = addr_index_v;

  assign chosen_way_o = chosen_way_r;

  assign dma_way_o = goto_flush_op
    ? flush_way_r
    : chosen_way_r;

  // chosen way lru decode
  //
  logic [ways_p-2:0] chosen_way_lru_data;
  logic [ways_p-2:0] chosen_way_lru_mask;

  bsg_lru_pseudo_tree_decode #(
    .ways_p(ways_p)
  ) chosen_way_lru_decode (
    .way_id_i(chosen_way_r)
    ,.data_o(chosen_way_lru_data)
    ,.mask_o(chosen_way_lru_mask)
  );

  // backup LRU
  // A slightly crude implementation. read the design doc for the better possibility.
  logic [lg_ways_lp-1:0] backup_lru_way_id;
  
  bsg_priority_encode #(
    .width_p(ways_p)
    ,.lo_to_hi_p(1)
  ) backup_lru_pe (
    .i(~lock_v_i)
    ,.addr_o(backup_lru_way_id)
    ,.v_o() // backup LRU has to exist, otherwise we are screwed.
  );

  // chosen way demux
  //
  logic [ways_p-1:0] chosen_way_decode;
  bsg_decode #(
    .num_out_p(ways_p)
  ) chosen_way_demux (
    .i(chosen_way_n)
    ,.o(chosen_way_decode)
  );

  // flush way demux
  logic [ways_p-1:0] addr_way_v_decode;
  bsg_decode #(
    .num_out_p(ways_p)
  ) addr_way_v_demux (
    .i(addr_way_v)
    ,.o(addr_way_v_decode)
  );
  
  logic [ways_p-1:0] flush_way_decode;
  assign flush_way_decode =  decode_v_i.tagfl_op
    ? addr_way_v_decode
    : tag_hit_v_i;

  assign select_snoop_data_r_o = select_snoop_data_r;

  always_comb begin

    stat_mem_v_o = 1'b0;
    stat_mem_w_o = 1'b0;
    stat_mem_data_out = '0;
    stat_mem_w_mask_out = '0;

    tag_mem_v_o = 1'b0;
    tag_mem_w_o = 1'b0;
    tag_mem_data_out = '0;
    tag_mem_w_mask_out = '0;

    chosen_way_n = chosen_way_r;
    flush_way_n = flush_way_r;

    dma_addr_o = '0;
    dma_cmd_o = e_dma_nop;

    recover_o = '0;
    done_o = '0;

    select_snoop_data_n = select_snoop_data_r;

    case (miss_state_r)

      // miss handler waits in this state, until the miss is detected in tv
      // stage.
      START: begin
        stat_mem_v_o = miss_v_i;
        miss_state_n = miss_v_i
          ? (goto_flush_op
            ? FLUSH_OP 
            : (goto_lock_op
              ? LOCK_OP
              : SEND_FILL_ADDR))
          : START;
      end

      // Send out the missing cache block address (to read).
      // Choose a block to replace/fill.
      // If the chosen block is dirty, then take evict route.
      SEND_FILL_ADDR: begin

        // Replacement Policy:
        // if an invalid and unlocked way exists, pick that.
        // if not, pick the LRU way. But if the LRU way is locked, then pick
        // the backup LRU (anything that's unlocked, assuming that we have at
        // least one unlocked way).
        chosen_way_n = invalid_exist
          ? invalid_way_id
          : (lock_v_i[lru_way_id]
            ? backup_lru_way_id
            : lru_way_id);

        dma_cmd_o = e_dma_send_fill_addr;
        dma_addr_o = {
          addr_tag_v,
          addr_index_v,
          {(lg_data_mask_width_lp+lg_block_size_in_words_lp){1'b0}}
        };


        // if the chosen way is dirty and valid, then evict.
        miss_state_n = dma_done_i
          ? ((stat_info_in.dirty[chosen_way_n] & valid_v_i[chosen_way_n])
            ? SEND_EVICT_ADDR
            : GET_FILL_DATA)
          : SEND_FILL_ADDR;
      end

      // Handling the cases for TAGFL, AINV, AFL, AFLINV.
      FLUSH_OP: begin

        // for TAGFL, pick whichever way set by the addr input.
        // Otherwise, pick the way with the tag hit.
        flush_way_n = decode_v_i.tagfl_op
          ? addr_way_v 
          : tag_hit_way_id_i;

        // Clear the dirty bit for the chosen set.
        // LRU bit does not need to be updated.
        stat_mem_v_o = 1'b1;
        stat_mem_w_o = 1'b1;
        stat_mem_data_out.dirty = {ways_p{1'b0}};
        stat_mem_data_out.lru_bits = {(ways_p-1){1'b0}};
        stat_mem_w_mask_out.dirty = flush_way_decode;
        stat_mem_w_mask_out.lru_bits = {(ways_p-1){1'b0}};

        // If it's invalidate op, then clear the valid bit for the chosen way.
        // Otherwise, do not touch the valid bits.
        tag_mem_v_o = 1'b1;
        tag_mem_w_o = 1'b1;

        for (integer i = 0; i < ways_p; i++) begin
          tag_mem_data_out[i].valid = 1'b0;
          tag_mem_data_out[i].lock = 1'b0;
          tag_mem_data_out[i].tag = {tag_width_lp{1'b0}};
          tag_mem_w_mask_out[i].valid = (decode_v_i.ainv_op | decode_v_i.aflinv_op) & flush_way_decode[i];
          tag_mem_w_mask_out[i].lock = (decode_v_i.ainv_op | decode_v_i.aflinv_op) & flush_way_decode[i];
          tag_mem_w_mask_out[i].tag =  {tag_width_lp{1'b0}};
        end

        // If it's not AINV, and the chosen set is dirty and valid, evict the
        // block.
        miss_state_n = (~decode_v_i.ainv_op & stat_info_in.dirty[flush_way_n] & valid_v_i[flush_way_n])
          ? SEND_EVICT_ADDR
          : RECOVER;
      end

      // handling AUNLOCK, and ALOCK with line not missing.
      LOCK_OP: begin
        tag_mem_v_o = 1'b1;
        tag_mem_w_o = 1'b1;

        for (integer i = 0; i < ways_p; i++) begin
          tag_mem_data_out[i].valid = 1'b0;
          tag_mem_data_out[i].lock = decode_v_i.alock_op;
          tag_mem_data_out[i].tag = {tag_width_lp{1'b0}};
          tag_mem_w_mask_out[i].valid = 1'b0;
          tag_mem_w_mask_out[i].lock = tag_hit_v_i[i];
          tag_mem_w_mask_out[i].tag = {tag_width_lp{1'b0}};
        end

        miss_state_n = RECOVER;
      end

      // Send out the block addr for eviction, before initiating the eviction.
      SEND_EVICT_ADDR: begin
        dma_cmd_o = e_dma_send_evict_addr;
        dma_addr_o = {
          tag_v_i[dma_way_o],
          addr_index_v,
          {(lg_data_mask_width_lp+lg_block_size_in_words_lp){1'b0}}
        };

        miss_state_n = dma_done_i
          ? SEND_EVICT_DATA
          : SEND_EVICT_ADDR;
      end

      // Set the DMA engine to evict the dirty block.
      // For the flush ops, go straight to RECOVER.
      SEND_EVICT_DATA: begin
        dma_cmd_o = sbuf_empty_i
          ? e_dma_send_evict_data
          : e_dma_nop;
        dma_addr_o = {
          tag_v_i[dma_way_o],
          addr_index_v,
          {(lg_data_mask_width_lp+lg_block_size_in_words_lp){1'b0}}
        };

        miss_state_n = dma_done_i
          ? ((decode_v_i.tagfl_op| decode_v_i.aflinv_op| decode_v_i.afl_op) ? RECOVER : GET_FILL_DATA)
          : SEND_EVICT_DATA;
      end

      // Set the DMA engine to start writing the new block to the data_mem.
      // Do not start until the store buffer is empty.
      GET_FILL_DATA: begin
        dma_cmd_o = sbuf_empty_i
          ? e_dma_get_fill_data
          : e_dma_nop;
        dma_addr_o = {
          addr_tag_v,
          addr_index_v,
          addr_block_offset_v, // used for snoop data in dma.
          {(lg_data_mask_width_lp){1'b0}}
        };

        // For store miss, set the dirty bit for the chosen way.
        // For load miss, clear the dirty bit for the chosen way.
        // Set the lru_bits, so that the chosen way is not the LRU.
        // We are choosing a way to bring in a new block, which is technically
        // the MRU. lru decode unit generates the next state LRU bits, so that
        // the input way is "not" the LRU way.
        stat_mem_v_o = dma_done_i;
        stat_mem_w_o = dma_done_i;
        stat_mem_data_out.dirty = {ways_p{decode_v_i.st_op | decode_v_i.atomic_op}};
        stat_mem_data_out.lru_bits = chosen_way_lru_data;
        stat_mem_w_mask_out.dirty = chosen_way_decode;
        stat_mem_w_mask_out.lru_bits = chosen_way_lru_mask;

        // set the tag and the valid bit to 1'b1 for the chosen way.
        tag_mem_v_o = dma_done_i;
        tag_mem_w_o = dma_done_i;

        for (integer i = 0; i < ways_p; i++) begin
          tag_mem_data_out[i].tag = addr_tag_v;
          tag_mem_data_out[i].lock = decode_v_i.alock_op;
          tag_mem_data_out[i].valid = 1'b1; 
          tag_mem_w_mask_out[i].tag = {tag_width_lp{chosen_way_decode[i]}};
          tag_mem_w_mask_out[i].lock = chosen_way_decode[i];
          tag_mem_w_mask_out[i].valid = chosen_way_decode[i];
        end

        select_snoop_data_n = dma_done_i
          ? 1'b1
          : select_snoop_data_r;

        miss_state_n = dma_done_i
          ? RECOVER
          : GET_FILL_DATA;
      end

      // Spend one cycle to recover the tl stage.
      // By recovering, it means re-reading the data_mem and tag_mem for the tl
      // stage.
      RECOVER: begin
        recover_o = 1'b1;
        miss_state_n = DONE;
      end

      // Miss handling is done. Output is valid.
      // Move onto next state, when the output data is taken.
      DONE: begin
        done_o = 1'b1;
        miss_state_n = ack_i ? START : DONE;
        select_snoop_data_n = ack_i ? 1'b0 : select_snoop_data_r;
      end

      // this should never happen, but if it does, go back to START;
      default: begin
        miss_state_n = START;
      end

    endcase
  end

  // synopsys sync_set_reset "reset_i"
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      miss_state_r <= START;
      chosen_way_r <= '0;
      flush_way_r <= '0;
      select_snoop_data_r <= 1'b0;
      // added to be a little more X pessimism conservative
    end
    else begin
      miss_state_r <= miss_state_n;
      chosen_way_r <= chosen_way_n;
      flush_way_r <= flush_way_n;
      select_snoop_data_r <= select_snoop_data_n;
    end
  end

endmodule
