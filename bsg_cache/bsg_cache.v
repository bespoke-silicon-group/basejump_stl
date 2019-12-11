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

module bsg_cache
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="inv"
    ,parameter ways_p="inv"

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

    ,input [data_width_p-1:0] dma_data_i
    ,input dma_data_v_i
    ,output logic dma_data_ready_o

    ,output logic [data_width_p-1:0] dma_data_o
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


  // instruction decoding
  //
  logic [lg_ways_lp-1:0] addr_way;
  logic [lg_sets_lp-1:0] addr_index;
  logic [lg_block_size_in_words_lp-1:0] addr_block_offset;

  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);
  bsg_cache_pkt_s cache_pkt;

  assign cache_pkt = cache_pkt_i;

  bsg_cache_pkt_decode_s decode;

  bsg_cache_pkt_decode #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
  ) cache_pkt_decoder (
    .cache_pkt_i(cache_pkt)
    ,.decode_o(decode)
  );

  assign addr_way
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp+:lg_ways_lp];
  assign addr_index
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  assign addr_block_offset
    = cache_pkt.addr[lg_data_mask_width_lp+:lg_block_size_in_words_lp];

  // tl_stage
  //
  logic v_tl_r;
  bsg_cache_pkt_decode_s decode_tl_r;
  logic [data_mask_width_lp-1:0] mask_tl_r;
  logic [addr_width_p-1:0] addr_tl_r;
  logic [data_width_p-1:0] data_tl_r;

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
    end
  end

  logic [lg_sets_lp-1:0] addr_index_tl;
  logic [lg_block_size_in_words_lp-1:0] addr_block_offset_tl;

  assign addr_index_tl =
    addr_tl_r[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];

  assign addr_block_offset_tl =
    addr_tl_r[lg_data_mask_width_lp+:lg_block_size_in_words_lp];

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
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_mem_addr_li;
  logic [ways_p-1:0][data_width_p-1:0] data_mem_data_li;
  logic [ways_p-1:0][data_mask_width_lp-1:0] data_mem_w_mask_li;
  logic [ways_p-1:0][data_width_p-1:0] data_mem_data_lo;

  bsg_mem_1rw_sync_mask_write_byte #(
    .data_width_p(data_width_p*ways_p)
    ,.els_p(block_size_in_words_p*sets_p)
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
  bsg_cache_pkt_decode_s decode_v_r;
  logic [data_mask_width_lp-1:0] mask_v_r;
  logic [addr_width_p-1:0] addr_v_r;
  logic [data_width_p-1:0] data_v_r;
  logic [ways_p-1:0] valid_v_r;
  logic [ways_p-1:0] lock_v_r;
  logic [ways_p-1:0][tag_width_lp-1:0] tag_v_r;
  logic [ways_p-1:0][data_width_p-1:0] ld_data_v_r;
  logic retval_op_v;
  logic block_ld_busy;
  logic [lg_block_size_in_words_lp-1:0] block_ld_counter_r;
  logic counter_clear;
  logic counter_en;
  logic v_we_r;
  logic v_we_posedge;
  logic block_ld_busy_r;
  logic ld_under_block_ld_en;
  logic ld_under_block_ld_pending;
  logic ld_under_block_ld_done;
  logic [addr_width_p-1:0] ld_under_block_ld_addr_r;
  logic [ways_p-1:0][data_width_p-1:0] ld_under_block_ld_data_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_v_r <= 1'b0;
      {mask_v_r
      ,decode_v_r
      ,addr_v_r
      ,data_v_r
      ,valid_v_r
      ,lock_v_r
      ,tag_v_r
      ,ld_under_block_ld_pending} <= '0;
    end
    else begin
      v_we_r <= v_we;
      block_ld_busy_r <= block_ld_busy;
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
      if(ld_under_block_ld_en) begin 
        ld_under_block_ld_data_r <= data_mem_data_lo;
        ld_under_block_ld_pending <= 1'b1;
        ld_under_block_ld_addr_r <= addr_tl_r;
      end
      else if (ld_under_block_ld_done)
        ld_under_block_ld_pending <= 1'b0;
    end
  end

  assign v_we_o = v_we;
  assign v_we_posedge = v_we & ~v_we_r;
  
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

  logic ld_st_miss;
  logic tagfl_hit;
  logic aflinv_hit;
  logic alock_miss;  // either the line is miss, or the line is unlocked.
  logic aunlock_hit; // the line is hit and locked.
  logic block_ld_miss;
  logic block_ld;
  logic ld_bypass;

  assign block_ld = decode_v_r.block_ld_op;            //decode_v_r.ld_op & decode_v_r.mask_op;
  assign block_ld_miss  = ~tag_hit_found & block_ld;
  assign ld_st_miss = ~tag_hit_found & (decode_v_r.ld_op | decode_v_r.st_op);
  assign tagfl_hit = decode_v_r.tagfl_op& valid_v_r[addr_way_v];
  assign aflinv_hit = (decode_v_r.afl_op| decode_v_r.aflinv_op| decode_v_r.ainv_op) & tag_hit_found;
  assign alock_miss = decode_v_r.alock_op& (tag_hit_found ? ~lock_v_r[tag_hit_way_id] : 1'b1);
  assign aunlock_hit = decode_v_r.aunlock_op& (tag_hit_found ? lock_v_r[tag_hit_way_id] : 1'b0);
  assign ld_bypass = block_ld_miss & decode_v_r.ld_bypass_op; // l2_bypass_op is passed via cache_pkt to bypass insertion into data_mem in case of a miss

  // miss_v signal activates the miss handling unit.
  // MBT: the ~decode_v_r.tagst_op is necessary at the top of this expression
  //      to avoid X-pessimism post synthesis due to X's coming out of the tags
  logic miss_v;
  assign miss_v = (~decode_v_r.tagst_op) & v_v_r
    & (ld_st_miss | tagfl_hit | aflinv_hit | alock_miss | aunlock_hit | block_ld_miss);
  
  // ops that return some value other than '0.
  assign retval_op_v = decode_v_r.ld_op | decode_v_r.taglv_op | decode_v_r.tagla_op | decode_v_r.block_ld_op; 

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
  logic miss_ack;

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
    
    ,.ack_i(miss_ack)                       // Since dma data is forwarded while miss is handled, (v_o & yumi_i) is low by the time  miss handler fsm checks ack_i
  );

  // dma
  // 
  logic [data_width_p-1:0] snoop_word_lo;
  logic dma_data_mem_v_lo;
  logic dma_data_mem_w_lo;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] dma_data_mem_addr_lo;
  logic [ways_p-1:0][data_mask_width_lp-1:0] dma_data_mem_w_mask_lo;
  logic [ways_p-1:0][data_width_p-1:0] dma_data_mem_data_lo;
  logic dma_evict_lo;

  bsg_cache_dma #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
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

  // Block Load Counter
  //
  always_ff @ (posedge clk_i)begin
  if(v_we_posedge)                                   // Latching Counter Enable
    counter_en = 1'b1;
  if(counter_clear)
    counter_en = 1'b0;
  end

  assign counter_clear = (block_ld_counter_r == (block_size_in_words_p-1));
  assign block_ld_busy = block_ld & tag_hit_found & counter_en & v_v_r;

  assign ld_under_block_ld_en = decode_tl_r.ld_op & block_ld_busy & (block_ld_counter_r == '0); // latch_en to latch the data read by ld_op during input stage while block ld is in tv stage
  assign ld_under_block_ld_done = decode_v_r.ld_op & ld_under_block_ld_pending & (addr_v_r == ld_under_block_ld_addr_r);

  bsg_counter_clear_up #(                  // Counter to go through different word offsets in a block
    .max_val_p(block_size_in_words_p-1)
    ,.init_val_p(0)
  ) block_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i|counter_clear)
    ,.clear_i(0)
    ,.up_i(block_ld_busy)
    ,.count_o(block_ld_counter_r)
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

  logic [ways_p-1:0][data_mask_width_lp-1:0] sbuf_data_mem_w_mask;
  logic [ways_p-1:0][data_width_p-1:0] sbuf_data_mem_data;


  for (genvar i = 0 ; i < ways_p; i++) begin
    assign sbuf_data_mem_data[i] = sbuf_entry_lo.data;
    assign sbuf_data_mem_w_mask[i] = {data_mask_width_lp{sbuf_way_decode[i]}} & sbuf_entry_lo.mask;
  end


  // store buffer data/mask input
  //
  logic [data_sel_mux_els_lp-1:0][data_width_p-1:0] sbuf_data_in_mux_li;
  logic [data_sel_mux_els_lp-1:0][data_mask_width_lp-1:0] sbuf_mask_in_mux_li;
  logic [data_width_p-1:0] sbuf_data_in;
  logic [data_mask_width_lp-1:0] sbuf_mask_in;

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

  for (genvar i = 0; i < data_sel_mux_els_lp; i++) begin: sbuf_in_sel

    assign sbuf_data_in_mux_li[i] = {(data_width_p/(8*(2**i))){data_v_r[0+:(8*(2**i))]}};


    if (i == data_sel_mux_els_lp-1) begin: max_size

      assign sbuf_mask_in_mux_li[i] = {data_mask_width_lp{1'b1}};    

    end 
    else begin: non_max_size

      logic [data_width_p/(8*(2**i))-1:0] decode_lo;

      bsg_decode #(
        .num_out_p(data_width_p/(8*(2**i)))
      ) dec (
        .i(addr_v_r[i+:`BSG_MAX(lg_data_mask_width_lp-i,1)])
        ,.o(decode_lo)
      );

      bsg_expand_bitmask #(
        .in_width_p(data_width_p/(8*(2**i)))
        ,.expand_p(2**i)
      ) exp (
        .i(decode_lo)
        ,.o(sbuf_mask_in_mux_li[i])
      );

    end
  end

  assign sbuf_entry_li.data = decode_v_r.mask_op
    ? data_v_r
    : sbuf_data_in;

  assign sbuf_entry_li.mask = decode_v_r.mask_op
    ? mask_v_r
    : sbuf_mask_in;


  // output stage
  //
  logic [data_width_p-1:0] ld_data_way_picked;
  logic [data_width_p-1:0] bypass_data_masked;
  logic [data_width_p-1:0] snoop_or_ld_data;
  logic [data_width_p-1:0] ld_data_masked;
  logic [data_width_p-1:0] block_ld_data;
  logic [data_width_p-1:0] ld_or_bl_ld_data;
  logic [ways_p-1:0][data_width_p-1:0] ld_under_ld_data_picked;

  bsg_mux #(                  
    .width_p(data_width_p)
    ,.els_p(ways_p)
  ) bl_ld_data_mux (
    .data_i(data_mem_data_lo)
    ,.sel_i(tag_hit_way_id)
    ,.data_o(block_ld_data)
  );

  bsg_mux #(
    .width_p(ways_p*data_width_p)
    ,.els_p(ways_p)
  ) ld_under_block_ld_data_mux (
    .data_i({ld_under_block_ld_data_r, ld_data_v_r})
    ,.sel_i(ld_under_block_ld_pending)
    ,.data_o(ld_under_ld_data_picked)
  );

  bsg_mux #(
    .width_p(data_width_p)
    ,.els_p(ways_p)
  ) ld_data_mux (
    .data_i(ld_under_ld_data_picked)
    ,.sel_i(tag_hit_way_id)
    ,.data_o(ld_data_way_picked)
  );

  bsg_mux #(
    .width_p(data_width_p)
    ,.els_p(2)
  ) ld_or_bl_ld_data_mux (
    .data_i({block_ld_data, ld_data_way_picked})
    ,.sel_i(block_ld)
    ,.data_o(ld_or_bl_ld_data)
  );

  bsg_mux_segmented #(
    .segments_p(data_mask_width_lp)
    ,.segment_width_p(8)
  ) bypass_mux_segmented (
    .data0_i(ld_or_bl_ld_data)
    ,.data1_i(bypass_data_lo)
    ,.sel_i(bypass_mask_lo)
    ,.data_o(bypass_data_masked)
  );
  

  assign snoop_or_ld_data = miss_v
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
  logic [data_sel_mux_els_lp-1:0][data_width_p-1:0] ld_data_final_li;
  logic [data_width_p-1:0] ld_data_final_lo;
  

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
      else if (block_ld) begin
        data_o = (block_ld_miss & dma_data_mem_w_lo) ? dma_data_mem_data_lo[0] : snoop_or_ld_data; // On a block ld miss, dma_data is directly forwarded to output
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
    ? (block_ld_miss               // On a block ld miss, data is forwarded to the CCE simultaneously as it's written into data_mem
    ? dma_data_mem_w_lo
    : miss_done_lo)
    : (block_ld 
    ? block_ld_busy_r
    : 1'b1));

  assign v_we = v_v_r
    ? (miss_v ? miss_done_lo : ~block_ld_busy)
    : 1'b1;

  assign miss_ack = block_ld_miss ? miss_done_lo : (v_o & yumi_i);
  // during miss, tl pipeline cannot take next instruction when
  // 1) input is tagst
  // 2) miss handler is writing to tag_mem
  // 3) dma engine is writing to data_mem
  // 4) tl_stage is recovering from tag_miss
  logic tl_ready;
  assign tl_ready = miss_v
    ? (~(decode.tagst_op & v_i) & ~miss_tag_mem_v_lo & ~dma_data_mem_v_lo & ~recover_lo & ~dma_evict_lo)
    : ~(block_ld_busy); // Block_ld_busy is high only for block ld hits, thus tl_ready lowered to prevent successive requests
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
    ? (miss_tag_mem_w_lo & ~ld_bypass)
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
  assign data_mem_v_li = ((v_i & decode.ld_op & ready_o)
    | (v_tl_r & recover_lo & decode_tl_r.ld_op)
    | block_ld_busy
    | dma_data_mem_v_lo
    | (sbuf_v_lo & sbuf_yumi_li)
  );
  
  assign data_mem_w_li = (dma_data_mem_w_lo & ~ld_bypass) | (sbuf_v_lo & sbuf_yumi_li);

  assign data_mem_data_li = dma_data_mem_w_lo
    ? dma_data_mem_data_lo
    : sbuf_data_mem_data;

  assign data_mem_addr_li = recover_lo
    ? {addr_index_tl, addr_block_offset_tl}
    : (dma_data_mem_v_lo
      ? dma_data_mem_addr_lo
      : ((block_ld_busy & v_v_r)
        ? {addr_index_v, block_ld_counter_r}
        : ((decode.ld_op & v_i & ready_o)
          ? {addr_index, addr_block_offset}
          : sbuf_entry_lo.addr[lg_data_mask_width_lp+:lg_block_size_in_words_lp+lg_sets_lp])));

  assign data_mem_w_mask_li = dma_data_mem_w_lo
    ? dma_data_mem_w_mask_lo
    : sbuf_data_mem_w_mask;

//{lg_block_size_in_words_lp{1'b0}} 
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
      stat_mem_w_li = ~ld_bypass & miss_stat_mem_w_lo;
      stat_mem_addr_li = miss_stat_mem_addr_lo; // essentially same as addr_index_v
      stat_mem_data_li = miss_stat_mem_data_lo;
      stat_mem_w_mask_li = miss_stat_mem_w_mask_lo;
    end
    else begin
      stat_mem_v_li = ((decode_v_r.st_op| decode_v_r.ld_op| decode_v_r.block_ld_op| decode_v_r.tagst_op) & v_o & yumi_i);
      stat_mem_w_li = ((decode_v_r.st_op| decode_v_r.ld_op| decode_v_r.block_ld_op| decode_v_r.tagst_op) & v_o & yumi_i);
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
        stat_mem_data_li.dirty = {ways_p{decode_v_r.st_op}};
        stat_mem_data_li.lru_bits = plru_decode_data_lo;
        stat_mem_w_mask_li.dirty = {ways_p{decode_v_r.st_op}} & tag_hit_v;
        stat_mem_w_mask_li.lru_bits = plru_decode_mask_lo;
      end
    end
  end


  // store buffer
  //
  assign sbuf_v_li = decode_v_r.st_op & v_o & yumi_i;
  assign sbuf_entry_li.way_id = miss_v ? chosen_way_lo : tag_hit_way_id;
  assign sbuf_entry_li.addr = addr_v_r;
  assign sbuf_yumi_li = sbuf_v_lo & ~(decode.ld_op & v_i & ready_o) & (~dma_data_mem_v_lo) & (~block_ld_busy); 

  assign bypass_addr_li = block_ld_busy ? {addr_tag_v, addr_index_v, block_ld_counter_r, {lg_data_mask_width_lp{1'b0}}}: addr_tl_r;
  assign bypass_v_li = ((decode_tl_r.ld_op | decode_tl_r.block_ld_op) & v_tl_r & v_we) | block_ld;


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
