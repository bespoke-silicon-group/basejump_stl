/**
 *  bsg_data_cache.v
 *
 *  @author mbt
 *  @modified tommy
 */

// size_op_i
// ---------
// 2'b0 = byte
// 2'b1 = half
// 2'b2 = word

// instr_op_i
// ---------------
// 0000 = LD (load)
// 0001 = ST (store)
// 0010 = TAGST (tag store)
// 0011 = TAGFL (tag flush)
// 0100 = TAGLV (tag load valid)
// 0101 = TAGLA (tag load addr)
// 0110 = AFL (address flush)
// 0111 = AFLINV (address flush & invalidate)
// 1000 = AINV (address invalidate)


module bsg_data_cache (
  input clk_i
  ,input rst_i

  ,input sigext_op_i
  ,input [1:0] size_op_i
  ,input [3:0] instr_op_i
  ,input [31:0] addr_i
  ,input [31:0] data_i
  ,input v_i
  ,output logic ready_o

  ,output logic [31:0] data_o
  ,output logic v_o
  ,input yumi_i

  ,input [31:0] cmni_data_i
  ,input cmni_valid_i
  ,output logic cmni_thanks_o

  ,output logic cmno_send_req_o
  ,input cmno_send_committed_i
  ,output logic [31:0] cmno_data_o
);

  // logic declaration
  logic v_tl_r, v_v_r;
  logic sigext_op_tl_r, sigext_op_v_r;
  logic word_op, word_op_tl_r, word_op_v_r;
  logic half_op, half_op_tl_r, half_op_v_r;
  logic byte_op, byte_op_tl_r, byte_op_v_r;
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
  logic store_slot_avail_a;
  logic tag_hit_0_tl, tag_hit_1_tl;
  logic tag_hit_0_v_r, tag_hit_1_v_r;
  logic final_recover;
  logic just_recovered_r;
  logic miss_tl;  

  logic instr_reads_tags_a;
  logic instr_reads_tags_tl_r;

  logic instr_cannot_miss_tl;
  logic instr_must_miss_tl;

  logic [7:0] data_mask_storebuf;
  logic [11:0] data_addr_storebuf;
  logic [63:0] data_in_storebuf;
  
  logic [31:0] addr_tl_r;
  logic [31:0] addr_v_r;

  logic [31:0] data_i_tl_r;
  logic [31:0] data_i_v_r;

  logic [19:0] tag_check_me_tl;

  logic [8:0] tag_addr;
  logic [8:0] tag_addr_force;
  logic [8:0] tag_addr_recover;
  logic [8:0] tag_addr_force_or_recover;
  logic [8:0] tag_addr_final;
  
  logic tag_we_force;
  logic tag_we_final;

  logic tag_mask_inval;
  logic tag_mask_force;
  logic tag_mask_force_or_inval;
  logic tag_mask_force_or_inval_n;
  
  logic [37:0] tag_mask_final;
  logic [37:0] tag_data_out_tl;
  logic [37:0] tag_data_out_v_r;
  logic [37:0] tag_data_in_inval;
  logic [37:0] tag_data_in_force;
  logic [37:0] tag_data_in_final;

  logic explicit_set_bit_a;
  logic explicit_set_bit_tl;
  logic explicit_set_bit_v;
  logic evict_and_fill_set;

  logic [18:0] tag_mask_foi_buf;
  logic [18:0] tag_mask_foi_n_buf; 

  logic ainv_or_aflinv_op_v;

  logic in_middle_of_miss;
  logic tag_re_final;
  logic tag_en;

  logic [11:0] data_addr;
  logic [11:0] data_addr_force;
  logic [11:0] data_addr_recover;
  logic [11:0] data_addr_force_or_recover;
    
  logic [11:0] data_addr_force_or_write;
  logic [11:0] data_addr_final;
  
  logic data_mem_en;
  logic data_we_storebuf;
  logic data_we_force;
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
 
  logic [18:0] tag_data_0_tl, tag_data_1_tl;
  logic [18:0] tag_data_0_v, tag_data_1_v;
  logic [18:0] tag_data_explicit_tl;
  logic tag_data_explicit_valid_tl;
  logic [26:0] tag_data_explicit_addr_tl;
  logic [26:0] tag_data_explicit_addr_anded_tl;
  
  logic [31:0] taglalv_val_tl, taglalv_val_v_r;

  logic miss_sense_tl;
  
  logic [31:0] mdn_evict_header_v;
  logic [31:0] mdn_fill_header_v;
 
  logic [3:0] storebuf_hit_v;
  logic [31:0] storebuf_bypass_data_v;

  logic [31:0] writebuf_out_data;
  logic writebuf_out_set;
  logic [3:0] writebuf_out_mask;
  logic [31:0] writebuf_in_data;
  logic [3:0] writebuf_in_mask;
  logic writebuf_empty;

  logic [31:0] snooped_data;
 
  logic [15:0] data_out_vp_readj_lo, data_out_vp_readj_hi;
  logic [7:0] data_out_vp_readj_b0, data_out_vp_readj_b1,
    data_out_vp_readj_b2, data_out_vp_readj_b3;
  logic [15:0] data_out_vp_half;
  logic [7:0] data_out_vp_byte;
  
  logic data_out_vp_half_extend;
  logic data_out_vp_byte_extend;
  logic [31:0] data_out_vp_half_extended;
  logic [31:0] data_out_vp_byte_extended;

  logic [31:0] data_out_lalv_swlw_v;
  logic [31:0] data_out_half_or_byte;

  logic miss_case_wipe_request_v;
  logic dirty0;
  logic dirty1;
  logic write_over_read_v;
  logic mru;

  logic [31:0] pass_data;
  logic dma_finished;
  logic mem_to_network_req;
  logic network_to_mem_req;
  logic pass_to_network_req;

  logic mc_reading_dmem_for_dma;
  logic instr_returns_val_v;

  logic status_mem_re;
  logic v_v_we;


  // handshaking
  //
  assign ready_o = (v_tl_r & v_v_we)
    | (~v_tl_r & (v_v_we | (~tagst_op & miss_v_r)));

  assign v_o = (instr_returns_val_v & v_v_r & ~miss_v_r);


  // datapath
  //
  assign byte_op = (size_op_i == 2'b00);  
  assign half_op = (size_op_i == 2'b01);  
  assign word_op = (size_op_i == 2'b10);  

  assign ld_op = (instr_op_i == 4'b0000);
  assign st_op = (instr_op_i == 4'b0001);
  assign tagst_op = (instr_op_i == 4'b0010);
  assign tagfl_op = (instr_op_i == 4'b0011);
  assign taglv_op = (instr_op_i == 4'b0100);
  assign tagla_op = (instr_op_i == 4'b0101);
  assign afl_op = (instr_op_i == 4'b0110);
  assign aflinv_op = (instr_op_i == 4'b0111);
  assign ainv_op = (instr_op_i == 4'b1000);

  assign override = miss_v_r;
  assign store_slot_avail_a = ~ld_op | miss_v_r;

  assign instr_returns_val_v = (ld_op_v_r | taglv_op_v_r | tagla_op_v_r);
  assign instr_cannot_miss_tl = tagst_op_tl_r | tagla_op_tl_r | taglv_op_tl_r;
  assign instr_must_miss_tl = tagfl_op_tl_r;

  assign tag_check_me_tl = {instr_must_miss_tl, 1'b1, addr_tl_r[31:14]};
  assign explicit_set_bit_a = addr_i[14];
  assign explicit_set_bit_tl = addr_tl_r[14];
  assign explicit_set_bit_v = addr_v_r[14];

  assign tag_mask_inval = explicit_set_bit_a;
  assign tag_mask_force = evict_and_fill_set;
  assign tag_mask_force_or_inval = override ? tag_mask_force : tag_mask_inval;
  assign tag_mask_force_or_inval_n = ~tag_mask_force_or_inval;

  bsg_buf_ctrl #(.width_p(19)) tag_mask_buf (.i(tag_mask_force_or_inval), .o(tag_mask_foi_buf));
  bsg_buf_ctrl #(.width_p(19)) tag_mask_buf_n (.i(tag_mask_force_or_inval_n), .o(tag_mask_foi_n_buf));

  assign tag_mask_final = {tag_mask_foi_buf, tag_mask_foi_n_buf};

  assign tag_data_in_inval = {2{data_i[31], data_i[17:0]}};

  assign ainv_or_aflinv_op_v = ainv_op_v_r | aflinv_op_v_r;
  
  assign tag_data_in_force = {2{~ainv_or_aflinv_op_v, addr_v_r[31:14]}};

  assign tag_addr = addr_i[13:5];
  assign tag_addr_force = addr_v_r[13:5];
  assign tag_addr_recover = addr_tl_r[13:5];

  assign tag_addr_force_or_recover = final_recover
    ? tag_addr_recover
    : tag_addr_force;

  assign tag_addr_final = override 
    ? tag_addr_force_or_recover
    : tag_addr;

  assign tag_data_in_final = override
    ? tag_data_in_force
    : tag_data_in_inval;

  assign tag_we_final = override ? tag_we_force : (tagst_op & v_i);

  assign instr_reads_tags_a = ld_op | st_op | tagfl_op | taglv_op
    | tagla_op | afl_op | aflinv_op | ainv_op; 

  assign in_middle_of_miss = miss_v_r & ~final_recover;

  assign tag_re_final = (instr_reads_tags_a & ~in_middle_of_miss & v_i) 
    | (final_recover & instr_reads_tags_tl_r & v_tl_r);

  assign tag_en = (~rst_i) & (tag_re_final | tag_we_final);

  assign data_addr = addr_i[13:2];
  assign data_addr_recover = addr_tl_r[13:2];

  assign data_we_final = (data_we_force | data_we_storebuf);

  assign data_mem_en = (~rst_i) & ((v_i & ld_op & ~miss_v_r)
    | (v_tl_r & final_recover & ld_op_tl_r)
    | mc_reading_dmem_for_dma
    | data_we_final);

  assign data_in_final = data_we_force 
    ? data_in_force     // dma
    : data_in_storebuf; // write_buffer

  assign data_in_storebuf = {2{writebuf_out_data}};

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

  assign data_mask_storebuf = writebuf_out_set
    ? {writebuf_out_mask, 4'b0000}
    : {4'b0000, writebuf_out_mask};

  assign data_out_0_tl = raw_data_out[31:0];
  assign data_out_1_tl = raw_data_out[63:32];

  assign tag_data_0_tl = tag_data_out_tl[18:0];
  assign tag_data_1_tl = tag_data_out_tl[37:19];

  assign tag_data_0_v = tag_data_out_v_r[18:0];
  assign tag_data_1_v = tag_data_out_v_r[37:19];

  assign tag_data_explicit_tl = explicit_set_bit_tl
    ? tag_data_1_tl
    : tag_data_0_tl;
 
  assign tag_data_explicit_valid_tl = tag_data_explicit_tl[18];
 
  assign tag_data_explicit_addr_tl = {tag_data_explicit_tl[17:0], addr_tl_r[13:5]};

  assign tag_data_explicit_addr_anded_tl = tag_data_explicit_addr_tl & {27{tagla_op_tl_r}};

  assign taglalv_val_tl = {tag_data_explicit_addr_anded_tl, 4'b0000,
    taglv_op_tl_r & tag_data_explicit_valid_tl}; 

  assign tag_hit_0_tl = (tag_check_me_tl == {1'b0, tag_data_0_tl});
  assign tag_hit_1_tl = (tag_check_me_tl == {1'b0, tag_data_1_tl});

  assign miss_sense_tl = ~(afl_op_tl_r | aflinv_op_tl_r | ainv_op_tl_r); 

  assign miss_tl = miss_sense_tl ^ (instr_cannot_miss_tl | tag_hit_0_tl | tag_hit_1_tl);

  assign mdn_evict_header_v = {16'b0, 3'b0, 5'd9, 4'b0100, 4'b0};
  assign mdn_fill_header_v = {16'b0, 3'b0, 5'd1, 4'b0000, 4'b0};
  
  assign writebuf_in_mask = word_op_v_r
    ? 4'b1111
    : (half_op_v_r
      ? {addr_v_r[1], addr_v_r[1], ~addr_v_r[1], ~addr_v_r[1]}
      : {(addr_v_r[1] & addr_v_r[0]),
         (addr_v_r[1] & ~addr_v_r[0]),
         (~addr_v_r[1] & addr_v_r[0]),
         (~addr_v_r[1] & ~addr_v_r[0])});

  assign writebuf_in_data = word_op_v_r
    ? data_i_v_r
    : (half_op_v_r
      ? {data_i_v_r[15:0], data_i_v_r[15:0]}
      : {data_i_v_r[7:0], data_i_v_r[7:0], data_i_v_r[7:0], data_i_v_r[7:0]});

  bsg_mux_4way MUX_storebuf_bypass0 (
    .el0_i(data_out_0_v_r)
    ,.el1_i(storebuf_bypass_data_v)
    ,.sel_i(storebuf_hit_v)
    ,.o(data_out_0_vp)
  );

  bsg_mux_4way MUX_storebuf_bypass1 (
    .el0_i(data_out_1_v_r)
    ,.el1_i(storebuf_bypass_data_v)
    ,.sel_i(storebuf_hit_v)
    ,.o(data_out_1_vp)
  );

  assign data_out_vp_set_picked = tag_hit_1_v_r
    ? data_out_1_vp
    : data_out_0_vp;

  assign data_out_vp_readjust = just_recovered_r
    ? snooped_data
    : data_out_vp_set_picked;

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

  assign data_out_vp_half_extend = sigext_op_v_r & data_out_vp_half[15];

  bsg_mux #(.width_p(8), .els_p(4)) MUX_byte (
    .data_i({data_out_vp_readj_b3, data_out_vp_readj_b2, data_out_vp_readj_b1, data_out_vp_readj_b0})
    ,.sel_i(addr_v_r[1:0])
    ,.data_o(data_out_vp_byte)
  );

  assign data_out_vp_byte_extend = sigext_op_v_r & data_out_vp_byte[7];
  
  assign data_out_vp_half_extended = {{16{data_out_vp_half_extend}}, data_out_vp_half};
  assign data_out_vp_byte_extended = {{24{data_out_vp_byte_extend}}, data_out_vp_byte};

  bsg_mux #(.width_p(32), .els_p(2)) MUX_merge_taglalv (
    .data_i({taglalv_val_v_r, data_out_vp_readjust})
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
    ,.sel_i(word_op_v_r | taglv_op_v_r | tagla_op_v_r)
    ,.data_o(data_o)
  );

  assign v_v_we = (~miss_v_r)
    & ((~v_v_r)
      | (v_v_r & instr_returns_val_v & yumi_i)
      | (v_v_r & ~instr_returns_val_v));


  // tag_mem
  //
  bsg_mem_1rw_sync_mask_write_bit #(
    .width_p(38)
    ,.els_p(2**9)
  ) tag_mem (
    .clk_i(clk_i)
    ,.reset_i(rst_i)
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
    ,.els_p(2**12)
  ) data_mem (
    .clk_i(clk_i)
    ,.reset_i(rst_i)
    ,.data_i(data_in_final)
    ,.addr_i(data_addr_final)
    ,.v_i(data_mem_en)
    ,.write_mask_i(data_mask_final)
    ,.w_i(data_we_final)
    ,.data_o(raw_data_out)
  );

  // write_buffer
  //
  bsg_write_buffer wb (
    .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.write_mask_v_i(writebuf_in_mask)
    ,.write_index_v_i(addr_v_r[13:2])
    ,.write_addr_v_i({addr_v_r[31:2], 2'b00})
    ,.write_data_v_i(writebuf_in_data)
    ,.write_set_v_i(just_recovered_r ? evict_and_fill_set : tag_hit_1_v_r)
    ,.write_valid_v_i(~miss_v_r & st_op_v_r & v_v_r)
    ,.data_mem_free_i(store_slot_avail_a)
    ,.read_addr_tl_i({addr_tl_r[31:2], 2'b00})
    ,.is_read_tl_i(ld_op_tl_r & v_tl_r)
    ,.writebuf_bypass_data_o(storebuf_bypass_data_v)
    ,.writebuf_bypass_valid_o(storebuf_hit_v)
    ,.writebuf_mask_o(writebuf_out_mask)
    ,.writebuf_index_o(data_addr_storebuf)
    ,.writebuf_data_o(writebuf_out_data)
    ,.writebuf_set_o(writebuf_out_set)
    ,.writebuf_we_o(data_we_storebuf)
    ,.writebuf_empty_o(writebuf_empty)
  );

  // replacement
  //
  bsg_replacement repl (
    .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.line_v_i(addr_v_r[13:5])
    ,.line_tl_i(addr_tl_r[13:5])
    ,.miss_minus_recover_v_i(in_middle_of_miss)
    ,.tagged_access_v_i(addr_v_r[0] & word_op_v_r)
    ,.ld_st_set_v_i(just_recovered_r ? evict_and_fill_set : tag_hit_1_v_r)
    ,.wipe_set_v_i(tagst_op_v_r ? explicit_set_bit_v : evict_and_fill_set)
    ,.ld_op_v_i(~miss_v_r & ld_op_v_r)
    ,.st_op_v_i(~miss_v_r & st_op_v_r)
    ,.wipe_v_i(tagst_op_v_r | miss_case_wipe_request_v)
    ,.dirty0_o(dirty0)
    ,.dirty1_o(dirty1)
    ,.mru_o(mru)
    ,.write_over_read_v_o(write_over_read_v)
    ,.status_mem_re_i(status_mem_re)
  );

  // miss_case
  //
  bsg_miss_case mc (
    .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.v_v_r_i(v_v_r)
    ,.miss_v_i(miss_v_r)
    ,.ld_op_v_i(ld_op_v_r)
    ,.st_op_v_i(st_op_v_r)
    ,.tagfl_op_v_i(tagfl_op_v_r)
    ,.afl_op_v_i(afl_op_v_r)
    ,.aflinv_op_v_i(aflinv_op_v_r)
    ,.ainv_op_v_i(ainv_op_v_r)
    ,.miss_addr_v_i(addr_v_r)
    ,.tag_data0_v_i(tag_data_0_v)
    ,.tag_data1_v_i(tag_data_1_v)
    ,.tag_hit1_v_i(tag_hit_1_v_r)
    ,.writebuf_empty_i(writebuf_empty)
    ,.mdn_fill_header_v_i(mdn_fill_header_v)
    ,.mdn_evict_header_v_i(mdn_evict_header_v)
    ,.mem_to_network_req_o(mem_to_network_req)
    ,.network_to_mem_req_o(network_to_mem_req)
    ,.pass_to_network_req_o(pass_to_network_req)
    ,.pass_data_o(pass_data)
    ,.dma_finished_i(dma_finished)
    ,.wipe_v_o(miss_case_wipe_request_v)
    ,.query_dirty0_i(dirty0)
    ,.query_dirty1_i(dirty1)
    ,.query_mru_i(mru)
    ,.final_recover_o(final_recover)
    ,.tag_we_force_o(tag_we_force)
    ,.chosen_set_o(evict_and_fill_set)
    ,.mc_reading_dmem_o(mc_reading_dmem_for_dma)
    ,.status_mem_re_o(status_mem_re)
  );

  // dma_engine
  //
  bsg_dma_engine de (
    .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.mem_to_network_req_i(mem_to_network_req)
    ,.network_to_mem_req_i(network_to_mem_req)
    ,.pass_to_network_req_i(pass_to_network_req)
    ,.start_addr_i(addr_v_r[13:5])
    ,.start_set_i(evict_and_fill_set)
    ,.snoop_word_i(addr_v_r[4:2])
    ,.snoop_data_o(snooped_data)
    ,.pass_data_i(pass_data)
    ,.cmni_data_i(cmni_data_i)
    ,.cmni_valid_i(cmni_valid_i)
    ,.cmni_thanks_o(cmni_thanks_o)
    ,.cmno_send_req_o(cmno_send_req_o)
    ,.cmno_send_committed_i(cmno_send_committed_i)
    ,.cmno_data_o(cmno_data_o)
    ,.data_we_force_o(data_we_force)
    ,.data_mask_force_o(data_mask_force)
    ,.data_addr_force_o(data_addr_force)
    ,.data_in_force_o(data_in_force)
    ,.raw_data_i(raw_data_out)
    ,.finished_o(dma_finished)
  );




  // sequential 
  //
  always_ff @ (posedge clk_i) begin
    
    if (rst_i) begin
      miss_v_r <= 1'b0;
      v_tl_r <= 1'b0;
      v_v_r <= 1'b0;
    end
    else begin
      miss_v_r <= miss_v_r
        ? ~final_recover
        : (v_tl_r ? miss_tl : 1'b0);

      if (ready_o) begin
        v_tl_r <= v_i;
      end   

      if (v_v_we) begin
        v_v_r <= v_tl_r;
      end
    end
  
    if (rst_i) begin
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
      just_recovered_r <= 1'b0;
      instr_reads_tags_tl_r <= 1'b0;
    end
    else begin

      just_recovered_r <= final_recover;

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
          sigext_op_tl_r <= sigext_op_i;
          instr_reads_tags_tl_r <= instr_reads_tags_a;
          addr_tl_r <= addr_i;
          data_i_tl_r <= data_i;
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
