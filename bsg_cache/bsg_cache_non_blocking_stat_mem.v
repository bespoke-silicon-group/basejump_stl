/**
 *    bsg_cache_non_blocking_stat_mem.v
 *
 *    stat_mem and peripheral circuits
 *
 *    @author tommy
 *
 */


`include "bsg_defines.v"

module bsg_cache_non_blocking_stat_mem
  import bsg_cache_non_blocking_pkg::*;
  #(parameter ways_p="inv"
    , parameter sets_p="inv"

    , parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)

    , parameter stat_mem_pkt_width_lp=
      `bsg_cache_non_blocking_stat_mem_pkt_width(ways_p,sets_p)
  )
  (
    input clk_i
    , input reset_i
    
    , input v_i
    , input [stat_mem_pkt_width_lp-1:0] stat_mem_pkt_i

    , output logic [ways_p-1:0] dirty_o
    , output logic [ways_p-2:0] lru_bits_o
  );


  // localparam
  //
  localparam stat_info_width_lp = `bsg_cache_non_blocking_stat_info_width(ways_p);

  // stat_mem_pkt
  //
  `declare_bsg_cache_non_blocking_stat_mem_pkt_s(ways_p,sets_p);
  bsg_cache_non_blocking_stat_mem_pkt_s stat_mem_pkt;
  assign stat_mem_pkt = stat_mem_pkt_i;

  // stat_mem
  //
  `declare_bsg_cache_non_blocking_stat_info_s(ways_p);
  bsg_cache_non_blocking_stat_info_s data_li, data_lo, mask_li;
  logic w_li;

  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p(stat_info_width_lp)
    ,.els_p(sets_p)
    ,.latch_last_read_p(1)
  ) stat_mem (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.v_i(v_i)
    ,.w_i(w_li)

    ,.addr_i(stat_mem_pkt.index)
    ,.w_mask_i(mask_li)
    ,.data_i(data_li)
    ,.data_o(data_lo)
  );


  // input logic
  //
  logic [ways_p-1:0] way_decode_lo;

  bsg_decode #(
    .num_out_p(ways_p)
  ) way_demux (
    .i(stat_mem_pkt.way_id)
    ,.o(way_decode_lo)
  );  

  logic [ways_p-2:0] lru_decode_data_lo;
  logic [ways_p-2:0] lru_decode_mask_lo;

  bsg_lru_pseudo_tree_decode #(
    .ways_p(ways_p)
  ) lru_decode (
    .way_id_i(stat_mem_pkt.way_id)
    ,.data_o(lru_decode_data_lo)
    ,.mask_o(lru_decode_mask_lo)
  );


  always_comb begin

    w_li = 1'b0;
    data_li.lru_bits = '0;
    mask_li.lru_bits = '0;
    data_li.dirty = '0;
    mask_li.dirty = '0;

    case (stat_mem_pkt.opcode)

      // read the stat_mem.
      e_stat_read: begin
        w_li = 1'b0;
        data_li.lru_bits = '0;
        mask_li.lru_bits = '0;
        data_li.dirty = '0;
        mask_li.dirty = '0;
      end

      // clear dirty bit for the block, chosen by index and way_id.
      e_stat_clear_dirty: begin
        w_li = 1'b1;
        data_li.lru_bits = '0;
        mask_li.lru_bits = '0;
        data_li.dirty = '0;
        mask_li.dirty = way_decode_lo;
      end

      // set LRU so that the chosen block is not LRU.
      e_stat_set_lru: begin
        w_li = 1'b1;
        data_li.lru_bits = lru_decode_data_lo;
        mask_li.lru_bits = lru_decode_mask_lo;
        data_li.dirty = '0;
        mask_li.dirty = '0;
      end

      // set LRU so that the chosen block is not LRU.
      // Also, set the dirty bit.
      e_stat_set_lru_and_dirty: begin
        w_li = 1'b1;
        data_li.lru_bits = lru_decode_data_lo;
        mask_li.lru_bits = lru_decode_mask_lo;
        data_li.dirty = {ways_p{1'b1}};
        mask_li.dirty = way_decode_lo;
      end

      // set LRU so that the chosen block is not LRU.
      // Also, clear the dirty bit.
      e_stat_set_lru_and_clear_dirty: begin
        w_li = 1'b1;
        data_li.lru_bits = lru_decode_data_lo;
        mask_li.lru_bits = lru_decode_mask_lo;
        data_li.dirty = {ways_p{1'b0}};
        mask_li.dirty = way_decode_lo;
      end

      // resets the LRU to zero, and clear the dirty bits of chosen way.
      e_stat_reset: begin
        w_li = 1'b1;
        data_li.lru_bits = '0;
        mask_li.lru_bits = {(ways_p-1){1'b1}};
        data_li.dirty = '0;
        mask_li.dirty = way_decode_lo;
      end
    
      default: begin
        // this should never be used.
      end

    endcase

  end

  
  // output logic
  //
  assign lru_bits_o = data_lo.lru_bits;
  assign dirty_o = data_lo.dirty;


endmodule
