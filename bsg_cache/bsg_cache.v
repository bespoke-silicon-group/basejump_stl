/**
 *  bsg_cache.v
 *
 *  @param addr_width_p
 *  @param data_width_p
 *  @param block_size_in_words_p
 *  @param sets_p
 *
 *  @author tommy
 */

`include "bsg_cache_pkt.vh"
`include "bsg_cache_dma_pkt.vh"

module bsg_cache
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="inv"

    ,localparam lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,localparam data_mask_width_lp=(data_width_p>>3)
    ,localparam lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_mask_width_lp)
    ,localparam lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,localparam tag_width_lp=(addr_width_p-lg_data_mask_width_lp-lg_sets_lp-lg_block_size_in_words_lp)
    ,localparam bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(addr_width_p,data_width_p)
    ,localparam bsg_cache_dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)

    ,parameter debug_p=0
    ,parameter axe_trace_p=0
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

    ,output logic v_we_o
  );

  // instruction decoding
  //
  logic word_op;
  logic half_op;
  logic byte_op;
  logic mask_op;
  logic ld_op;
  logic st_op;
  logic tagst_op;
  logic tagfl_op;
  logic taglv_op;
  logic tagla_op;
  logic afl_op;
  logic aflinv_op;
  logic ainv_op;
  logic tag_read_op;
  logic addr_set;
  logic [lg_sets_lp-1:0] addr_index;
  logic [lg_block_size_in_words_lp-1:0] addr_block_offset;

  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);
  bsg_cache_pkt_s cache_pkt;

  assign cache_pkt = cache_pkt_i;
  bsg_cache_pkt_decode #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
  ) cache_pkt_decoder (
    .cache_pkt_i(cache_pkt)
    ,.word_op_o(word_op)
    ,.half_op_o(half_op)
    ,.byte_op_o(byte_op)
    ,.mask_op_o(mask_op)
    ,.ld_op_o(ld_op)
    ,.st_op_o(st_op)
    ,.tagst_op_o(tagst_op)
    ,.tagfl_op_o(tagfl_op)
    ,.taglv_op_o(taglv_op)
    ,.tagla_op_o(tagla_op)
    ,.afl_op_o(afl_op)
    ,.aflinv_op_o(aflinv_op)
    ,.ainv_op_o(ainv_op)
    ,.tag_read_op_o(tag_read_op)
  );

  assign addr_set
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp];
  assign addr_index
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  assign addr_block_offset
    = cache_pkt.addr[lg_data_mask_width_lp+:lg_block_size_in_words_lp];

  // tl_stage
  //
  logic v_tl_r;
  logic sigext_op_tl_r;
  logic word_op_tl_r;
  logic half_op_tl_r;
  logic byte_op_tl_r;
  logic mask_op_tl_r;
  logic [data_mask_width_lp-1:0] mask_tl_r;
  logic ld_op_tl_r;
  logic st_op_tl_r;
  logic tagst_op_tl_r;
  logic tagfl_op_tl_r;
  logic taglv_op_tl_r;
  logic tagla_op_tl_r;
  logic afl_op_tl_r;
  logic aflinv_op_tl_r;
  logic ainv_op_tl_r;
  logic tag_read_op_tl_r;
  logic [addr_width_p-1:0] addr_tl_r;
  logic [data_width_p-1:0] data_tl_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_tl_r <= 1'b0;
      {sigext_op_tl_r
      ,word_op_tl_r
      ,half_op_tl_r
      ,byte_op_tl_r
      ,mask_op_tl_r
      ,mask_tl_r
      ,ld_op_tl_r
      ,st_op_tl_r
      ,tagst_op_tl_r
      ,taglv_op_tl_r
      ,tagla_op_tl_r
      ,afl_op_tl_r
      ,aflinv_op_tl_r
      ,ainv_op_tl_r
      ,tag_read_op_tl_r
      ,addr_tl_r
      ,data_tl_r} <= '0;
    end
    else begin
      if (ready_o) begin
        v_tl_r <= v_i;
        if (v_i) begin
          sigext_op_tl_r <= cache_pkt.sigext;
          word_op_tl_r <= word_op;
          half_op_tl_r <= half_op;
          byte_op_tl_r <= byte_op;
          mask_op_tl_r <= mask_op;
          mask_tl_r <= cache_pkt.mask;
          ld_op_tl_r <= ld_op;
          st_op_tl_r <= st_op;
          tagst_op_tl_r <= tagst_op;
          taglv_op_tl_r <= taglv_op;
          tagla_op_tl_r <= tagla_op;
          afl_op_tl_r <= afl_op;
          aflinv_op_tl_r <= aflinv_op;
          ainv_op_tl_r <= ainv_op;
          tag_read_op_tl_r <= tag_read_op;
          addr_tl_r <= cache_pkt.addr;
          data_tl_r <= cache_pkt.data;
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
  logic [(tag_width_lp+1)*2-1:0] tag_mem_data_li;
  logic [lg_sets_lp-1:0] tag_mem_addr_li;
  logic tag_mem_v_li;
  logic [(tag_width_lp+1)*2-1:0] tag_mem_w_mask_li;
  logic tag_mem_w_li;
  logic [(tag_width_lp+1)*2-1:0] tag_mem_data_lo;
  
  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p((tag_width_lp+1)*2)
    ,.els_p(sets_p)
  ) tag_mem (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(tag_mem_data_li)
    ,.addr_i(tag_mem_addr_li)
    ,.v_i(tag_mem_v_li)
    ,.w_mask_i(tag_mem_w_mask_li)
    ,.w_i(tag_mem_w_li)
    ,.data_o(tag_mem_data_lo)
  );

  logic [1:0] valid_tl;
  logic [1:0][tag_width_lp-1:0] tag_tl;
  assign valid_tl = {
    tag_mem_data_lo[tag_width_lp*2+1],
    tag_mem_data_lo[tag_width_lp]
  };
  assign tag_tl = {
    tag_mem_data_lo[tag_width_lp+1+:tag_width_lp],
    tag_mem_data_lo[0+:tag_width_lp]
  };
 

  // data_mem
  //
  logic [(data_width_p*2)-1:0] data_mem_data_li;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_mem_addr_li;
  logic data_mem_v_li;
  logic [(data_mask_width_lp*2)-1:0] data_mem_w_mask_li;
  logic data_mem_w_li;
  logic [data_width_p*2-1:0] data_mem_data_lo;

  bsg_mem_1rw_sync_mask_write_byte #(
    .data_width_p(data_width_p*2)
    ,.els_p(block_size_in_words_p*sets_p)
  ) data_mem (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(data_mem_data_li)
    ,.addr_i(data_mem_addr_li)
    ,.v_i(data_mem_v_li)
    ,.write_mask_i(data_mem_w_mask_li)
    ,.w_i(data_mem_w_li)
    ,.data_o(data_mem_data_lo)
  );

  // v stage
  //
  logic v_we;
  logic v_v_r;
  logic sigext_op_v_r;
  logic word_op_v_r;
  logic half_op_v_r;
  logic byte_op_v_r;
  logic mask_op_v_r;
  logic [data_mask_width_lp-1:0] mask_v_r;
  logic ld_op_v_r;
  logic st_op_v_r;
  logic tagst_op_v_r;
  logic tagfl_op_v_r;
  logic taglv_op_v_r;
  logic tagla_op_v_r;
  logic afl_op_v_r;
  logic aflinv_op_v_r;
  logic ainv_op_v_r;
  logic [addr_width_p-1:0] addr_v_r;
  logic [data_width_p-1:0] data_v_r;
  logic [1:0] valid_v_r;
  logic [1:0][tag_width_lp-1:0] tag_v_r;
  logic [2*data_width_p-1:0] ld_data_v_r;
  logic retval_op_v;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_v_r <= 1'b0;
      {sigext_op_v_r
      ,word_op_v_r
      ,half_op_v_r
      ,byte_op_v_r
      ,mask_op_v_r
      ,mask_v_r
      ,ld_op_v_r
      ,st_op_v_r
      ,tagst_op_v_r
      ,tagfl_op_v_r
      ,taglv_op_v_r
      ,tagla_op_v_r
      ,afl_op_v_r
      ,aflinv_op_v_r
      ,ainv_op_v_r
      ,addr_v_r
      ,data_v_r
      ,valid_v_r
      ,tag_v_r} <= '0;
    end
    else begin
      if (v_we) begin
        v_v_r <= v_tl_r;
        if (v_tl_r) begin
          sigext_op_v_r <= sigext_op_tl_r;
          word_op_v_r <= word_op_tl_r;
          half_op_v_r <= half_op_tl_r;
          byte_op_v_r <= byte_op_tl_r;
          mask_op_v_r <= mask_op_tl_r;
          mask_v_r <= mask_tl_r;
          ld_op_v_r <= ld_op_tl_r;
          st_op_v_r <= st_op_tl_r;
          tagst_op_v_r <= tagst_op_tl_r;
          tagfl_op_v_r <= tagfl_op_v_r;
          taglv_op_v_r <= taglv_op_tl_r;
          tagla_op_v_r <= tagla_op_tl_r;
          afl_op_v_r <= afl_op_tl_r;
          aflinv_op_v_r <= aflinv_op_tl_r;
          ainv_op_v_r <= ainv_op_tl_r;
          addr_v_r <= addr_tl_r;
          data_v_r <= data_tl_r;
          valid_v_r <= valid_tl;
          tag_v_r <= tag_tl;
          ld_data_v_r <= data_mem_data_lo;
        end
      end
    end
  end

  assign v_we_o = v_we;
  
  logic [tag_width_lp-1:0] addr_tag_v;
  logic [lg_sets_lp-1:0] addr_index_v;
  logic addr_set_v; 
  logic [1:0] tag_hit_v;
  logic miss_v;

  assign addr_tag_v =
    addr_v_r[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp+:tag_width_lp];
  assign addr_index_v =
    addr_v_r[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  assign addr_set_v =
    addr_v_r[lg_sets_lp+lg_block_size_in_words_lp+lg_data_mask_width_lp];

  assign tag_hit_v[1] = (addr_tag_v == tag_v_r[1]) & valid_v_r[1];
  assign tag_hit_v[0] = (addr_tag_v == tag_v_r[0]) & valid_v_r[0];
  assign miss_v = v_v_r & (((ld_op_v_r | st_op_v_r) & ~(tag_hit_v[1] | tag_hit_v[0]))
    | (tagfl_op_v_r & valid_v_r[addr_set_v])
    | ((afl_op_v_r | aflinv_op_v_r | ainv_op_v_r) & (tag_hit_v[1] | tag_hit_v[0])));

  assign retval_op_v = ld_op_v_r | taglv_op_v_r | tagla_op_v_r;

  // stat_mem
  //
  logic [3:0] stat_mem_data_li;
  logic [lg_sets_lp-1:0] stat_mem_addr_li;
  logic stat_mem_v_li;
  logic [3:0] stat_mem_w_mask_li;
  logic stat_mem_w_li;
  logic [3:0] stat_mem_data_lo;

  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p(4)
    ,.els_p(sets_p)
  ) stat_mem (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(stat_mem_data_li)
    ,.addr_i(stat_mem_addr_li)
    ,.v_i(stat_mem_v_li)
    ,.w_mask_i(stat_mem_w_mask_li)
    ,.w_i(stat_mem_w_li)
    ,.data_o(stat_mem_data_lo)
  );
 
  // miss handler
  //
  logic dma_send_fill_addr_lo;
  logic dma_send_evict_addr_lo;
  logic dma_get_fill_data_lo;
  logic dma_send_evict_data_lo;
  logic dma_set_lo;
  logic [addr_width_p-1:0] dma_addr_lo;
  logic dma_done_li;

  logic recover_lo;
  logic miss_done_lo;

  logic miss_stat_mem_v_lo;
  logic miss_stat_mem_w_lo;
  logic [lg_sets_lp-1:0] miss_stat_mem_addr_lo;
  logic [2:0] miss_stat_mem_data_lo;
  logic [2:0] miss_stat_mem_w_mask_lo;

  logic miss_tag_mem_v_lo;
  logic miss_tag_mem_w_lo;
  logic [lg_sets_lp-1:0] miss_tag_mem_addr_lo;
  logic [2*(tag_width_lp+1)-1:0] miss_tag_mem_data_lo;
  logic [2*(tag_width_lp+1)-1:0] miss_tag_mem_w_mask_lo;

  logic sbuf_empty_li;
  logic chosen_set_lo;

  bsg_cache_miss #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.sets_p(sets_p)
    ,.block_size_in_words_p(block_size_in_words_p)
  ) miss (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.miss_v_i(miss_v)
    ,.st_op_v_i(st_op_v_r)
    ,.tagfl_op_v_i(tagfl_op_v_r)
    ,.afl_op_v_i(afl_op_v_r)
    ,.aflinv_op_v_i(aflinv_op_v_r)
    ,.ainv_op_v_i(ainv_op_v_r)
    ,.addr_v_i(addr_v_r)

    ,.tag_v_i(tag_v_r)
    ,.valid_v_i(valid_v_r)
    ,.tag_hit_v_i(tag_hit_v)

    ,.sbuf_empty_i(sbuf_empty_li)
  
    ,.dma_send_fill_addr_o(dma_send_fill_addr_lo)
    ,.dma_send_evict_addr_o(dma_send_evict_addr_lo)
    ,.dma_get_fill_data_o(dma_get_fill_data_lo)
    ,.dma_send_evict_data_o(dma_send_evict_data_lo)
    ,.dma_set_o(dma_set_lo)
    ,.dma_addr_o(dma_addr_lo)
    ,.dma_done_i(dma_done_li)

    ,.dirty_i(stat_mem_data_lo[2:1])
    ,.mru_i(stat_mem_data_lo[0])

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

    ,.chosen_set_o(chosen_set_lo)
    
    ,.ack_i(v_o & yumi_i) 
  );

  // dma
  // 
  logic [data_width_p-1:0] snoop_word_lo;
  logic dma_data_mem_v_lo;
  logic dma_data_mem_w_lo;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] dma_data_mem_addr_lo;
  logic [2*(data_mask_width_lp)-1:0] dma_data_mem_w_mask_lo;
  logic [2*data_width_p-1:0] dma_data_mem_data_lo;

  bsg_cache_dma #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.debug_p(debug_p)
  ) dma (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
   
    ,.dma_send_fill_addr_i(dma_send_fill_addr_lo)
    ,.dma_send_evict_addr_i(dma_send_evict_addr_lo)
    ,.dma_get_fill_data_i(dma_get_fill_data_lo)
    ,.dma_send_evict_data_i(dma_send_evict_data_lo)
    ,.dma_set_i(dma_set_lo)
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
  ); 

  // store buffer
  //
  logic [data_width_p-1:0] sbuf_data_li;
  logic [data_mask_width_lp-1:0] sbuf_mask_li;
  logic sbuf_set_li;
  logic sbuf_v_li;

  logic [data_width_p-1:0] sbuf_data_lo;
  logic [addr_width_p-1:0] sbuf_addr_lo;
  logic sbuf_set_lo;
  logic [data_mask_width_lp-1:0] sbuf_mask_lo;
  logic sbuf_v_lo;
  logic sbuf_yumi_li;

  logic [addr_width_p-1:0] bypass_addr_li;
  logic bypass_v_li;
  logic [data_width_p-1:0] bypass_data_lo;
  logic [data_mask_width_lp-1:0] bypass_mask_lo;


  bsg_cache_sbuf #(
    .data_width_p(data_width_p)
    ,.addr_width_p(addr_width_p)
  ) sbuf (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.addr_i(addr_v_r)
    ,.data_i(sbuf_data_li)
    ,.mask_i(sbuf_mask_li)
    ,.set_i(sbuf_set_li)
    ,.v_i(sbuf_v_li)

    ,.data_o(sbuf_data_lo)
    ,.addr_o(sbuf_addr_lo)
    ,.set_o(sbuf_set_lo)
    ,.mask_o(sbuf_mask_lo)
    ,.v_o(sbuf_v_lo)
    ,.yumi_i(sbuf_yumi_li)

    ,.empty_o(sbuf_empty_li)

    ,.bypass_addr_i(bypass_addr_li)
    ,.bypass_v_i(bypass_v_li)
    ,.bypass_data_o(bypass_data_lo)
    ,.bypass_mask_o(bypass_mask_lo)
  ); 

  logic [2*data_mask_width_lp-1:0] sbuf_data_mem_w_mask;
  logic [2*data_width_p-1:0] sbuf_data_mem_data;
  assign sbuf_data_mem_data = {2{sbuf_data_lo}};

  assign sbuf_data_mem_w_mask = sbuf_set_lo
    ? {sbuf_mask_lo, {(data_mask_width_lp){1'b0}}}
    : {{(data_mask_width_lp){1'b0}}, sbuf_mask_lo};

  // for 32-bit data width
  if (data_width_p == 32) begin

    assign sbuf_data_li = (word_op_v_r | mask_op_v_r)
      ? data_v_r
      : (half_op_v_r 
        ? {2{data_v_r[(data_width_p>>1)-1:0]}}
        : {4{data_v_r[(data_width_p>>2)-1:0]}});
  
    assign sbuf_mask_li = mask_op_v_r
      ? mask_v_r
      : (word_op_v_r 
        ? 4'b1111
        : (half_op_v_r
          ? {addr_v_r[1], addr_v_r[1], ~addr_v_r[1], ~addr_v_r[1]}
          : {(addr_v_r[1] & addr_v_r[0]),
            (addr_v_r[1] & ~addr_v_r[0]),
            (~addr_v_r[1] & addr_v_r[0]),
            (~addr_v_r[1] & ~addr_v_r[0])}));
  end


  // output stage
  //
  logic [data_width_p-1:0] ld_data_set_picked;
  logic [data_width_p-1:0] bypass_data_masked;
  logic [data_width_p-1:0] snoop_or_ld_data;
  logic [data_width_p-1:0] ld_data_masked;

  assign ld_data_set_picked = tag_hit_v[1]
    ? ld_data_v_r[data_width_p+:data_width_p]
    : ld_data_v_r[0+:data_width_p];

  bsg_mux_segmented #(
    .segments_p(data_mask_width_lp)
    ,.segment_width_p(8)
  ) bypass_mux_segmented (
    .data0_i(ld_data_set_picked)
    ,.data1_i(bypass_data_lo)
    ,.sel_i(bypass_mask_lo)
    ,.data_o(bypass_data_masked)
  );
  

  assign snoop_or_ld_data = miss_v
    ? snoop_word_lo
    : bypass_data_masked;

  for (genvar i = 0; i < (data_width_p>>3); i++) begin
    assign ld_data_masked[8*i+:8] = {8{mask_v_r[i]}} & snoop_or_ld_data[8*i+:8];
  end

  if (data_width_p == 32) begin

    logic [15:0] data_half_selected;
    logic [7:0] data_byte_selected;
    logic half_sigext;
    logic byte_sigext;

    bsg_mux #(.width_p(16), .els_p(2)) half_mux (
      .data_i(snoop_or_ld_data)
      ,.sel_i(addr_v_r[1])
      ,.data_o(data_half_selected)
    );

    bsg_mux #(.width_p(8), .els_p(4)) byte_mux (
      .data_i(snoop_or_ld_data)
      ,.sel_i(addr_v_r[1:0])
      ,.data_o(data_byte_selected)
    );

    assign half_sigext = sigext_op_v_r & data_half_selected[15];
    assign byte_sigext = sigext_op_v_r & data_byte_selected[7];
  
    always_comb begin
      if (retval_op_v) begin
        if (taglv_op_v_r) begin
          data_o = (32)'(valid_v_r[addr_set_v]);
        end
        else if (tagla_op_v_r) begin
          data_o = {tag_v_r[addr_set_v], addr_index_v,
            {(lg_block_size_in_words_lp+2){1'b0}}
          };
        end
        else if (mask_op_v_r) begin
          data_o = ld_data_masked;
        end
        else if (word_op_v_r) begin
          data_o = snoop_or_ld_data;
        end
        else if (half_op_v_r) begin
          data_o = {{16{half_sigext}}, data_half_selected};
        end
        else if (byte_op_v_r) begin
          data_o = {{24{byte_sigext}}, data_byte_selected};
        end
        else begin
          data_o = '0;
        end
      end
      else begin
        data_o = '0;
      end 
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

  logic tl_ready;
  assign tl_ready = miss_v
    ? (~(tagst_op & v_i) & ~miss_tag_mem_v_lo & ~dma_data_mem_v_lo & ~recover_lo)
    : 1'b1;
  assign ready_o = v_tl_r
    ? (v_we & tl_ready)
    : tl_ready;


  // tag_mem
  //
  assign tag_mem_data_li = miss_v
    ? miss_tag_mem_data_lo
    : {2{cache_pkt.data[data_width_p-1], cache_pkt.data[tag_width_lp-1:0]}};

  assign tag_mem_addr_li = miss_v
    ? (recover_lo ? addr_index_tl : (miss_tag_mem_v_lo ? miss_tag_mem_addr_lo : addr_index))
    : addr_index;

  assign tag_mem_w_mask_li = miss_v
    ? miss_tag_mem_w_mask_lo
    : {{(1+tag_width_lp){addr_set}}, {(1+tag_width_lp){~addr_set}}};

  assign tag_mem_v_li = ((tag_read_op & ready_o & v_i)
    | (recover_lo & tag_read_op_tl_r & v_tl_r)
    | miss_tag_mem_v_lo
    | (tagst_op & ready_o & v_i)); 
  
  assign tag_mem_w_li = miss_v
    ? miss_tag_mem_w_lo
    : (tagst_op & ready_o & v_i);

  // data_mem
  //
  assign data_mem_data_li = dma_data_mem_w_lo
    ? dma_data_mem_data_lo
    : sbuf_data_mem_data;

  assign data_mem_addr_li = recover_lo ? {addr_index_tl, addr_block_offset_tl}
    : (dma_data_mem_v_lo ? dma_data_mem_addr_lo
    : ((ld_op & v_i & ready_o) ? {addr_index, addr_block_offset}
    : sbuf_addr_lo[lg_data_mask_width_lp+:lg_block_size_in_words_lp+lg_sets_lp]));

  assign data_mem_w_mask_li = dma_data_mem_w_lo
    ? dma_data_mem_w_mask_lo
    : sbuf_data_mem_w_mask;

  assign data_mem_v_li = ((v_i & ld_op & ready_o)
    | (v_tl_r & recover_lo & ld_op_tl_r)
    | dma_data_mem_v_lo
    | (sbuf_v_lo & sbuf_yumi_li)
  );
  
  assign data_mem_w_li = dma_data_mem_w_lo | (sbuf_v_lo & sbuf_yumi_li);


  // stat_mem
  //
  assign stat_mem_data_li[3] = 1'b0;
  assign stat_mem_data_li[2:0] = miss_v
    ? miss_stat_mem_data_lo
    : {st_op_v_r, st_op_v_r, tag_hit_v[1]};

  assign stat_mem_addr_li = addr_index_v;
    
  assign stat_mem_w_mask_li[3] = 1'b0;
  assign stat_mem_w_mask_li[2:0] = miss_v
    ? miss_stat_mem_w_mask_lo
    : {tag_hit_v[1] & st_op_v_r, tag_hit_v[0] & st_op_v_r, st_op_v_r | ld_op_v_r};
  
  assign stat_mem_v_li = miss_v
    ? miss_stat_mem_v_lo
    : ((st_op_v_r | ld_op_v_r) & v_o & yumi_i);

  assign stat_mem_w_li = miss_v
    ? miss_stat_mem_w_lo
    : ((st_op_v_r | ld_op_v_r) & v_o & yumi_i);


  // store buffer
  //
  assign sbuf_v_li = st_op_v_r & v_o & yumi_i;
  assign sbuf_set_li = miss_v ? chosen_set_lo : tag_hit_v[1];
  //assign sbuf_yumi_li = sbuf_v_lo & (~(ld_op & v_i) | (miss_v & ~miss_done_lo & ~recover_lo)); 
  assign sbuf_yumi_li = sbuf_v_lo & ~(ld_op & v_i & ready_o) & (~dma_data_mem_v_lo); 

  assign bypass_addr_li = addr_tl_r;
  assign bypass_v_li = ld_op_tl_r & v_tl_r & v_we;


  // synopsys translate_off

  initial begin
    assert(data_width_p == 32)
      else $error("only 32-bit for data_width_p supported now.");
  end

  if (debug_p) begin
    always_ff @ (posedge clk_i) begin
      if (v_o & yumi_i) begin
        if (ld_op_v_r) begin
          $display("<VCACHE> M[%4h] == %8h // %8t", addr_v_r, data_o, $time);
        end
        
        if (st_op_v_r) begin
          $display("<VCACHE> M[%4h] := %8h // %8t", addr_v_r, sbuf_data_li, $time);
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

  if (axe_trace_p) begin
    bsg_nonsynth_axe_tracer #(
      .data_width_p(data_width_p)
      ,.addr_width_p(addr_width_p)
    ) axe_tracer (
      .clk_i(clk_i)
      ,.v_i(v_o & yumi_i)
      ,.store_op_i(st_op_v_r)
      ,.load_op_i(ld_op_v_r)
      ,.addr_i(addr_v_r)
      ,.store_data_i(sbuf_data_li)
      ,.load_data_i(data_o)
    );
  end

  // synopsys translate_on


endmodule
