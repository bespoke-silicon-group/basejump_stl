/**
 *    bsg_cache_non_blocking.v
 *
 *    Non-blocking cache
 *
 *    @author tommy
 *
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

    , parameter miss_fifo_els_p=32
    
    , parameter cache_pkt_width_lp=`bsg_cache_non_blocking_pkt_width(id_width_p,addr_width_p,data_width_p)
    , parameter dma_pkt_width_lp=`bsg_cache_non_blocking_dma_pkt_width(addr_width_p)
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [cache_pkt_width_lp-1:0] cache_pkt_i
    , output logic ready_o 

    , output logic [data_width_p-1:0] data_o
    , output logic v_o

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
  localparam data_mask_width_lp = (data_width_p>>3);
  localparam lg_data_mask_width_lp = `BSG_SAFE_CLOG2(data_mask_width_lp);
  localparam tag_width_lp = (addr_width_p-lg_data_mask_width_lp-lg_block_size_in_words_lp-lg_sets_lp);

  localparam tag_info_width_lp = `bsg_cache_non_blocking_tag_info_width(tag_width_lp);


  // packet decoding
  //
  logic [lg_ways_lp-1:0] addr_way;
  logic [lg_sets_lp-1:0] addr_index;

  `declare_bsg_cache_non_blocking_pkt_s(id_width_p, addr_width_p, data_width_p);
  bsg_cache_non_blocking_pkt_s cache_pkt;
  assign cache_pkt = cache_pkt_i;

  bsg_cache_non_blocking_decode_s decode;
  bsg_cache_non_blocking_decode decode0
  (
    .opcode_i(cache_pkt.opcode)
    ,.decode_o(decode)
  );

  assign addr_way
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp+:lg_ways_lp];
  assign addr_index
    = cache_pkt.addr[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];


  // tl_stage
  //
  logic stall_tl;
  logic v_tl_r;
  bsg_cache_non_blocking_decode_s decode_tl_r;
  logic [id_width_p-1:0] id_tl_r;
  logic [addr_width_p-1:0] addr_tl_r;
  logic [data_width_p-1:0] data_tl_r;
  logic [data_mask_width_lp-1:0] mask_tl_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_tl_r <= 1'b0;
      {decode_tl_r
      ,id_tl_r
      ,addr_tl_r
      ,data_tl_r
      ,mask_tl_r} <= '0;
    end
    else begin
      if (ready_o) begin
        v_tl_r <= v_i;
        if (v_i) begin
          id_tl_r <= cache_pkt.id;
          addr_tl_r <= cache_pkt.addr;
          data_tl_r <= cache_pkt.data;
          mask_tl_r <= cache_pkt.mask;
          decode_tl_r <= decode;
        end
      end
      else begin
        if (~stall_tl) begin
          v_tl_r <= 1'b0;
        end
      end
    end
  end


  // tag_mem
  //
  `declare_bsg_cache_non_blocking_tag_info_s(tag_width_lp);
  logic tag_mem_v_li;
  logic tag_mem_w_li;
  logic [lg_sets_lp-1:0] tag_mem_addr_li;
  bsg_cache_non_blocking_tag_info_s [ways_p-1:0] tag_mem_data_li;
  bsg_cache_non_blocking_tag_info_s [ways_p-1:0] tag_mem_mask_li;
  bsg_cache_non_blocking_tag_info_s [ways_p-1:0] tag_mem_data_lo;

  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p(ways_p*tag_info_width_lp)
    ,.els_p(sets_p)
    ,.latch_last_read_p(1)
  ) tag_mem0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i(tag_mem_v_li)
    ,.w_i(tag_mem_w_li)
    ,.addr_i(tag_mem_addr_li)
    ,.data_i(tag_mem_data_li)
    ,.w_mask_i(tag_mem_mask_li)
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

  
  logic [ways_p-1:0] tag_hit_tl;
  logic [lg_ways_lp-1:0] tag_hit_way_id_tl;
  logic tag_hit_found_tl;

  for (genvar i = 0; i < ways_p; i++) begin
    assign tag_hit_tl[i] = (addr_tag_tl == tag_tl[i]) & valid_tl[i];
  end  

  bsg_priority_encode #(
    .width_p(ways_p)
    ,.lo_to_hi_p(1)
  ) tag_hit_pe (
    .i(tag_hit_tl)
    ,.addr_o(tag_hit_way_id_tl)
    ,.v_o(tag_hit_found_tl)
  );

  // miss FIFO
  //
  `declare_bsg_cache_non_blocking_miss_fifo_entry_s(id_width_p,addr_width_p,data_width_p);  
  bsg_cache_non_blocking_miss_fifo_entry_s miss_fifo_data_li;
  logic miss_fifo_v_li;
  logic miss_fifo_ready_lo;

  bsg_cache_non_blocking_miss_fifo_entry_s miss_fifo_data_lo;
  logic miss_fifo_v_lo;
  logic miss_fifo_yumi_li;
  bsg_cache_non_blocking_miss_fifo_yumi_op_e miss_fifo_yumi_op_li; 
  logic miss_fifo_rollback_li;
  logic miss_fifo_empty_lo;
  

  bsg_cache_non_blocking_miss_fifo #(
    .width_p($bits(bsg_cache_non_blocking_miss_fifo_entry_s))
    ,.els_p(miss_fifo_els_p)
  ) miss_fifo0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.data_i(miss_fifo_data_li)
    ,.v_i(miss_fifo_v_li)
    ,.ready_o(miss_fifo_ready_lo)

    ,.v_o(miss_fifo_v_lo)
    ,.data_o(miss_fifo_data_lo)
    ,.yumi_i(miss_fifo_yumi_li)
    ,.yumi_op_i(miss_fifo_yumi_op_li)

    ,.rollback_i(miss_fifo_rollback_li)
    ,.empty_o(miss_fifo_empty_lo)
  );






  // data bank
  //
  bsg_cache_non_blocking_data_bank #(
  ) db0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i()
    ,.w_i()
    ,. 
  );









  // MHU
  //
  bsg_cache_non_blocking_mhu #(
  ) mhu0 (
  );









  // DMA engine
  //
  logic dma_data_mem_v_lo;
  logic dma_data_mem_w_lo;
  logic [lg_ways_lp-1:0] dma_data_mem_way_lo;
  logic [lg_block_size_in_words_lp+lg_sets_lp-1:0] dma_data_mem_addr_lo;
  logic [data_width_p-1:0] dma_data_mem_data_lo;
  logic [data_width_p-1:0] dma_data_mem_data_li;
  

  bsg_cache_non_blocking_dma #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
  ) dma0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
  
    ,.dma_cmd_i()
    ,.dma_cmd_v_i()
    ,.dma_cmd_ready_o()

    ,.dma_cmd_return_o()
    ,.done_o()
    ,.pending_o()
    ,.ack_i()

    ,.data_mem_v_o(dma_data_mem_v_lo)
    ,.data_mem_w_o(dma_data_mem_w_lo)
    ,.data_mem_way_o(dma_data_mem_way_lo)
    ,.data_mem_addr_o(dma_data_mem_addr_lo)
    ,.data_mem_data_o(dma_data_mem_data_lo)
    ,.data_mem_data_i(dma_data_mem_data_li)
    
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
