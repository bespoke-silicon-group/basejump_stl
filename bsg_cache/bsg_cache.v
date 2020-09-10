/**
 *  bsg_cache.v
 *
 *  - two-stage pipelined.
 *  - n-way set associative.
 *  - pseudo-tree LRU replacement policy.
 *  - write-back, write-allocate
 *
 *  @author tommy
 * 
 *  See https://docs.google.com/document/d/1AIjhuwTbOYwyZHdu-Uc4dr9Fwxi6ZKscKSGTiUeQEYo/edit for design doc
 */


`include "bsg_defines.v"

module bsg_cache
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"  // byte addr
    ,parameter data_width_p="inv" // word size
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="inv"
    ,parameter ways_p="inv"

    ,parameter amo_support_p=(1 << e_cache_amo_swap)
                             | (1 << e_cache_amo_or)

    // dma burst width
    ,parameter dma_data_width_p=data_width_p // default value. it can also be pow2 multiple of data_width_p.

    ,parameter bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(addr_width_p,data_width_p)
    ,parameter bsg_cache_dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)

    ,parameter debug_p=0
  )
  (
    input clk_i
    ,input reset_i

    ,input [bsg_cache_pkt_width_lp-1:0] cache_pkt_i
    ,input v_i
    ,output logic ready_o
    
    ,output logic [data_width_p-1:0] data_o
    ,output logic v_o
    ,input yumi_i

    ,output logic [bsg_cache_dma_pkt_width_lp-1:0] dma_pkt_o
    ,output logic dma_pkt_v_o
    ,input dma_pkt_yumi_i

    ,input [dma_data_width_p-1:0] dma_data_i
    ,input dma_data_v_i
    ,output logic dma_data_ready_o

    ,output logic [dma_data_width_p-1:0] dma_data_o
    ,output logic dma_data_v_o
    ,input dma_data_yumi_i

    // this signal tells the outside world that the instruction is moving from
    // TL to TV stage. It can be used for some metadata outside the cache that
    // needs to move together with the corresponding instruction. The usage of
    // this signal is totally optional.
    ,output logic v_we_o
  );


  // localparam
  //
  localparam lg_sets_lp=`BSG_SAFE_CLOG2(sets_p);
  localparam data_mask_width_lp=(data_width_p>>3);
  localparam lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_mask_width_lp);
  localparam lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p);
  localparam tag_width_lp=(addr_width_p-lg_data_mask_width_lp-lg_sets_lp-lg_block_size_in_words_lp);
  localparam tag_info_width_lp=`bsg_cache_tag_info_width(tag_width_lp);
  localparam lg_ways_lp=`BSG_SAFE_CLOG2(ways_p);
  localparam stat_info_width_lp = `bsg_cache_stat_info_width(ways_p);
  localparam data_sel_mux_els_lp = `BSG_MIN(4,lg_data_mask_width_lp+1);
  localparam lg_data_sel_mux_els_lp = `BSG_SAFE_CLOG2(data_sel_mux_els_lp);

  localparam burst_size_in_words_lp=(dma_data_width_p/data_width_p);
  localparam lg_burst_size_in_words_lp=`BSG_SAFE_CLOG2(burst_size_in_words_lp);
  localparam burst_len_lp=(block_size_in_words_p*data_width_p/dma_data_width_p);
  localparam lg_burst_len_lp=`BSG_SAFE_CLOG2(burst_len_lp);
  localparam dma_data_mask_width_lp=(dma_data_width_p>>3);
  localparam data_mem_els_lp = sets_p*burst_len_lp;
  localparam lg_data_mem_els_lp = `BSG_SAFE_CLOG2(data_mem_els_lp);


  // instruction decoding
  //
  logic [lg_ways_lp-1:0] addr_way;
  logic [lg_sets_lp-1:0] addr_index;
  logic [lg_block_size_in_words_lp-1:0] addr_block_offset;

  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);
  bsg_cache_pkt_s cache_pkt;

  assign cache_pkt = cache_pkt_i;

  bsg_cache_decode_s decode;

  bsg_cache_decode decode0 (
    .opcode_i(cache_pkt.opcode)
    ,.decode_o(decode)
  );

  assign addr_way
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp+:lg_ways_lp];
  assign addr_index
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  assign addr_block_offset
    = cache_pkt.addr[lg_data_mask_width_lp+:lg_block_size_in_words_lp];

  logic [lg_data_mem_els_lp-1:0] ld_data_mem_addr;

  if (burst_len_lp == 1) begin
    assign ld_data_mem_addr = addr_index;
  end
  else if (burst_len_lp == block_size_in_words_p) begin
    assign ld_data_mem_addr = {addr_index, cache_pkt.addr[lg_data_mask_width_lp+:lg_block_size_in_words_lp]};
  end
  else begin
    assign ld_data_mem_addr = {addr_index, cache_pkt.addr[lg_data_mask_width_lp+lg_burst_size_in_words_lp+:lg_burst_len_lp]};
  end


  // tl_stage
  //
  logic v_tl_r;
  bsg_cache_decode_s decode_tl_r;
  logic [data_mask_width_lp-1:0] mask_tl_r;
  logic [addr_width_p-1:0] addr_tl_r;
  logic [data_width_p-1:0] data_tl_r;
  logic sbuf_hazard;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_tl_r <= 1'b0;
      {mask_tl_r
      ,addr_tl_r
      ,data_tl_r
      ,decode_tl_r} <= '0;
    end
    else begin
      if (ready_o) begin
        v_tl_r <= v_i;
        if (v_i) begin
          mask_tl_r <= cache_pkt.mask;
          addr_tl_r <= cache_pkt.addr;
          data_tl_r <= cache_pkt.data;
          decode_tl_r <= decode;
        end
      end
      else begin
        if (sbuf_hazard)
          v_tl_r <= 1'b0;
      end
    end
  end

  logic [lg_sets_lp-1:0] addr_index_tl;
  logic [lg_block_size_in_words_lp-1:0] addr_block_offset_tl;

  assign addr_index_tl =
    addr_tl_r[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];

  assign addr_block_offset_tl =
    addr_tl_r[lg_data_mask_width_lp+:lg_block_size_in_words_lp];

  logic [lg_data_mem_els_lp-1:0] recover_data_mem_addr;

  if (burst_len_lp == 1) begin
    assign recover_data_mem_addr = addr_index_tl;
  end
  else if (burst_len_lp == block_size_in_words_p) begin
    assign recover_data_mem_addr = {addr_index_tl, addr_tl_r[lg_data_mask_width_lp+:lg_block_size_in_words_lp]};
  end
  else begin
    assign recover_data_mem_addr = {addr_index_tl, addr_tl_r[lg_data_mask_width_lp+lg_burst_size_in_words_lp+:lg_burst_len_lp]};
  end


  // tag_mem
  //
  `declare_bsg_cache_tag_info_s(tag_width_lp);

  logic tag_mem_v_li;
  logic tag_mem_w_li;
  logic [lg_sets_lp-1:0] tag_mem_addr_li;
  bsg_cache_tag_info_s [ways_p-1:0] tag_mem_data_li;
  bsg_cache_tag_info_s [ways_p-1:0] tag_mem_w_mask_li;
  bsg_cache_tag_info_s [ways_p-1:0] tag_mem_data_lo;
  
  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p(tag_info_width_lp*ways_p)
    ,.els_p(sets_p)
    ,.latch_last_read_p(1)
  ) tag_mem (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i(tag_mem_v_li)
    ,.w_i(tag_mem_w_li)
    ,.addr_i(tag_mem_addr_li)
    ,.data_i(tag_mem_data_li)
    ,.w_mask_i(tag_mem_w_mask_li)
    ,.data_o(tag_mem_data_lo)
  );

  logic [ways_p-1:0] valid_tl;
  logic [ways_p-1:0][tag_width_lp-1:0] tag_tl;
  logic [ways_p-1:0] lock_tl;

  for (genvar i = 0; i < ways_p; i++) begin
    assign valid_tl[i] = tag_mem_data_lo[i].valid;
    assign tag_tl[i] = tag_mem_data_lo[i].tag;
    assign lock_tl[i] = tag_mem_data_lo[i].lock;
  end
 

  // data_mem
  //
  logic data_mem_v_li;
  logic data_mem_w_li;
  logic [lg_data_mem_els_lp-1:0] data_mem_addr_li;
  logic [ways_p-1:0][dma_data_width_p-1:0] data_mem_data_li;
  logic [ways_p-1:0][dma_data_mask_width_lp-1:0] data_mem_w_mask_li;
  logic [ways_p-1:0][dma_data_width_p-1:0] data_mem_data_lo;

  bsg_mem_1rw_sync_mask_write_byte #(
    .data_width_p(dma_data_width_p*ways_p)
    ,.els_p(data_mem_els_lp)
    ,.latch_last_read_p(1)
  ) data_mem (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i(data_mem_v_li)
    ,.w_i(data_mem_w_li)
    ,.addr_i(data_mem_addr_li)
    ,.data_i(data_mem_data_li)
    ,.write_mask_i(data_mem_w_mask_li)
    ,.data_o(data_mem_data_lo)
  );

  // v stage
  //
  logic v_we;
  logic v_v_r;
  bsg_cache_decode_s decode_v_r;
  logic [data_mask_width_lp-1:0] mask_v_r;
  logic [addr_width_p-1:0] addr_v_r;
  logic [data_width_p-1:0] data_v_r;
  logic [ways_p-1:0] valid_v_r;
  logic [ways_p-1:0] lock_v_r;
  logic [ways_p-1:0][tag_width_lp-1:0] tag_v_r;
  logic [ways_p-1:0][dma_data_width_p-1:0] ld_data_v_r;
  logic retval_op_v;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_v_r <= 1'b0;
      {mask_v_r
      ,decode_v_r
      ,addr_v_r
      ,data_v_r
      ,valid_v_r
      ,lock_v_r
      ,tag_v_r} <= '0;
    end
    else begin
      if (v_we) begin
        v_v_r <= v_tl_r;
        if (v_tl_r) begin
          mask_v_r <= mask_tl_r;
          decode_v_r <= decode_tl_r;
          addr_v_r <= addr_tl_r;
          data_v_r <= data_tl_r;
          valid_v_r <= valid_tl;
          tag_v_r <= tag_tl;
          lock_v_r <= lock_tl;
          ld_data_v_r <= data_mem_data_lo;
        end
      end
    end
  end

  assign v_we_o = v_we;
  
  logic [tag_width_lp-1:0] addr_tag_v;
  logic [lg_sets_lp-1:0] addr_index_v;
  logic [lg_ways_lp-1:0] addr_way_v; 
  logic [ways_p-1:0] tag_hit_v;

  assign addr_tag_v =
    addr_v_r[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp+:tag_width_lp];
  assign addr_index_v =
    addr_v_r[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  assign addr_way_v =
    addr_v_r[lg_sets_lp+lg_block_size_in_words_lp+lg_data_mask_width_lp+:lg_ways_lp];

  for (genvar i = 0; i < ways_p; i++) begin
    assign tag_hit_v[i] = (addr_tag_v == tag_v_r[i]) & valid_v_r[i];
  end


  logic [lg_ways_lp-1:0] tag_hit_way_id;
  logic tag_hit_found;

  bsg_priority_encode #(
    .width_p(ways_p)
    ,.lo_to_hi_p(1)
  ) tag_hit_pe (
    .i(tag_hit_v)
    ,.addr_o(tag_hit_way_id)
    ,.v_o(tag_hit_found)
  );

  wire ld_st_miss = ~tag_hit_found & (decode_v_r.ld_op | decode_v_r.st_op);
  wire tagfl_hit = decode_v_r.tagfl_op & valid_v_r[addr_way_v];
  wire aflinv_hit = (decode_v_r.afl_op | decode_v_r.aflinv_op| decode_v_r.ainv_op) & tag_hit_found;
  wire alock_miss = decode_v_r.alock_op & (tag_hit_found ? ~lock_v_r[tag_hit_way_id] : 1'b1);   // either the line is miss, or the line is unlocked.
  wire aunlock_hit = decode_v_r.aunlock_op & (tag_hit_found ? lock_v_r[tag_hit_way_id] : 1'b0); // the line is hit and locked. 
  wire atomic_miss = decode_v_r.atomic_op & ~tag_hit_found;

  // miss_v signal activates the miss handling unit.
  // MBT: the ~decode_v_r.tagst_op is necessary at the top of this expression
  //      to avoid X-pessimism post synthesis due to X's coming out of the tags
  wire miss_v = (~decode_v_r.tagst_op) & v_v_r
    & (ld_st_miss | tagfl_hit | aflinv_hit | alock_miss | aunlock_hit | atomic_miss);
  
  // ops that return some value other than '0.
  assign retval_op_v = decode_v_r.ld_op | decode_v_r.taglv_op | decode_v_r.tagla_op | decode_v_r.atomic_op; 

  // stat_mem
  //
  `declare_bsg_cache_stat_info_s(ways_p);  

  logic stat_mem_v_li;
  logic stat_mem_w_li;
  logic [lg_sets_lp-1:0] stat_mem_addr_li;
  bsg_cache_stat_info_s stat_mem_data_li;
  bsg_cache_stat_info_s stat_mem_w_mask_li;
  bsg_cache_stat_info_s stat_mem_data_lo;

  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p(stat_info_width_lp)
    ,.els_p(sets_p)
    ,.latch_last_read_p(1)
  ) stat_mem (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i(stat_mem_v_li)
    ,.w_i(stat_mem_w_li)
    ,.addr_i(stat_mem_addr_li)
    ,.data_i(stat_mem_data_li)
    ,.w_mask_i(stat_mem_w_mask_li)
    ,.data_o(stat_mem_data_lo)
  );
 
  // miss handler
  //
  bsg_cache_dma_cmd_e dma_cmd_lo;
  logic [addr_width_p-1:0] dma_addr_lo;
  logic [lg_ways_lp-1:0] dma_way_lo;
  logic dma_done_li;

  logic recover_lo;
  logic miss_done_lo;

  logic miss_stat_mem_v_lo;
  logic miss_stat_mem_w_lo;
  logic [lg_sets_lp-1:0] miss_stat_mem_addr_lo;
  bsg_cache_stat_info_s miss_stat_mem_data_lo;
  bsg_cache_stat_info_s miss_stat_mem_w_mask_lo;

  logic miss_tag_mem_v_lo;
  logic miss_tag_mem_w_lo;
  logic [lg_sets_lp-1:0] miss_tag_mem_addr_lo;
  bsg_cache_tag_info_s [ways_p-1:0] miss_tag_mem_data_lo;
  bsg_cache_tag_info_s [ways_p-1:0] miss_tag_mem_w_mask_lo;

  logic sbuf_empty_li;
  logic [lg_ways_lp-1:0] chosen_way_lo;
  logic select_snoop_data_r_lo;

  bsg_cache_miss #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.sets_p(sets_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.ways_p(ways_p)
  ) miss (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.miss_v_i(miss_v)
    ,.decode_v_i(decode_v_r)
    ,.addr_v_i(addr_v_r)

    ,.tag_v_i(tag_v_r)
    ,.valid_v_i(valid_v_r)
    ,.lock_v_i(lock_v_r)
    ,.tag_hit_way_id_i(tag_hit_way_id)
    ,.tag_hit_v_i(tag_hit_v)
    ,.tag_hit_found_i(tag_hit_found)

    ,.sbuf_empty_i(sbuf_empty_li)
 
    ,.dma_cmd_o(dma_cmd_lo) 
    ,.dma_way_o(dma_way_lo)
    ,.dma_addr_o(dma_addr_lo)
    ,.dma_done_i(dma_done_li)

    ,.stat_info_i(stat_mem_data_lo)

    ,.stat_mem_v_o(miss_stat_mem_v_lo)
    ,.stat_mem_w_o(miss_stat_mem_w_lo)
    ,.stat_mem_addr_o(miss_stat_mem_addr_lo)
    ,.stat_mem_data_o(miss_stat_mem_data_lo)
    ,.stat_mem_w_mask_o(miss_stat_mem_w_mask_lo)
    
    ,.tag_mem_v_o(miss_tag_mem_v_lo)
    ,.tag_mem_w_o(miss_tag_mem_w_lo)
    ,.tag_mem_addr_o(miss_tag_mem_addr_lo)
    ,.tag_mem_data_o(miss_tag_mem_data_lo)
    ,.tag_mem_w_mask_o(miss_tag_mem_w_mask_lo)

    ,.recover_o(recover_lo)
    ,.done_o(miss_done_lo) 

    ,.chosen_way_o(chosen_way_lo)
    
    ,.ack_i(v_o & yumi_i) 
    ,.select_snoop_data_r_o(select_snoop_data_r_lo)
  );

  // dma
  // 
  logic [data_width_p-1:0] snoop_word_lo;
  logic dma_data_mem_v_lo;
  logic dma_data_mem_w_lo;
  logic [lg_data_mem_els_lp-1:0] dma_data_mem_addr_lo;
  logic [ways_p-1:0][dma_data_mask_width_lp-1:0] dma_data_mem_w_mask_lo;
  logic [ways_p-1:0][dma_data_width_p-1:0] dma_data_mem_data_lo;
  logic dma_evict_lo;

  bsg_cache_dma #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
    ,.dma_data_width_p(dma_data_width_p)
    ,.debug_p(debug_p)
  ) dma (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
   
    ,.dma_cmd_i(dma_cmd_lo)
    ,.dma_way_i(dma_way_lo)
    ,.dma_addr_i(dma_addr_lo)
    ,.done_o(dma_done_li)

    ,.snoop_word_o(snoop_word_lo)
    
    ,.dma_pkt_o(dma_pkt_o)
    ,.dma_pkt_v_o(dma_pkt_v_o)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_i)

    ,.dma_data_i(dma_data_i)
    ,.dma_data_v_i(dma_data_v_i)
    ,.dma_data_ready_o(dma_data_ready_o)
    
    ,.dma_data_o(dma_data_o)
    ,.dma_data_v_o(dma_data_v_o)
    ,.dma_data_yumi_i(dma_data_yumi_i)

    ,.data_mem_v_o(dma_data_mem_v_lo)
    ,.data_mem_w_o(dma_data_mem_w_lo)
    ,.data_mem_addr_o(dma_data_mem_addr_lo)
    ,.data_mem_w_mask_o(dma_data_mem_w_mask_lo)
    ,.data_mem_data_o(dma_data_mem_data_lo)
    ,.data_mem_data_i(data_mem_data_lo)
    
    ,.dma_evict_o(dma_evict_lo)
  ); 

  // store buffer
  //
  `declare_bsg_cache_sbuf_entry_s(addr_width_p, data_width_p, ways_p);

  logic sbuf_v_li;
  bsg_cache_sbuf_entry_s sbuf_entry_li;

  logic sbuf_v_lo;
  logic sbuf_yumi_li;
  bsg_cache_sbuf_entry_s sbuf_entry_lo;

  logic [addr_width_p-1:0] bypass_addr_li;
  logic bypass_v_li;
  logic [data_width_p-1:0] bypass_data_lo;
  logic [data_mask_width_lp-1:0] bypass_mask_lo;
  logic sbuf_full_lo;

  bsg_cache_sbuf #(
    .data_width_p(data_width_p)
    ,.addr_width_p(addr_width_p)
    ,.ways_p(ways_p)
  ) sbuf (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.sbuf_entry_i(sbuf_entry_li)
    ,.v_i(sbuf_v_li)

    ,.sbuf_entry_o(sbuf_entry_lo)
    ,.v_o(sbuf_v_lo)
    ,.yumi_i(sbuf_yumi_li)

    ,.empty_o(sbuf_empty_li)
    ,.full_o(sbuf_full_lo)

    ,.bypass_addr_i(bypass_addr_li)
    ,.bypass_v_i(bypass_v_li)
    ,.bypass_data_o(bypass_data_lo)
    ,.bypass_mask_o(bypass_mask_lo)
  ); 

  logic [ways_p-1:0] sbuf_way_decode;

  bsg_decode #(
    .num_out_p(ways_p)
  ) sbuf_way_demux (
    .i(sbuf_entry_lo.way_id)
    ,.o(sbuf_way_decode)
  );

  logic [burst_size_in_words_lp-1:0] sbuf_burst_offset_decode;
  bsg_decode #(
    .num_out_p(burst_size_in_words_lp)
  ) sbuf_bo_demux (
    .i(sbuf_entry_lo.addr[lg_data_mask_width_lp+:lg_burst_size_in_words_lp])
    ,.o(sbuf_burst_offset_decode)
  );

  logic [dma_data_mask_width_lp-1:0] sbuf_expand_mask;
  bsg_expand_bitmask #(
    .in_width_p(burst_size_in_words_lp)
    ,.expand_p(data_mask_width_lp)
  ) expand0 (
    .i(sbuf_burst_offset_decode)
    ,.o(sbuf_expand_mask)
  );

  logic [ways_p-1:0][dma_data_mask_width_lp-1:0] sbuf_data_mem_w_mask;
  logic [ways_p-1:0][dma_data_width_p-1:0] sbuf_data_mem_data;
  logic [lg_data_mem_els_lp-1:0] sbuf_data_mem_addr;

  for (genvar i = 0 ; i < ways_p; i++) begin
    assign sbuf_data_mem_data[i] = {burst_size_in_words_lp{sbuf_entry_lo.data}};
    assign sbuf_data_mem_w_mask[i] = sbuf_way_decode[i]
      ? (sbuf_expand_mask & {burst_size_in_words_lp{sbuf_entry_lo.mask}})
      : '0;
  end
  if (burst_len_lp == 1) begin
    assign sbuf_data_mem_addr = sbuf_entry_lo.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  end 
  else if (burst_len_lp == block_size_in_words_p) begin
    assign sbuf_data_mem_addr = sbuf_entry_lo.addr[lg_data_mask_width_lp+:lg_block_size_in_words_lp+lg_sets_lp];
  end
  else begin
    assign sbuf_data_mem_addr = sbuf_entry_lo.addr[lg_data_mask_width_lp+lg_burst_size_in_words_lp+:lg_burst_len_lp+lg_sets_lp];
  end


  // store buffer data/mask input
  //
  logic [data_sel_mux_els_lp-1:0][data_width_p-1:0] sbuf_data_in_mux_li;
  logic [data_sel_mux_els_lp-1:0][data_mask_width_lp-1:0] sbuf_mask_in_mux_li;
  logic [data_width_p-1:0] sbuf_data_in;
  logic [data_mask_width_lp-1:0] sbuf_mask_in;
  logic [data_width_p-1:0] snoop_or_ld_data;
  logic [data_sel_mux_els_lp-1:0][data_width_p-1:0] ld_data_final_li;
  logic [data_width_p-1:0] ld_data_final_lo;

  bsg_mux #(
    .width_p(data_width_p)
    ,.els_p(data_sel_mux_els_lp)
  ) sbuf_data_in_mux (
    .data_i(sbuf_data_in_mux_li)
    ,.sel_i(decode_v_r.data_size_op[0+:lg_data_sel_mux_els_lp])
    ,.data_o(sbuf_data_in)
  );

  bsg_mux #(
    .width_p(data_mask_width_lp)
    ,.els_p(data_sel_mux_els_lp)
  ) sbuf_mask_in_mux (
    .data_i(sbuf_mask_in_mux_li)
    ,.sel_i(decode_v_r.data_size_op[0+:lg_data_sel_mux_els_lp])
    ,.data_o(sbuf_mask_in)
  );

  //
  // Atomic operations
  //   Defined only for 32/64 operations
  // Data incoming from cache_pkt
  logic [`BSG_MIN(data_width_p, 64)-1:0] atomic_reg_data;
  // Data read from the cache line
  logic [`BSG_MIN(data_width_p, 64)-1:0] atomic_mem_data;
  // Result of the atomic
  logic [`BSG_MIN(data_width_p, 64)-1:0] atomic_alu_result;
  // Final atomic data for store buffer
  logic [`BSG_MIN(data_width_p, 64)-1:0] atomic_result;

  // Shift data to high bits for operations less than 64-bits
  // This allows us to share the arithmetic operators for 32/64 bit atomics
  if (data_width_p >= 64) begin : atomic_64
    wire [63:0] amo32_reg_in = data_v_r[0+:32] << 32;
    wire [63:0] amo64_reg_in = data_v_r[0+:64];
    assign atomic_reg_data = decode_v_r.data_size_op[0] ? amo64_reg_in : amo32_reg_in;

    wire [63:0] amo32_mem_in = ld_data_final_li[2] << 32;
    wire [63:0] amo64_mem_in = ld_data_final_li[3];
    assign atomic_mem_data = decode_v_r.data_size_op[0] ? amo64_mem_in : amo32_mem_in;
  end
  else if (data_width_p >= 32) begin : atomic_32
    assign atomic_reg_data = data_v_r[0+:32];
    assign atomic_mem_data = ld_data_final_li[2];
  end

  // Atomic ALU
  always_comb begin
    // This logic was confirmed not to synthesize unsupported operators in
    //   Synopsys DC O-2018.06-SP4
    unique casez({amo_support_p[decode_v_r.amo_subop], decode_v_r.amo_subop})
      {1'b1, e_cache_amo_swap}: atomic_alu_result = atomic_reg_data;
      {1'b1, e_cache_amo_and }: atomic_alu_result = atomic_reg_data & atomic_mem_data;
      {1'b1, e_cache_amo_or  }: atomic_alu_result = atomic_reg_data | atomic_mem_data;
      {1'b1, e_cache_amo_xor }: atomic_alu_result = atomic_reg_data ^ atomic_mem_data;
      {1'b1, e_cache_amo_add }: atomic_alu_result = atomic_reg_data + atomic_mem_data;
      {1'b1, e_cache_amo_min }: atomic_alu_result =
          ($signed(atomic_reg_data) < $signed(atomic_mem_data)) ? atomic_reg_data : atomic_mem_data;
      {1'b1, e_cache_amo_max }: atomic_alu_result =
          ($signed(atomic_reg_data) > $signed(atomic_mem_data)) ? atomic_reg_data : atomic_mem_data;
      {1'b1, e_cache_amo_minu}: atomic_alu_result =
          (atomic_reg_data < atomic_mem_data) ? atomic_reg_data : atomic_mem_data;
      {1'b1, e_cache_amo_maxu}: atomic_alu_result =
          (atomic_reg_data > atomic_mem_data) ? atomic_reg_data : atomic_mem_data;
      // Noisily fail in simulation if an unsupported AMO operation is requested
      {1'b0, 4'b????         }: atomic_alu_result = `BSG_UNDEFINED_IN_SIM(0);
      default: atomic_alu_result = '0;
    endcase
  end

  // Shift data from high bits for operations less than 64-bits
  if (data_width_p >= 64) begin : fi
    wire [63:0] amo32_out = atomic_alu_result >> 32;
    wire [63:0] amo64_out = atomic_alu_result;
    assign atomic_result = decode_v_r.data_size_op[0] ? amo64_out : amo32_out;
  end
  else begin
    assign atomic_result = atomic_alu_result;
  end

  for (genvar i = 0; i < data_sel_mux_els_lp; i++) begin: sbuf_in_sel
    localparam slice_width_lp = (8*(2**i));

    logic [slice_width_lp-1:0] slice_data;

    // AMO computation
    // AMOs are only supported for words and double words
    if ((i == 2'b10) || (i == 2'b11)) begin: atomic_in_sel
      assign slice_data = decode_v_r.atomic_op
        ? atomic_result[0+:slice_width_lp]
        : data_v_r[0+:slice_width_lp];
    end 
    else begin
      assign slice_data = data_v_r[0+:slice_width_lp];
    end

    assign sbuf_data_in_mux_li[i] = {(data_width_p/slice_width_lp){slice_data}};

    if (i == data_sel_mux_els_lp-1) begin: max_size
      assign sbuf_mask_in_mux_li[i] = {data_mask_width_lp{1'b1}};    
    end 
    else begin: non_max_size

      logic [(data_width_p/slice_width_lp)-1:0] decode_lo;

      bsg_decode #(
        .num_out_p(data_width_p/slice_width_lp)
      ) dec (
        .i(addr_v_r[i+:`BSG_MAX(lg_data_mask_width_lp-i,1)])
        ,.o(decode_lo)
      );

      bsg_expand_bitmask #(
        .in_width_p(data_width_p/slice_width_lp)
        ,.expand_p(2**i)
      ) exp (
        .i(decode_lo)
        ,.o(sbuf_mask_in_mux_li[i])
      );

    end
  end

  // store buffer data,mask input
  always_comb begin
    if (decode_v_r.mask_op) begin
      sbuf_entry_li.data = data_v_r;
      sbuf_entry_li.mask = mask_v_r;
    end
    else begin
      sbuf_entry_li.data = sbuf_data_in;
      sbuf_entry_li.mask = sbuf_mask_in;
    end
  end


  // output stage
  //
  logic [dma_data_width_p-1:0] ld_data_way_picked;
  logic [data_width_p-1:0] ld_data_offset_picked;
  logic [data_width_p-1:0] bypass_data_masked;
  logic [data_width_p-1:0] ld_data_masked;

  bsg_mux #(
    .width_p(dma_data_width_p)
    ,.els_p(ways_p)
  ) ld_data_mux (
    .data_i(ld_data_v_r)
    ,.sel_i(tag_hit_way_id)
    ,.data_o(ld_data_way_picked)
  );

  bsg_mux #(
    .width_p(data_width_p)
    ,.els_p(burst_size_in_words_lp)
  ) mux00 (
    .data_i(ld_data_way_picked)
    ,.sel_i(addr_v_r[lg_data_mask_width_lp+:lg_burst_size_in_words_lp])
    ,.data_o(ld_data_offset_picked)
  );

  bsg_mux_segmented #(
    .segments_p(data_mask_width_lp)
    ,.segment_width_p(8)
  ) bypass_mux_segmented (
    .data0_i(ld_data_offset_picked)
    ,.data1_i(bypass_data_lo)
    ,.sel_i(bypass_mask_lo)
    ,.data_o(bypass_data_masked)
  );
  

  assign snoop_or_ld_data = select_snoop_data_r_lo
    ? snoop_word_lo
    : bypass_data_masked;


  logic [data_width_p-1:0] expanded_mask_v;

  bsg_expand_bitmask #(
    .in_width_p(data_mask_width_lp)
    ,.expand_p(8)
  ) mask_v_expand (
    .i(mask_v_r)
    ,.o(expanded_mask_v)
  );

  assign ld_data_masked = snoop_or_ld_data & expanded_mask_v;

  // select double/word/half/byte load data
  //

  for (genvar i = 0; i < data_sel_mux_els_lp; i++) begin: ld_data_sel

    if (i == data_sel_mux_els_lp-1) begin: max_size

      assign ld_data_final_li[i] = snoop_or_ld_data;

    end
    else begin: non_max_size

      logic [(8*(2**i))-1:0] byte_sel;

      bsg_mux #(
        .width_p(8*(2**i))
        ,.els_p(data_width_p/(8*(2**i)))
      ) byte_mux (
        .data_i(snoop_or_ld_data)
        ,.sel_i(addr_v_r[i+:`BSG_MAX(lg_data_mask_width_lp-i,1)])
        ,.data_o(byte_sel)
      );

      assign ld_data_final_li[i] = 
        {{(data_width_p-(8*(2**i))){decode_v_r.sigext_op & byte_sel[(8*(2**i))-1]}}, byte_sel};

    end

  end
  
  bsg_mux #(
    .width_p(data_width_p)
    ,.els_p(data_sel_mux_els_lp)
  ) ld_data_size_mux (
    .data_i(ld_data_final_li)
    ,.sel_i(decode_v_r.data_size_op[0+:lg_data_sel_mux_els_lp])
    ,.data_o(ld_data_final_lo)
  );

  // final output mux
  always_comb begin
    if (retval_op_v) begin
      if (decode_v_r.taglv_op) begin
        data_o = {{(data_width_p-2){1'b0}}, lock_v_r[addr_way_v], valid_v_r[addr_way_v]};
      end
      else if (decode_v_r.tagla_op) begin
        data_o = {tag_v_r[addr_way_v], addr_index_v,
          {(lg_block_size_in_words_lp+lg_data_mask_width_lp){1'b0}}
        };
      end
      else if (decode_v_r.mask_op) begin
        data_o = ld_data_masked;
      end
      else begin
        data_o = ld_data_final_lo;
      end
    end
    else begin
      data_o = '0;
    end 
  end 

  // ctrl logic
  //
  assign v_o = v_v_r & (miss_v
    ? miss_done_lo
    : 1'b1); 

  assign v_we = v_v_r
    ? (v_o & yumi_i)
    : 1'b1;

  // when the store buffer is full, and the TV stage is inserting another entry,
  // load/atomic cannot enter tl stage.
  assign sbuf_hazard = (sbuf_full_lo & (v_o & yumi_i & (decode_v_r.st_op | decode_v_r.atomic_op)))
    & (v_i & (decode.ld_op | decode.atomic_op));

  // during miss, tl pipeline cannot take next instruction when
  // 1) input is tagst
  // 2) miss handler is writing to tag_mem
  // 3) dma engine is writing to data_mem
  // 4) tl_stage is recovering from tag_miss
  // 5) DMA is evicting a block.
  wire tl_ready = (miss_v
    ? (~(decode.tagst_op & v_i) & ~miss_tag_mem_v_lo & ~dma_data_mem_v_lo & ~recover_lo & ~dma_evict_lo)
    : 1'b1) & ~sbuf_hazard;

  assign ready_o = v_tl_r
    ? (v_we & tl_ready)
    : tl_ready;


  // tag_mem
  // values written by tagst command
 
  logic tagst_valid;
  logic tagst_lock;
  logic [tag_width_lp-1:0] tagst_tag;
  logic tagst_write_en;

  assign tagst_valid = cache_pkt.data[data_width_p-1];
  assign tagst_lock = cache_pkt.data[data_width_p-2];
  assign tagst_tag = cache_pkt.data[0+:tag_width_lp];
  assign tagst_write_en = decode.tagst_op & ready_o & v_i;

  logic [ways_p-1:0] addr_way_decode;
  bsg_decode #(
    .num_out_p(ways_p)
  ) addr_way_demux (
    .i(addr_way)
    ,.o(addr_way_decode)
  );

  assign tag_mem_v_li = (decode.tag_read_op & ready_o & v_i)
    | (recover_lo & decode_tl_r.tag_read_op & v_tl_r)
    | miss_tag_mem_v_lo
    | (decode.tagst_op & ready_o & v_i); 
  
  assign tag_mem_w_li = miss_v
    ? miss_tag_mem_w_lo
    : tagst_write_en;

  always_comb begin
    if (miss_v) begin
      tag_mem_addr_li = recover_lo
        ? addr_index_tl
        : (miss_tag_mem_v_lo ? miss_tag_mem_addr_lo : addr_index);
      tag_mem_data_li = miss_tag_mem_data_lo;
      tag_mem_w_mask_li = miss_tag_mem_w_mask_lo;
    end
    else begin
      // for TAGST
      tag_mem_addr_li = addr_index;
      for (integer i = 0; i < ways_p; i++) begin
        tag_mem_data_li[i] = {tagst_valid, tagst_lock, tagst_tag};
        tag_mem_w_mask_li[i] = {tag_info_width_lp{addr_way_decode[i]}};
      end
    end
  end

  // data_mem ctrl logic
  //
  assign data_mem_v_li = ((v_i & ready_o & (decode.ld_op | decode.atomic_op))
    | (v_tl_r & recover_lo & (decode_tl_r.ld_op | decode_tl_r.atomic_op)) 
    | dma_data_mem_v_lo
    | (sbuf_v_lo & sbuf_yumi_li)
  );
  
  assign data_mem_w_li = dma_data_mem_w_lo | (sbuf_v_lo & sbuf_yumi_li);

  assign data_mem_data_li = dma_data_mem_w_lo
    ? dma_data_mem_data_lo
    : sbuf_data_mem_data;

  assign data_mem_addr_li = recover_lo
    ? recover_data_mem_addr
    : (dma_data_mem_v_lo
      ? dma_data_mem_addr_lo
      : (((decode.ld_op | decode.atomic_op) & v_i & ready_o) 
        ? ld_data_mem_addr
        : sbuf_data_mem_addr));

  assign data_mem_w_mask_li = dma_data_mem_w_lo
    ? dma_data_mem_w_mask_lo
    : sbuf_data_mem_w_mask;


  // stat_mem ctrl logic
  // TAGST clears the stat_info as it exits tv stage.
  // If it's load or store, and there is a hit, it updates the dirty bits and LRU.
  // If there is a miss, stat_mem may be modified by the miss handler.

  logic [ways_p-2:0] plru_decode_data_lo;
  logic [ways_p-2:0] plru_decode_mask_lo;
  
  bsg_lru_pseudo_tree_decode #(
    .ways_p(ways_p)
  ) plru_decode (
    .way_id_i(tag_hit_way_id)
    ,.data_o(plru_decode_data_lo)
    ,.mask_o(plru_decode_mask_lo)
  );

  always_comb begin
    if (miss_v) begin
      stat_mem_v_li = miss_stat_mem_v_lo;
      stat_mem_w_li = miss_stat_mem_w_lo;
      stat_mem_addr_li = miss_stat_mem_addr_lo; // essentially same as addr_index_v
      stat_mem_data_li = miss_stat_mem_data_lo;
      stat_mem_w_mask_li = miss_stat_mem_w_mask_lo;
    end
    else begin
      stat_mem_v_li = ((decode_v_r.st_op | decode_v_r.ld_op | decode_v_r.tagst_op | decode_v_r.atomic_op) & v_o & yumi_i);
      stat_mem_w_li = ((decode_v_r.st_op | decode_v_r.ld_op | decode_v_r.tagst_op | decode_v_r.atomic_op) & v_o & yumi_i);
      stat_mem_addr_li = addr_index_v;

      if (decode_v_r.tagst_op) begin
        // for TAGST
        stat_mem_data_li.dirty = {ways_p{1'b0}};
        stat_mem_data_li.lru_bits = {(ways_p-1){1'b0}};
        stat_mem_w_mask_li.dirty = {ways_p{1'b1}};
        stat_mem_w_mask_li.lru_bits = {(ways_p-1){1'b1}};
      end
      else begin
        // for LD, ST
        stat_mem_data_li.dirty = {ways_p{decode_v_r.st_op | decode_v_r.atomic_op}};
        stat_mem_data_li.lru_bits = plru_decode_data_lo;
        stat_mem_w_mask_li.dirty = {ways_p{decode_v_r.st_op | decode_v_r.atomic_op}} & tag_hit_v;
        stat_mem_w_mask_li.lru_bits = plru_decode_mask_lo;
      end
    end
  end


  // store buffer
  //
  assign sbuf_v_li = (decode_v_r.st_op | decode_v_r.atomic_op) & v_o & yumi_i;
  assign sbuf_entry_li.way_id = miss_v ? chosen_way_lo : tag_hit_way_id;
  assign sbuf_entry_li.addr = addr_v_r;
  // store buffer can write to dmem when
  // 1) there is valid entry in store buffer.
  // 2) incoming request does not read DMEM.
  // 3) DMA engine is not accessing DMEM.
  // 4) TL read DMEM (and bypass from sbuf), and TV is not stalled (v_we).
  //    During miss, the store buffer can be drained.
  assign sbuf_yumi_li = sbuf_v_lo
    & ~((decode.ld_op | decode.atomic_op) & v_i & ready_o)
    & (~dma_data_mem_v_lo)
    & ~(v_tl_r & (decode_tl_r.ld_op | decode_tl_r.atomic_op) & (~v_we) & (~miss_v)); 

  assign bypass_addr_li = addr_tl_r;
  assign bypass_v_li = (decode_tl_r.ld_op | decode_tl_r.atomic_op) & v_tl_r & v_we;


  // synopsys translate_off

  always_ff @ (negedge clk_i) begin
    if (~reset_i) begin
      if (v_v_r) begin
        // check that there is no multiple hit.
        assert($countones(tag_hit_v) <= 1)
          else $error("[BSG_ERROR][BSG_CACHE] Multiple cache hit detected. %m, T=%t", $time);

        // check that there is at least one unlocked way in a set.
        assert($countones(lock_v_r) < ways_p)
          else $error("[BSG_ERROR][BSG_CACHE] There should be at least one unlocked way in a set. %m, T=%t", $time);

        // Check that client hasn't required unsupported AMO
        assert(~decode_v_r.atomic_op | amo_support_p[decode_v_r.amo_subop])
          else $error("[BSG_ERROR][BSG_CACHE] Unsupported AMO OP %d received. %m, T=%t", decode.amo_subop, $time);

        assert(~decode_v_r.atomic_op || (data_width_p >= 64) || ~decode_v_r.data_size_op[0])
          else $error("[BSG_ERROR][BSG_CACHE] AMO_D performed on data_width < 64. %m T=%t", $time);
        assert(~decode_v_r.atomic_op || (data_width_p >= 32))
          else $error("[BSG_ERROR][BSG_CACHE] AMO performed on data_width < 32. %m T=%t", $time);
      end
    end
  end


  if (debug_p) begin
    always_ff @ (posedge clk_i) begin
      if (v_o & yumi_i) begin
        if (decode_v_r.ld_op) begin
          $display("<VCACHE> M[%4h] == %8h // %8t", addr_v_r, data_o, $time);
        end
        
        if (decode_v_r.st_op) begin
          $display("<VCACHE> M[%4h] := %8h // %8t", addr_v_r, sbuf_entry_li.data, $time);
        end

      end
      if (tag_mem_v_li & tag_mem_w_li) begin
        $display("<VCACHE> tag_mem_write. addr=%8h data_1=%8h data_0=%8h mask_1=%8h mask_0=%8h // %8t",
          tag_mem_addr_li,
          tag_mem_data_li[1+tag_width_lp+:1+tag_width_lp],
          tag_mem_data_li[0+:1+tag_width_lp],
          tag_mem_w_mask_li[1+tag_width_lp+:1+tag_width_lp],
          tag_mem_w_mask_li[0+:1+tag_width_lp],
          $time
        );
      end
    end
  end

  // synopsys translate_on


endmodule
