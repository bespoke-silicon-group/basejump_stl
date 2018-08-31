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

module bsg_cache
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="inv"
    ,parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,parameter tag_width_lp=addr_width_p-2-lg_sets_lp-lg_block_size_in_words_lp
    ,parameter bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(addr_width_p,data_width_p)
    ,parameter bsg_cache_dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
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
  logic mask;
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

  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);
  bsg_cache_pkt_s cache_pkt;

  assign cache_pkt = cache_pkt_i;
  assign byte_op = (cache_pkt.opcode[2:0] == 3'b000);
  assign half_op = (cache_pkt.opcode[2:0] == 3'b001);
  assign word_op = (cache_pkt.opcode[2:0] == 3'b010);
  assign mask_op = (cache_pkt.opcode[2:0] == 3'b100);

  assign ld_op = (cache_pkt.opcode[4:3] == 2'b00);
  assign st_op = (cache_pkt.opcode[4:3] == 2'b01);
  assign tagst_op = (cache_pkt.opcode == TAGST);
  assign tagfl_op = (cache_pkt.opcode == TAGFL);
  assign taglv_op = (cache_pkt.opcode == TAGLV);
  assign tagla_op = (cache_pkt.opcode == TAGLA);
  assign afl_op = (cache_pkt.opcode == AFL);
  assign aflinv_op = (cache_pkt.opcode == AFLINV);
  assign ainv_op = (cache_pkt.opcode == AINV);
  assign tag_read_op = ld_op | st_op | tagfl_op | taglv_op | tagla_op
    | afl_op | aflinv_op | ainv_op;

  // tl_stage
  //
  logic v_tl_r;
  logic sigext_op_tl_r;
  logic word_op_tl_r
  logic half_op_tl_r;
  logic byte_op_tl_r;
  logic mask_op_tl_r;
  logic [(data_width_p>>3)-1:0] mask_tl_r;
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

  // v stage
  //
  logic v_we;
  logic v_v_r;
  logic sigext_op_v_r;
  logic word_op_v_r;
  logic half_op_v_r;
  logic byte_op_v_r;
  logic mask_op_v_r;
  logic [(data_width_p>>3)-1:0] mask_v_r;
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

  always_ff @ (posedge clk_i) begin
    if (v_we) begin
      v_v_r <= v_tl_r;
      if (v_tl_r) begin
        sigext_op_v_r <= sigext_op_tl_r;
        word_op_v_r <= word_op_tl_r;
        half_op_v_r <= half_op_tl_r;
        byte_op_v_r <= byte_op_tl_r;
        mask_op_v_r <= mask_op_tl_r;
        mask_v_r <= mask_tl_r;
        
        
    
      end
    end
  end

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
 

  // data_mem
  //
  logic [data_width_p*2-1:0] data_mem_data_li;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_mem_addr_li;
  logic data_mem_v_li;
  logic [((data_width_p*2)>>3)-1:0] data_mem_w_mask_li;
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

  // stat_mem
  //
  logic [2:0] stat_mem_data_li;
  logic [lg_sets_lp-1:0] stat_mem_addr_li;
  logic stat_mem_v_li;
  logic [2:0] stat_mem_w_mask_li;
  logic stat_mem_w_li;
  logic [2:0] stat_mem_data_lo;

  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p(3)
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

  bsg_cache_miss #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.tag_width_p(tag_width_p)
    ,.lg_block_size_in_words_lp(lg_block_size_in_words_lp)
    ,.lg_sets_lp(lg_sets_lp)
  ) miss (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.v_v_i(v_v_r)
    ,.miss_v_i(miss_v)
    ,.ld_op_v_i(ld_op_v_r)
    ,.st_op_v_i(st_op_v_r)
    ,.tagfl_op_v_i(tagfl_op_v_r)
    ,.afl_op_v_i(afl_op_v_r)
    ,.aflinv_op_v_i(afl_op_v_r)
    ,.ainv_op_v_i(ainv_op_v_r)
    ,.addr_v_i(addr_v_r)

    ,.tag_v_i()
    ,.valid_v_i()
    ,.tag_hit_v_i()

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
    
    ,.ack_i(v_o & yumi_i) 
  );

  // dma
  // 
  logic [data_width_p-1:0] snoop_word_lo;
  logic dma_data_mem_v_lo;
  logic dma_data_mem_w_lo;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] dma_data_mem_addr_lo;
  logic [2*(data_width_p>>3)-1:0] dma_data_mem_w_mask_lo;
  logic [2*data_width_p-1:0] dma_data_mem_data_o;

  bsg_cache_dma #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.lg_block_size_in_words_lp)
    ,.lg_sets_lp(lg_sets_lp)
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
  logic sbuf_v_r;
  logic [(data_width_p>>3)-1:0] sbuf_mask_r;
  logic [data_width_p-1:0] sbuf_data_r;
  logic [addr_width_p-1:0] sbuf_addr_r;
  logic sbuf_set_r;
  

endmodule
