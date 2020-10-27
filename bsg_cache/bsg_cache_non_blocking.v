/**
 *    bsg_cache_non_blocking.v
 *
 *    Non-blocking cache.
 *
 *    @author tommy
 *
 *    For design doc, follow this link.
 *    https://docs.google.com/document/d/1hf4WgCuf4CGjPMZXH5AplK7k9wtcAN2uw2moZhroryU/edit
 */


`include "bsg_defines.v"

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
    , input yumi_i

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
  `declare_bsg_cache_non_blocking_tag_mem_pkt_s(ways_p,sets_p,data_width_p,tag_width_lp);
  `declare_bsg_cache_non_blocking_miss_fifo_entry_s(id_width_p,addr_width_p,data_width_p);
  `declare_bsg_cache_non_blocking_dma_cmd_s(ways_p,sets_p,tag_width_lp);
  

  // stall signal
  // When the pipeline is stalled, DMA can still operate, and move data in and
  // output of data_mem. TL stage is not able to access data_mem, but it can
  // still enqueue missed requests into miss_fifo. MHU cannot dequeue or invalidate 
  // an entry from miss FIFO.
  wire stall = v_o & ~yumi_i;


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
  logic tl_data_mem_pkt_ready_li;
  logic tl_block_loading;

  bsg_cache_non_blocking_stat_mem_pkt_s tl_stat_mem_pkt_lo;
  logic tl_stat_mem_pkt_v_lo;
  logic tl_stat_mem_pkt_ready_li;

  bsg_cache_non_blocking_miss_fifo_entry_s tl_miss_fifo_entry_lo;
  logic tl_miss_fifo_v_lo;
  logic tl_miss_fifo_ready_li;
  
  logic mgmt_v_lo;
  logic [ways_p-1:0] valid_tl_lo;
  logic [ways_p-1:0] lock_tl_lo;
  logic [ways_p-1:0][tag_width_lp-1:0] tag_tl_lo;
  bsg_cache_non_blocking_decode_s decode_tl_lo;
  logic [addr_width_p-1:0] addr_tl_lo;
  logic [id_width_p-1:0] id_tl_lo;
  logic [data_width_p-1:0] data_tl_lo;
  logic [lg_ways_lp-1:0] tag_hit_way_lo;
  logic tag_hit_found_lo;
  logic mgmt_yumi_li;

  bsg_cache_non_blocking_tag_mem_pkt_s mhu_tag_mem_pkt_lo;
  logic mhu_tag_mem_pkt_v_lo;
  logic mhu_idle;
  logic mhu_recover;

  logic [lg_ways_lp-1:0] curr_mhu_way_id;
  logic [lg_sets_lp-1:0] curr_mhu_index;
  logic curr_mhu_v;
  logic [lg_ways_lp-1:0] curr_dma_way_id;
  logic [lg_sets_lp-1:0] curr_dma_index;
  logic curr_dma_v;

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
    ,.mask_i(cache_pkt.mask)
    ,.decode_i(decode)
    ,.ready_o(ready_o)

    ,.data_mem_pkt_v_o(tl_data_mem_pkt_v_lo)
    ,.data_mem_pkt_o(tl_data_mem_pkt_lo)
    ,.data_mem_pkt_ready_i(tl_data_mem_pkt_ready_li)
    ,.block_loading_o(tl_block_loading)

    ,.stat_mem_pkt_v_o(tl_stat_mem_pkt_v_lo)
    ,.stat_mem_pkt_o(tl_stat_mem_pkt_lo)
    ,.stat_mem_pkt_ready_i(tl_stat_mem_pkt_ready_li)

    ,.miss_fifo_v_o(tl_miss_fifo_v_lo)
    ,.miss_fifo_entry_o(tl_miss_fifo_entry_lo)
    ,.miss_fifo_ready_i(tl_miss_fifo_ready_li)

    ,.mgmt_v_o(mgmt_v_lo)
    ,.valid_tl_o(valid_tl_lo)
    ,.lock_tl_o(lock_tl_lo)
    ,.tag_tl_o(tag_tl_lo)
    ,.decode_tl_o(decode_tl_lo)
    ,.addr_tl_o(addr_tl_lo)
    ,.id_tl_o(id_tl_lo)
    ,.data_tl_o(data_tl_lo)
    ,.tag_hit_way_o(tag_hit_way_lo)
    ,.tag_hit_found_o(tag_hit_found_lo)
    ,.mgmt_yumi_i(mgmt_yumi_li)

    ,.mhu_tag_mem_pkt_v_i(mhu_tag_mem_pkt_v_lo)
    ,.mhu_tag_mem_pkt_i(mhu_tag_mem_pkt_lo)
    ,.mhu_idle_i(mhu_idle)
    ,.recover_i(mhu_recover)

    ,.curr_dma_way_id_i(curr_dma_way_id)
    ,.curr_dma_index_i(curr_dma_index)
    ,.curr_dma_v_i(curr_dma_v)

    ,.curr_mhu_way_id_i(curr_mhu_way_id)
    ,.curr_mhu_index_i(curr_mhu_index)
    ,.curr_mhu_v_i(curr_mhu_v)
  );


  // miss FIFO
  //
  bsg_cache_non_blocking_miss_fifo_entry_s miss_fifo_data_li;
  logic miss_fifo_v_li;
  logic miss_fifo_ready_lo;

  bsg_cache_non_blocking_miss_fifo_entry_s miss_fifo_data_lo;
  logic miss_fifo_v_lo;
  logic miss_fifo_yumi_li;
  logic miss_fifo_scan_not_dq_li;

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
    ,.scan_not_dq_i(miss_fifo_scan_not_dq_li)

    ,.rollback_i(miss_fifo_rollback_li)
    ,.empty_o(miss_fifo_empty_lo)
  );

  assign miss_fifo_v_li = tl_miss_fifo_v_lo;
  assign miss_fifo_data_li = tl_miss_fifo_entry_lo;
  assign tl_miss_fifo_ready_li = miss_fifo_ready_lo;


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


  // DMA read data buffer
  // When the DMA engine reads the data_mem for eviction, the output 
  // is buffered here, in case dma_data_o is stalled. 
  logic dma_read_en;
  logic dma_read_en_r;
  logic [data_width_p-1:0] dma_read_data_r;

  bsg_dff_reset #(
    .width_p(1)
  ) dma_read_en_dff (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(dma_read_en)
    ,.data_o(dma_read_en_r)
  );

  bsg_dff_en_bypass #(
    .width_p(data_width_p)
  ) dma_read_buffer (
    .clk_i(clk_i)
    ,.en_i(dma_read_en_r)
    ,.data_i(data_mem_data_lo)
    ,.data_o(dma_read_data_r)
  );

  
  // Load data buffer
  // When the TL stage or MHU does load, the output is buffered here.
  logic load_read_en;
  logic load_read_en_r;
  logic [data_width_p-1:0] load_read_data_r;

  bsg_dff_reset #(
    .width_p(1)
  ) load_read_en_eff (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(load_read_en)
    ,.data_o(load_read_en_r)
  );

  bsg_dff_en_bypass #(
    .width_p(data_width_p)
  ) load_read_buffer (
    .clk_i(clk_i)
    ,.en_i(load_read_en_r)
    ,.data_i(data_mem_data_lo)
    ,.data_o(load_read_data_r)
  );


  // stat_mem
  //
  bsg_cache_non_blocking_stat_mem_pkt_s stat_mem_pkt_li;
  logic stat_mem_v_li;
  logic [ways_p-1:0] dirty_lo;
  logic [ways_p-2:0] lru_bits_lo;

  bsg_cache_non_blocking_stat_mem #(
    .ways_p(ways_p)
    ,.sets_p(sets_p)
  ) stat_mem0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(stat_mem_v_li)
    ,.stat_mem_pkt_i(stat_mem_pkt_li)

    ,.dirty_o(dirty_lo)
    ,.lru_bits_o(lru_bits_lo)
  );


  // MHU
  //
  bsg_cache_non_blocking_data_mem_pkt_s mhu_data_mem_pkt_lo;
  logic [id_width_p-1:0] mhu_data_mem_pkt_id_lo;
  logic mhu_data_mem_pkt_v_lo;
  logic mhu_data_mem_pkt_yumi_li;

  bsg_cache_non_blocking_stat_mem_pkt_s mhu_stat_mem_pkt_lo;
  logic mhu_stat_mem_pkt_v_lo;

  bsg_cache_non_blocking_dma_cmd_s dma_cmd_lo;
  logic dma_cmd_v_lo;

  bsg_cache_non_blocking_dma_cmd_s dma_cmd_return_li;
  logic dma_done_li;
  logic dma_pending_li;
  logic dma_ack_lo;

  logic mgmt_data_v_lo;
  logic [data_width_p-1:0] mgmt_data_lo;  
  logic [id_width_p-1:0] mgmt_id_lo;
  logic mgmt_data_yumi_li;

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

    ,.mgmt_v_i(mgmt_v_lo)
    ,.mgmt_yumi_o(mgmt_yumi_li)
    ,.mgmt_data_v_o(mgmt_data_v_lo)
    ,.mgmt_data_o(mgmt_data_lo)
    ,.mgmt_id_o(mgmt_id_lo)
    ,.mgmt_data_yumi_i(mgmt_data_yumi_li)

    ,.decode_tl_i(decode_tl_lo)  
    ,.addr_tl_i(addr_tl_lo)
    ,.id_tl_i(id_tl_lo)

    ,.idle_o(mhu_idle)
    ,.recover_o(mhu_recover)
    ,.tl_block_loading_i(tl_block_loading)

    ,.data_mem_pkt_v_o(mhu_data_mem_pkt_v_lo)
    ,.data_mem_pkt_o(mhu_data_mem_pkt_lo)
    ,.data_mem_pkt_yumi_i(mhu_data_mem_pkt_yumi_li)
    ,.data_mem_pkt_id_o(mhu_data_mem_pkt_id_lo)

    ,.stat_mem_pkt_v_o(mhu_stat_mem_pkt_v_lo)
    ,.stat_mem_pkt_o(mhu_stat_mem_pkt_lo)
    ,.dirty_i(dirty_lo)
    ,.lru_bits_i(lru_bits_lo)

    ,.tag_mem_pkt_v_o(mhu_tag_mem_pkt_v_lo)
    ,.tag_mem_pkt_o(mhu_tag_mem_pkt_lo)
    ,.valid_tl_i(valid_tl_lo)
    ,.lock_tl_i(lock_tl_lo)
    ,.tag_tl_i(tag_tl_lo) 
    ,.tag_hit_way_i(tag_hit_way_lo)
    ,.tag_hit_found_i(tag_hit_found_lo)

    ,.curr_mhu_way_id_o(curr_mhu_way_id)
    ,.curr_mhu_index_o(curr_mhu_index)
    ,.curr_mhu_v_o(curr_mhu_v)

    ,.miss_fifo_v_i(miss_fifo_v_lo)
    ,.miss_fifo_entry_i(miss_fifo_data_lo)
    ,.miss_fifo_yumi_o(miss_fifo_yumi_li)
    ,.miss_fifo_yumi_op_o(miss_fifo_yumi_op_li)
    ,.miss_fifo_scan_not_dq_o(miss_fifo_scan_not_dq_li)
    ,.miss_fifo_rollback_o(miss_fifo_rollback_li)
    ,.miss_fifo_empty_i(miss_fifo_empty_lo)

    ,.dma_cmd_o(dma_cmd_lo)
    ,.dma_cmd_v_o(dma_cmd_v_lo)

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

    ,.dma_cmd_return_o(dma_cmd_return_li)
    ,.done_o(dma_done_li)
    ,.pending_o(dma_pending_li)
    ,.ack_i(dma_ack_lo)

    ,.curr_dma_way_id_o(curr_dma_way_id)
    ,.curr_dma_index_o(curr_dma_index)
    ,.curr_dma_v_o(curr_dma_v)

    ,.data_mem_pkt_v_o(dma_data_mem_pkt_v_lo)
    ,.data_mem_pkt_o(dma_data_mem_pkt_lo)
    ,.data_mem_data_i(dma_read_data_r)
    
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


  ///                   ///
  ///   CTRL  LOGIC     ///
  ///                   ///


  // data_mem ctrl logic 
  //
  // Access priority in descending order.
  // 1) DMA engine
  // 2) MHU
  // 3) TL stage (hit). When neither DMA nor MHU is accessing the data_mem,
  //    ready signal to TL stage goes high.

  always_comb begin

    data_mem_v_li = 1'b0;
    data_mem_pkt_li = dma_data_mem_pkt_lo;
    mhu_data_mem_pkt_yumi_li = 1'b0;
    tl_data_mem_pkt_ready_li = 1'b0;
    dma_read_en = 1'b0;
    load_read_en = 1'b0;

    if (dma_data_mem_pkt_v_lo) begin
      data_mem_pkt_li = dma_data_mem_pkt_lo;
      data_mem_v_li = 1'b1;
      dma_read_en =  ~dma_data_mem_pkt_lo.write_not_read;
    end
    else if (mhu_data_mem_pkt_v_lo) begin
      data_mem_pkt_li = mhu_data_mem_pkt_lo;
      data_mem_v_li = ~stall;
      mhu_data_mem_pkt_yumi_li = ~stall;
      load_read_en = ~mhu_data_mem_pkt_lo.write_not_read & ~stall;
    end
    else begin
      data_mem_pkt_li = tl_data_mem_pkt_lo;
      data_mem_v_li = tl_data_mem_pkt_v_lo & ~stall;
      tl_data_mem_pkt_ready_li = ~stall;
      load_read_en = ~tl_data_mem_pkt_lo.write_not_read & tl_data_mem_pkt_v_lo & ~stall;
    end

  end


  // stat_mem ctrl logic
  //
  // MHU has higher priority over TL stage.
  // MHU accesses tag_mem and stat_mem together.
  always_comb begin
    
    stat_mem_v_li = 1'b0;
    stat_mem_pkt_li = mhu_stat_mem_pkt_lo;
    tl_stat_mem_pkt_ready_li = 1'b0;

    if (mhu_stat_mem_pkt_v_lo) begin
      stat_mem_v_li = 1'b1;
      stat_mem_pkt_li = mhu_stat_mem_pkt_lo;
    end
    else begin
      tl_stat_mem_pkt_ready_li = ~stall;
      stat_mem_pkt_li = tl_stat_mem_pkt_lo;
      stat_mem_v_li = tl_stat_mem_pkt_v_lo & ~stall;
    end
  end


  // Output Logic
  //
  // Output valid signal lasts for only one cycle. The consumer needs to be
  // ready to accept the data whenever it becomes ready.
  // When the pipeline is stalled, these register values stay the same.
  // But the pipeline can only stall, when the output is valid.
  logic [data_width_p-1:0] mgmt_data_r, mgmt_data_n;
  logic [id_width_p-1:0] out_id_r, out_id_n;
  logic mgmt_data_v_r, mgmt_data_v_n;
  logic store_v_r, store_v_n;
  logic load_v_r, load_v_n;

  always_comb begin

    if (stall) begin
      out_id_n = out_id_r;
      mgmt_data_n = mgmt_data_r;
      store_v_n = store_v_r;
      load_v_n = load_v_r;
      mgmt_data_v_n = mgmt_data_v_r;
      mgmt_data_yumi_li = 1'b0;
    end
    else begin
      out_id_n = out_id_r;
      mgmt_data_n = mgmt_data_r;
      store_v_n = 1'b0;
      load_v_n = 1'b0;
      mgmt_data_v_n = 1'b0;
      mgmt_data_yumi_li = 1'b0;

      if (mgmt_data_v_lo) begin
        mgmt_data_n = mgmt_data_lo;
        out_id_n = mgmt_id_lo;
        mgmt_data_v_n = mgmt_data_v_lo;
        mgmt_data_yumi_li = mgmt_data_v_lo;
      end
      else if (mhu_data_mem_pkt_yumi_li) begin
        out_id_n = mhu_data_mem_pkt_id_lo;
        store_v_n = mhu_data_mem_pkt_lo.write_not_read;
        load_v_n = ~mhu_data_mem_pkt_lo.write_not_read;
      end
      else if (tl_data_mem_pkt_ready_li & tl_data_mem_pkt_v_lo) begin
        out_id_n = id_tl_lo;
        store_v_n = tl_data_mem_pkt_lo.write_not_read;
        load_v_n = ~tl_data_mem_pkt_lo.write_not_read;
      end
    end
    
 
    if (mgmt_data_v_r)
      data_o = mgmt_data_r;
    else if (load_v_r)
      data_o = load_read_data_r;
    else
      data_o = '0;
    
    id_o = out_id_r;
    v_o = mgmt_data_v_r | store_v_r | load_v_r;
  
  end


  // synopsys sync_set_reset "reset_i"
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      mgmt_data_r <= '0;
      out_id_r <= '0;
      mgmt_data_v_r <= 1'b0;
      store_v_r <= 1'b0;
      load_v_r <= 1'b0;
    end
    else begin
      mgmt_data_r <= mgmt_data_n;
      out_id_r <= out_id_n;
      mgmt_data_v_r <= mgmt_data_v_n;
      store_v_r <= store_v_n;
      load_v_r <= load_v_n;
    end
  end

 
endmodule
