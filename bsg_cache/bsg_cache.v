/**
 *  bsg_cache.v
 *
 *  @param addr_width_p address bit-width.
 *  @param block_size_in_words_p number of words in cache block. should be power of 2.
 *  @param sets_p number of sets in cache.
 */

`include "bsg_cache_pkt.vh"

module bsg_cache
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="inv"
    ,parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,parameter tag_width_lp=addr_width_p-2-lg_sets_lp-lg_block_size_in_words_lp
    ,parameter bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(addr_width_p,32))
(
  input clock_i
  ,input reset_i

  // input
  ,input [bsg_cache_pkt_width_lp-1:0] packet_i
  ,input v_i
  ,output logic ready_o

  // output
  ,output logic [31:0] data_o
  ,output logic v_o
  ,input yumi_i

  // DMA request channel
  ,output logic dma_req_ch_write_not_read_o
  ,output logic [addr_width_p-1:0] dma_req_ch_addr_o
  ,output logic dma_req_ch_v_o
  ,input dma_req_ch_yumi_i

  // DMA read channel
  ,input [31:0] dma_read_ch_data_i
  ,input dma_read_ch_v_i
  ,output logic dma_read_ch_ready_o

  // DMA write channel
  ,output logic [31:0] dma_write_ch_data_o
  ,output logic dma_write_ch_v_o
  ,input dma_write_ch_yumi_i
);

  // logic declaration
  logic v_tl_r, v_v_r;
  logic sigext_op_tl_r, sigext_op_v_r;
  logic word_op, word_op_tl_r, word_op_v_r;
  logic half_op, half_op_tl_r, half_op_v_r;
  logic byte_op, byte_op_tl_r, byte_op_v_r;
  logic mask_op, mask_op_tl_r, mask_op_v_r;
  logic [3:0] byte_mask, byte_mask_tl_r, byte_mask_v_r;
  logic ld_op, ld_op_tl_r, ld_op_v_r;
  logic st_op, st_op_tl_r, st_op_v_r;
  logic tagst_op, tagst_op_tl_r, tagst_op_v_r;
  logic tagfl_op, tagfl_op_tl_r, tagfl_op_v_r;
  logic taglv_op, taglv_op_tl_r, taglv_op_v_r;
  logic tagla_op, tagla_op_tl_r, tagla_op_v_r;
  logic afl_op, afl_op_tl_r, afl_op_v_r;
  logic aflinv_op, aflinv_op_tl_r, aflinv_op_v_r;
  logic ainv_op, ainv_op_tl_r, ainv_op_v_r;

  logic miss_v_r;
  logic override;
  logic data_mem_free;
  logic tag_hit_0_tl, tag_hit_1_tl;
  logic tag_hit_0_v_r, tag_hit_1_v_r;
  logic final_recover;
  logic just_recovered_r;
  logic miss_tl;  

  logic tag_read_op_a;
  logic tag_read_op_tl_r;

  logic instr_cannot_miss_tl;
  logic instr_must_miss_tl;

  logic [7:0] data_mask_storebuf;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_addr_storebuf;
  logic [63:0] data_in_storebuf;
  
  logic [addr_width_p-1:0] addr_tl_r;
  logic [addr_width_p-1:0] addr_v_r;

  logic [31:0] data_i_tl_r;
  logic [31:0] data_i_v_r;

  logic [tag_width_lp+1:0] tag_check_me_tl;

  logic [lg_sets_lp-1:0] tag_addr;
  logic [lg_sets_lp-1:0] tag_addr_force;
  logic [lg_sets_lp-1:0] tag_addr_recover;
  logic [lg_sets_lp-1:0] tag_addr_force_or_recover;
  logic [lg_sets_lp-1:0] tag_addr_final;
  
  logic tag_we_force;
  logic tag_we_final;

  logic tag_mask_inval;
  logic tag_mask_force;
  logic tag_mask_force_or_inval;
  logic tag_mask_force_or_inval_n;
  
  logic [(tag_width_lp+1)*2-1:0] tag_mask_final;
  logic [(tag_width_lp+1)*2-1:0] tag_data_out_tl;
  logic [(tag_width_lp+1)*2-1:0] tag_data_out_v_r;
  logic [(tag_width_lp+1)*2-1:0] tag_data_in_inval;
  logic [(tag_width_lp+1)*2-1:0] tag_data_in_force;
  logic [(tag_width_lp+1)*2-1:0] tag_data_in_final;

  logic explicit_set_bit_a;
  logic explicit_set_bit_tl;
  logic explicit_set_bit_v;
  logic evict_and_fill_set;

  logic [tag_width_lp:0] tag_mask_foi_buf;
  logic [tag_width_lp:0] tag_mask_foi_n_buf; 

  logic ainv_or_aflinv_op_v;

  logic in_middle_of_miss;
  logic tag_re_final;
  logic tag_en;

  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_addr;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_addr_force;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_addr_recover;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_addr_force_or_recover;
    
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_addr_force_or_write;
  logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_addr_final;
  
  logic data_mem_en;
  logic data_we_storebuf;
  logic data_we_force;
  logic data_re_force;
  logic data_we_final;

  logic [7:0] data_mask_force;
  logic [7:0] data_mask_final;

  logic [63:0] data_in_force;
  logic [63:0] data_in_final;
  logic [63:0] raw_data_out;

  logic [31:0] data_out_0_tl, data_out_1_tl;
  logic [31:0] data_out_0_v_r, data_out_1_v_r;
  logic [31:0] data_out_0_vp, data_out_1_vp;
  logic [31:0] data_out_vp_set_picked;
  logic [31:0] data_out_vp_readjust;
 
  logic [tag_width_lp:0] tag_data_0_tl, tag_data_1_tl;
  logic [tag_width_lp:0] tag_data_explicit_tl;
  logic tag_data_explicit_valid_tl;
  logic [32-2-lg_block_size_in_words_lp-1:0] tag_data_explicit_addr_tl;
  logic [32-2-lg_block_size_in_words_lp-1:0] tag_data_explicit_addr_anded_tl;
  
  logic [31:0] taglalv_val_tl, taglalv_val_v_r;

  logic miss_sense_tl;
  
  logic [3:0] storebuf_hit_v;
  logic [31:0] storebuf_bypass_data_v;

  logic [31:0] storebuf_out_data;
  logic storebuf_out_set;
  logic [3:0] storebuf_out_mask;
  logic [31:0] storebuf_in_data;
  logic [3:0] storebuf_in_mask;
  logic storebuf_empty;

  logic [31:0] snoop_word;
 
  logic [15:0] data_out_vp_readj_lo, data_out_vp_readj_hi;
  logic [7:0] data_out_vp_readj_b0, data_out_vp_readj_b1,
    data_out_vp_readj_b2, data_out_vp_readj_b3;
  logic [15:0] data_out_vp_half;
  logic [7:0] data_out_vp_byte;
  
  logic data_out_vp_half_extend;
  logic data_out_vp_byte_extend;
  logic [31:0] data_out_vp_half_extended;
  logic [31:0] data_out_vp_byte_extended;
  logic [31:0] data_out_vp_readjust_masked;
  logic [31:0] data_out_vp_readjust_masked_or_not;

  logic [31:0] data_out_lalv_swlw_v;
  logic [31:0] data_out_half_or_byte;
  logic [31:0] data_final;

  logic mc_wipe_request_v;
  logic dirty0;
  logic dirty1;
  logic write_over_read_v;
  logic mru;

  logic dma_finished;

  logic mc_send_fill_req;
  logic mc_send_evict_req;
  logic mc_fill_line;
  logic mc_evict_line;
  logic [addr_width_p-1:0] mc_pass_addr;
   
  logic status_mem_re;
  logic v_v_we;

  logic instr_returns_val_v;

  // handshaking
  //
  assign ready_o = (v_tl_r & v_v_we)
    | (~v_tl_r & (v_v_we | (~tagst_op & miss_v_r)));

  assign v_o = v_v_r & (~miss_v_r);

  assign v_v_we = (~miss_v_r) & ((v_v_r & yumi_i) | (~v_v_r));

  // datapath
  //
  `declare_bsg_cache_pkt_s(addr_width_p, 32);
  bsg_cache_pkt_s packet;
  assign packet = packet_i;
  assign byte_op = (packet.opcode[2:0] == 3'b000);  
  assign half_op = (packet.opcode[2:0] == 3'b001);  
  assign word_op = (packet.opcode[2:0] == 3'b010);  
  assign mask_op = (packet.opcode[2:0] == 3'b100);

  assign ld_op = (packet.opcode[4:3] == 2'b00);
  assign st_op = (packet.opcode[4:3] == 2'b01);
  assign tagst_op = (packet.opcode == TAGST);
  assign tagfl_op = (packet.opcode == TAGFL);
  assign taglv_op = (packet.opcode == TAGLV);
  assign tagla_op = (packet.opcode == TAGLA);
  assign afl_op = (packet.opcode == AFL);
  assign aflinv_op = (packet.opcode == AFLINV);
  assign ainv_op = (packet.opcode == AINV);

  assign byte_mask = packet.mask;

  assign override = miss_v_r;
  assign data_mem_free = ~ld_op | miss_v_r;

  assign instr_cannot_miss_tl = tagst_op_tl_r | tagla_op_tl_r | taglv_op_tl_r;
  assign instr_must_miss_tl = tagfl_op_tl_r;

  assign instr_returns_val_v = ld_op_v_r | taglv_op_v_r | tagla_op_v_r;

  assign tag_check_me_tl = {instr_must_miss_tl, 1'b1,
    addr_tl_r[2+lg_block_size_in_words_lp+lg_sets_lp+:tag_width_lp]};
  assign explicit_set_bit_a = packet.addr[2+lg_block_size_in_words_lp+lg_sets_lp]; // 2+3+9=14
  assign explicit_set_bit_tl = addr_tl_r[2+lg_block_size_in_words_lp+lg_sets_lp];
  assign explicit_set_bit_v = addr_v_r[2+lg_block_size_in_words_lp+lg_sets_lp];

  assign tag_mask_inval = explicit_set_bit_a;
  assign tag_mask_force = evict_and_fill_set;
  assign tag_mask_force_or_inval = override ? tag_mask_force : tag_mask_inval;
  assign tag_mask_force_or_inval_n = ~tag_mask_force_or_inval;

  bsg_buf_ctrl #(.width_p(tag_width_lp+1)) tag_mask_buf (
    .i(tag_mask_force_or_inval)
    ,.o(tag_mask_foi_buf)
  );
  bsg_buf_ctrl #(.width_p(tag_width_lp+1)) tag_mask_buf_n (
    .i(tag_mask_force_or_inval_n)
    ,.o(tag_mask_foi_n_buf)
  );

  assign tag_mask_final = {tag_mask_foi_buf, tag_mask_foi_n_buf};

  assign tag_data_in_inval = {2{packet.data[31], packet.data[tag_width_lp-1:0]}};

  assign ainv_or_aflinv_op_v = ainv_op_v_r | aflinv_op_v_r;
  
  assign tag_data_in_force = {
    2{~ainv_or_aflinv_op_v, addr_v_r[lg_sets_lp+lg_block_size_in_words_lp+2+:tag_width_lp]}
  };

  assign tag_addr = packet.addr[lg_block_size_in_words_lp+2+:lg_sets_lp]; // 13:5
  assign tag_addr_force = addr_v_r[lg_block_size_in_words_lp+2+:lg_sets_lp];
  assign tag_addr_recover = addr_tl_r[lg_block_size_in_words_lp+2+:lg_sets_lp];

  assign tag_addr_force_or_recover = final_recover
    ? tag_addr_recover
    : tag_addr_force;

  assign tag_addr_final = override 
    ? tag_addr_force_or_recover
    : tag_addr;

  assign tag_data_in_final = override
    ? tag_data_in_force
    : tag_data_in_inval;

  assign tag_we_final = override ? tag_we_force : (tagst_op & v_i & ready_o);

  assign tag_read_op_a = ld_op | st_op | tagfl_op | taglv_op
    | tagla_op | afl_op | aflinv_op | ainv_op; 

  assign in_middle_of_miss = miss_v_r & ~final_recover;

  assign tag_re_final = (tag_read_op_a & ~in_middle_of_miss & v_i) 
    | (final_recover & tag_read_op_tl_r & v_tl_r);

  assign tag_en = (~reset_i) & (tag_re_final | tag_we_final);

  assign data_addr = packet.addr[2+:lg_sets_lp+lg_block_size_in_words_lp]; // 13:2
  assign data_addr_recover = addr_tl_r[2+:lg_sets_lp+lg_block_size_in_words_lp];

  assign data_we_final = (data_we_force | data_we_storebuf);

  assign data_mem_en = (~reset_i) & ((v_i & ld_op & ~miss_v_r)
    | (v_tl_r & final_recover & ld_op_tl_r)
    | data_re_force 
    | data_we_final);

  assign data_in_final = data_we_force 
    ? data_in_force     // dma
    : data_in_storebuf; // store_buffer

  assign data_in_storebuf = {2{storebuf_out_data}};

  assign data_addr_force_or_recover = final_recover
    ? data_addr_recover
    : data_addr_force;

  assign data_addr_force_or_write = data_we_storebuf
    ? data_addr_storebuf
    : data_addr_force_or_recover;

  assign data_addr_final = (override | data_we_storebuf) 
    ? data_addr_force_or_write
    : data_addr;

  assign data_mask_final = data_we_force
    ? data_mask_force
    : data_mask_storebuf;

  assign data_mask_storebuf = storebuf_out_set
    ? {storebuf_out_mask, 4'b0000}
    : {4'b0000, storebuf_out_mask};

  assign data_out_0_tl = raw_data_out[31:0];
  assign data_out_1_tl = raw_data_out[63:32];

  assign tag_data_0_tl = tag_data_out_tl[tag_width_lp:0];
  assign tag_data_1_tl = tag_data_out_tl[tag_width_lp+1+:tag_width_lp+1];

  assign tag_data_explicit_tl = explicit_set_bit_tl
    ? tag_data_1_tl
    : tag_data_0_tl;
 
  assign tag_data_explicit_valid_tl = tag_data_explicit_tl[tag_width_lp];
 
  assign tag_data_explicit_addr_tl = {
    tag_data_explicit_tl[tag_width_lp-1:0],
    addr_tl_r[lg_block_size_in_words_lp+2+:lg_sets_lp]
  };

  assign tag_data_explicit_addr_anded_tl = tag_data_explicit_addr_tl
    & {(tag_width_lp+lg_sets_lp){tagla_op_tl_r}};

  assign taglalv_val_tl = {tag_data_explicit_addr_anded_tl, 4'b0000,
    taglv_op_tl_r & tag_data_explicit_valid_tl}; 

  assign tag_hit_0_tl = (tag_check_me_tl == {1'b0, tag_data_0_tl});
  assign tag_hit_1_tl = (tag_check_me_tl == {1'b0, tag_data_1_tl});

  assign miss_sense_tl = ~(afl_op_tl_r | aflinv_op_tl_r | ainv_op_tl_r); 

  assign miss_tl = miss_sense_tl ^ (instr_cannot_miss_tl | tag_hit_0_tl | tag_hit_1_tl);

  assign storebuf_in_mask = mask_op_v_r
    ? byte_mask_v_r
    : (word_op_v_r 
        ? 4'b1111
        : (half_op_v_r
          ? {addr_v_r[1], addr_v_r[1], ~addr_v_r[1], ~addr_v_r[1]}
          : {(addr_v_r[1] & addr_v_r[0]),
            (addr_v_r[1] & ~addr_v_r[0]),
            (~addr_v_r[1] & addr_v_r[0]),
            (~addr_v_r[1] & ~addr_v_r[0])}));

  assign storebuf_in_data = (word_op_v_r | mask_op_v_r)
    ? data_i_v_r
    : (half_op_v_r
      ? {data_i_v_r[15:0], data_i_v_r[15:0]}
      : {data_i_v_r[7:0], data_i_v_r[7:0], data_i_v_r[7:0], data_i_v_r[7:0]});

  bsg_mux_segmented #(
    .segments_p(4)
    ,.segment_width_p(8) 
  ) MUX_storebuf_bypass0 (
    .data0_i(data_out_0_v_r)
    ,.data1_i(storebuf_bypass_data_v)
    ,.sel_i(storebuf_hit_v)
    ,.data_o(data_out_0_vp)
  );

  bsg_mux_segmented #(
    .segments_p(4)
    ,.segment_width_p(8) 
  ) MUX_storebuf_bypass1 (
    .data0_i(data_out_1_v_r)
    ,.data1_i(storebuf_bypass_data_v)
    ,.sel_i(storebuf_hit_v)
    ,.data_o(data_out_1_vp)
  );

  assign data_out_vp_set_picked = tag_hit_1_v_r
    ? data_out_1_vp
    : data_out_0_vp;

  assign data_out_vp_readjust = just_recovered_r
    ? snoop_word
    : data_out_vp_set_picked;
  
  bsg_mux_segmented #(
    .segments_p(4)
    ,.segment_width_p(8)
  ) MUX_segmented_vp_readjust_masked (
    .data0_i(32'b0)
    ,.data1_i(data_out_vp_readjust)
    ,.sel_i(byte_mask_v_r)
    ,.data_o(data_out_vp_readjust_masked)
  );

  bsg_mux #(.width_p(32), .els_p(2)) MUX_masked (
    .data_i({data_out_vp_readjust_masked, data_out_vp_readjust})
    ,.sel_i(mask_op_v_r)
    ,.data_o(data_out_vp_readjust_masked_or_not)
  );

  assign data_out_vp_readj_lo = data_out_vp_readjust[15:0];
  assign data_out_vp_readj_hi = data_out_vp_readjust[31:16];
  
  assign data_out_vp_readj_b0 = data_out_vp_readjust[7:0];
  assign data_out_vp_readj_b1 = data_out_vp_readjust[15:8];
  assign data_out_vp_readj_b2 = data_out_vp_readjust[23:16];
  assign data_out_vp_readj_b3 = data_out_vp_readjust[31:24];

  bsg_mux #(.width_p(16), .els_p(2)) MUX_half (
    .data_i({data_out_vp_readj_hi, data_out_vp_readj_lo})
    ,.sel_i(addr_v_r[1])
    ,.data_o(data_out_vp_half)
  );

  bsg_mux #(.width_p(8), .els_p(4)) MUX_byte (
    .data_i({data_out_vp_readj_b3, data_out_vp_readj_b2, data_out_vp_readj_b1, data_out_vp_readj_b0})
    ,.sel_i(addr_v_r[1:0])
    ,.data_o(data_out_vp_byte)
  );

  assign data_out_vp_half_extend = sigext_op_v_r & data_out_vp_half[15];
  assign data_out_vp_byte_extend = sigext_op_v_r & data_out_vp_byte[7];
  
  assign data_out_vp_half_extended = {{16{data_out_vp_half_extend}}, data_out_vp_half};
  assign data_out_vp_byte_extended = {{24{data_out_vp_byte_extend}}, data_out_vp_byte};

  bsg_mux #(.width_p(32), .els_p(2)) MUX_merge_taglalv (
    .data_i({taglalv_val_v_r, data_out_vp_readjust_masked_or_not})
    ,.sel_i(taglv_op_v_r | tagla_op_v_r)
    ,.data_o(data_out_lalv_swlw_v)
  );
 
  bsg_mux #(.width_p(32), .els_p(2)) MUX_half_or_byte_data_out (
    .data_i({data_out_vp_half_extended, data_out_vp_byte_extended})
    ,.sel_i(half_op_v_r)
    ,.data_o(data_out_half_or_byte)
  );

  bsg_mux #(.width_p(32), .els_p(2)) MUX_word_or_other_data_out (
    .data_i({data_out_lalv_swlw_v, data_out_half_or_byte})
    ,.sel_i(mask_op_v_r | word_op_v_r | taglv_op_v_r | tagla_op_v_r)
    ,.data_o(data_final)
  );

  assign data_o = data_final & {32{instr_returns_val_v}};


  // tag_mem
  //
  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p((tag_width_lp+1)*2)
    ,.els_p(sets_p)
  ) tag_mem (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.data_i(tag_data_in_final)
    ,.addr_i(tag_addr_final)
    ,.v_i(tag_en)
    ,.w_mask_i(tag_mask_final)
    ,.w_i(tag_we_final)
    ,.data_o(tag_data_out_tl)
  );  

  // data_mem
  //
  bsg_mem_1rw_sync_mask_write_byte #(
    .data_width_p(64)
    ,.els_p(block_size_in_words_p*sets_p)
  ) data_mem (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.data_i(data_in_final)
    ,.addr_i(data_addr_final)
    ,.v_i(data_mem_en)
    ,.write_mask_i(data_mask_final)
    ,.w_i(data_we_final)
    ,.data_o(raw_data_out)
  );

  // store_buffer
  //
  bsg_store_buffer #(
    .addr_width_p(addr_width_p)
    ,.lg_sets_lp(lg_sets_lp)
    ,.lg_block_size_in_words_lp(lg_block_size_in_words_lp)
  ) wb (
    .clock_i(clock_i)
    ,.reset_i(reset_i)
    ,.write_mask_v_i(storebuf_in_mask)
    ,.write_addr_v_i({addr_v_r[addr_width_p-1:2], 2'b00})
    ,.write_data_v_i(storebuf_in_data)
    ,.write_set_v_i(just_recovered_r ? evict_and_fill_set : tag_hit_1_v_r)
    ,.write_valid_v_i(~miss_v_r & st_op_v_r & v_v_r)
    ,.data_mem_free_i(data_mem_free)
    ,.v_v_we_i(v_v_we)
    ,.ld_op_tl_i(ld_op_tl_r)
    ,.read_addr_tl_i({addr_tl_r[addr_width_p-1:2], 2'b00})
    ,.is_read_tl_i(ld_op_tl_r & v_tl_r)
    ,.storebuf_bypass_data_o(storebuf_bypass_data_v)
    ,.storebuf_bypass_valid_o(storebuf_hit_v)
    ,.storebuf_mask_o(storebuf_out_mask)
    ,.storebuf_index_o(data_addr_storebuf)
    ,.storebuf_data_o(storebuf_out_data)
    ,.storebuf_set_o(storebuf_out_set)
    ,.storebuf_we_o(data_we_storebuf)
    ,.storebuf_empty_o(storebuf_empty)
  );

  // repl
  //
  bsg_repl #(
    .sets_p(sets_p)
    ,.lg_sets_lp(lg_sets_lp)
  ) repl (
    .clock_i(clock_i)
    ,.reset_i(reset_i)
    ,.index_v_i(addr_v_r[2+lg_block_size_in_words_lp+:lg_sets_lp])
    ,.index_tl_i(addr_tl_r[2+lg_block_size_in_words_lp+:lg_sets_lp])
    ,.miss_minus_recover_v_i(in_middle_of_miss)
    ,.tagged_access_v_i(addr_v_r[0] & word_op_v_r)
    ,.ld_st_set_v_i(just_recovered_r ? evict_and_fill_set : tag_hit_1_v_r)
    ,.wipe_set_v_i(tagst_op_v_r ? explicit_set_bit_v : evict_and_fill_set)
    ,.ld_op_v_i(~miss_v_r & ld_op_v_r)
    ,.st_op_v_i(~miss_v_r & st_op_v_r)
    ,.wipe_v_i(tagst_op_v_r | mc_wipe_request_v)
    ,.dirty0_o(dirty0)
    ,.dirty1_o(dirty1)
    ,.mru_o(mru)
    ,.write_over_read_v_o(write_over_read_v)
    ,.status_mem_re_i(status_mem_re)
  );


  // miss_case
  //
  bsg_miss_case #(
    .addr_width_p(addr_width_p)
    ,.tag_width_lp(tag_width_lp)
    ,.lg_sets_lp(lg_sets_lp)
    ,.lg_block_size_in_words_lp(lg_block_size_in_words_lp)
  ) mc (
    .clock_i(clock_i)
    ,.reset_i(reset_i)

    ,.v_v_r_i(v_v_r)
    ,.miss_v_i(miss_v_r)
    ,.ld_op_v_i(ld_op_v_r)
    ,.st_op_v_i(st_op_v_r)
    ,.tagfl_op_v_i(tagfl_op_v_r)
    ,.afl_op_v_i(afl_op_v_r)
    ,.aflinv_op_v_i(aflinv_op_v_r)
    ,.ainv_op_v_i(ainv_op_v_r)
    ,.addr_v_i(addr_v_r)

    ,.tag0_v_i(tag_data_out_v_r[tag_width_lp-1:0])
    ,.tag1_v_i(tag_data_out_v_r[tag_width_lp+1+:tag_width_lp]) // 36:19
    ,.valid0_v_i(tag_data_out_v_r[tag_width_lp])
    ,.valid1_v_i(tag_data_out_v_r[2*(tag_width_lp+1)-1])
    ,.tag_hit1_v_i(tag_hit_1_v_r)

    // from store_buffer
    ,.storebuf_empty_i(storebuf_empty)
    
    // to evict_fill_machine
    ,.mc_send_fill_req_o(mc_send_fill_req)
    ,.mc_send_evict_req_o(mc_send_evict_req)
    ,.mc_fill_line_o(mc_fill_line)
    ,.mc_evict_line_o(mc_evict_line)
    ,.mc_pass_addr_o(mc_pass_addr)

    // from evict_fill_machine
    ,.dma_finished_i(dma_finished)

    // to repl
    ,.wipe_v_o(mc_wipe_request_v)

    // from repl
    ,.query_dirty0_i(dirty0)
    ,.query_dirty1_i(dirty1)
    ,.query_mru_i(mru)

    ,.final_recover_o(final_recover)
    ,.tag_we_force_o(tag_we_force)
    ,.chosen_set_o(evict_and_fill_set)
    ,.status_mem_re_o(status_mem_re)
  );

  // evict_fill_machine
  //
  bsg_evict_fill_machine #(
    .lg_sets_lp(lg_sets_lp)
    ,.block_size_in_words_p(block_size_in_words_p)
  ) de (

    .clock_i(clock_i)
    ,.reset_i(reset_i)

    // from miss_case
    ,.mc_send_fill_req_i(mc_send_fill_req)
    ,.mc_send_evict_req_i(mc_send_evict_req)
    ,.mc_fill_line_i(mc_fill_line)
    ,.mc_evict_line_i(mc_evict_line)
    ,.mc_pass_addr_i(mc_pass_addr)
    ,.start_set_i(evict_and_fill_set)

    ,.start_addr_i(addr_v_r[2+lg_block_size_in_words_lp+:lg_sets_lp]) // 13:5
    ,.snoop_word_offset_i(addr_v_r[2+:lg_block_size_in_words_lp]) // 4:2
    ,.snoop_word_o(snoop_word)

    // dma req channel
    ,.dma_req_ch_write_not_read_o(dma_req_ch_write_not_read_o)
    ,.dma_req_ch_addr_o(dma_req_ch_addr_o)
    ,.dma_req_ch_v_o(dma_req_ch_v_o)
    ,.dma_req_ch_yumi_i(dma_req_ch_yumi_i)
    
    // dma read channel
    ,.dma_read_ch_data_i(dma_read_ch_data_i)
    ,.dma_read_ch_v_i(dma_read_ch_v_i)
    ,.dma_read_ch_ready_o(dma_read_ch_ready_o)
  
    // dma write channel
    ,.dma_write_ch_data_o(dma_write_ch_data_o)
    ,.dma_write_ch_yumi_i(dma_write_ch_yumi_i)
    ,.dma_write_ch_v_o(dma_write_ch_v_o)

    ,.data_re_force_o(data_re_force)
    ,.data_we_force_o(data_we_force)
    ,.data_mask_force_o(data_mask_force)
    ,.data_addr_force_o(data_addr_force)
    ,.data_in_force_o(data_in_force)
    ,.raw_data_i(raw_data_out)
    ,.finished_o(dma_finished)
  );




  // sequential 
  //
  always_ff @ (posedge clock_i) begin
    
    if (reset_i) begin
      miss_v_r <= 1'b0;
      v_tl_r <= 1'b0;
      v_v_r <= 1'b0;
    end
    else begin
      miss_v_r <= miss_v_r
        ? ~final_recover
        : (v_tl_r ? miss_tl : 1'b0);

    end
  
    if (reset_i) begin
      ld_op_tl_r <= 1'b0;
      ld_op_v_r <= 1'b0;
      st_op_tl_r <= 1'b0;
      st_op_v_r <= 1'b0;
      tagst_op_tl_r <= 1'b0;
      tagst_op_v_r <= 1'b0;
      tagfl_op_tl_r <= 1'b0;
      tagfl_op_v_r <= 1'b0;
      taglv_op_tl_r <= 1'b0;
      taglv_op_v_r <= 1'b0;
      tagla_op_tl_r <= 1'b0;
      tagla_op_v_r <= 1'b0;
      afl_op_tl_r <= 1'b0;
      afl_op_v_r <= 1'b0;
      aflinv_op_tl_r <= 1'b0;
      aflinv_op_v_r <= 1'b0;
      ainv_op_tl_r <= 1'b0;
      ainv_op_v_r <= 1'b0;
      word_op_tl_r <= 1'b0;
      word_op_v_r <= 1'b0;
      half_op_tl_r <= 1'b0;
      half_op_v_r <= 1'b0;
      byte_op_tl_r <= 1'b0;
      byte_op_v_r <= 1'b0;
      sigext_op_tl_r <= 1'b0;
      sigext_op_v_r <= 1'b0;
      mask_op_tl_r <= 1'b0;
      mask_op_v_r <= 1'b0;
      byte_mask_tl_r <= 4'b0;
      byte_mask_v_r <= 4'b0;
      just_recovered_r <= 1'b0;
      tag_read_op_tl_r <= 1'b0;
    end
    else begin

      just_recovered_r <= just_recovered_r
        ? ~(v_o & yumi_i)
        : final_recover;

      // tl <= i
      if (ready_o) begin
        v_tl_r <= v_i;
        if (v_i) begin
          ld_op_tl_r <= ld_op;
          st_op_tl_r <= st_op;
          tagst_op_tl_r <= tagst_op;
          tagfl_op_tl_r <= tagfl_op;
          taglv_op_tl_r <= taglv_op;
          tagla_op_tl_r <= tagla_op;
          afl_op_tl_r <= afl_op;
          aflinv_op_tl_r <= aflinv_op;
          ainv_op_tl_r <= ainv_op;
          word_op_tl_r <= word_op;
          half_op_tl_r <= half_op;
          byte_op_tl_r <= byte_op;
          mask_op_tl_r <= mask_op;
          byte_mask_tl_r <= byte_mask;
          sigext_op_tl_r <= packet.sigext;
          tag_read_op_tl_r <= tag_read_op_a;
          addr_tl_r <= packet.addr;
          data_i_tl_r <= packet.data;
        end
      end 

      // v <= tl
      if (v_v_we) begin
        v_v_r <= v_tl_r;
        if (v_tl_r) begin
          tag_hit_0_v_r <= tag_hit_0_tl;
          tag_hit_1_v_r <= tag_hit_1_tl;
          ld_op_v_r <= ld_op_tl_r;
          st_op_v_r <= st_op_tl_r;
          tagst_op_v_r <= tagst_op_tl_r;
          tagfl_op_v_r <= tagfl_op_tl_r;
          taglv_op_v_r <= taglv_op_tl_r;
          tagla_op_v_r <= tagla_op_tl_r;
          afl_op_v_r <= afl_op_tl_r;
          aflinv_op_v_r <= aflinv_op_tl_r;
          ainv_op_v_r <= ainv_op_tl_r;
          word_op_v_r <= word_op_tl_r;
          half_op_v_r <= half_op_tl_r;
          byte_op_v_r <= byte_op_tl_r;
          mask_op_v_r <= mask_op_tl_r;
          byte_mask_v_r <= byte_mask_tl_r;
          sigext_op_v_r <= sigext_op_tl_r;
          addr_v_r <= addr_tl_r;
          data_i_v_r <= data_i_tl_r;
          tag_data_out_v_r <= tag_data_out_tl;
          data_out_0_v_r <= data_out_0_tl;
          data_out_1_v_r <= data_out_1_tl;
          taglalv_val_v_r <= taglalv_val_tl;
        end
      end
    end
  end 

endmodule
