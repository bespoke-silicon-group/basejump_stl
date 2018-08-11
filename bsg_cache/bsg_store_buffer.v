/**
 *  bsg_store_buffer.v
 */

module bsg_store_buffer
  #(parameter addr_width_p="inv"
   ,parameter lg_sets_lp="inv"
   ,parameter lg_block_size_in_words_lp="inv")
(
  input clock_i
  ,input reset_i

  ,input [3:0] write_mask_v_i
  ,input [addr_width_p-1:0] write_addr_v_i
  ,input [31:0] write_data_v_i 
  ,input write_set_v_i
  ,input write_valid_v_i

  ,input data_mem_free_i

  ,input v_v_we_i
  ,input ld_op_tl_i
  ,input [addr_width_p-1:0] read_addr_tl_i
  ,input is_read_tl_i

  ,output logic [31:0] storebuf_bypass_data_o
  ,output logic [3:0] storebuf_bypass_valid_o

  ,output logic [3:0] storebuf_mask_o
  ,output logic [11:0] storebuf_index_o
  ,output logic [31:0] storebuf_data_o
  ,output logic storebuf_set_o
  ,output logic storebuf_we_o
  ,output logic storebuf_empty_o
);

  logic [addr_width_p-1:0] el0_addr, el1_addr;
  logic [addr_width_p-1:0] el0_data, el1_data;
  logic [3:0] el0_mask, el1_mask;
  logic [1:0] num_els_r, num_els_n;
  logic [addr_width_p-1:0] storebuf_addr;

  logic el0_valid, el1_valid;
  logic mux1_sel, mux0_sel;
  logic storebuf_we_local;

  assign storebuf_we_o = storebuf_we_local;
  assign storebuf_index_o = storebuf_addr[2+:lg_sets_lp+lg_block_size_in_words_lp]; // 13:2
  
  assign el0_valid = (num_els_r == 2);
  assign el1_valid = (num_els_r >= 1);

  assign storebuf_empty_o = (num_els_r == 0);

  assign storebuf_we_local = (num_els_r != 0 | write_valid_v_i) & data_mem_free_i;

  assign mux0_sel = el0_valid;
  assign mux1_sel = el1_valid;

  logic el0_enable, el1_enable;
  assign el1_enable = storebuf_we_local | ~el1_valid;
  assign el0_enable = storebuf_we_local | ~el0_valid;

  always_ff @ (posedge clock_i) begin
    num_els_r <= reset_i ? 0 : num_els_r + write_valid_v_i - storebuf_we_local;
  end

  bsg_store_buffer_queue #(.width_p(4)) wbq_mask (
    .clock_i(clock_i)
    ,.data_i(write_mask_v_i)
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o(el0_mask)
    ,.el1_snoop_o(el1_mask)
    ,.final_o(storebuf_mask_o)
  );

  bsg_store_buffer_queue #(.width_p(32)) wbq_data (
    .clock_i(clock_i)
    ,.data_i(write_data_v_i)
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o(el0_data)
    ,.el1_snoop_o(el1_data)
    ,.final_o(storebuf_data_o)
  );

  bsg_store_buffer_queue #(.width_p(addr_width_p)) wbq_addr (
    .clock_i(clock_i)
    ,.data_i(write_addr_v_i)
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o(el0_addr)
    ,.el1_snoop_o(el1_addr)
    ,.final_o(storebuf_addr)
  );

  bsg_store_buffer_queue #(.width_p(1)) wbq_set (
    .clock_i(clock_i)
    ,.data_i(write_set_v_i)
    ,.el0_en_i(el0_enable)
    ,.el1_en_i(el1_enable)
    ,.mux0_sel_i(mux0_sel)
    ,.mux1_sel_i(mux1_sel)
    ,.el0_snoop_o()
    ,.el1_snoop_o()
    ,.final_o(storebuf_set_o)
  );

  logic tag_hit0, tag_hit0_n;
  logic tag_hit1, tag_hit1_n;
  logic tag_hit2, tag_hit2_n;
 
  assign tag_hit0_n = (read_addr_tl_i == el0_addr); 
  assign tag_hit1_n = (read_addr_tl_i == el1_addr); 
  assign tag_hit2_n = (read_addr_tl_i == write_addr_v_i); 

  assign tag_hit0 = tag_hit0_n & el0_valid;
  assign tag_hit1 = tag_hit1_n & el1_valid;
  assign tag_hit2 = tag_hit2_n & write_valid_v_i;

  logic [3:0] tag_hit0x4;
  logic [3:0] tag_hit1x4;
  logic [3:0] tag_hit2x4;
  
  assign tag_hit0x4 = {4{tag_hit0}};
  assign tag_hit1x4 = {4{tag_hit1}};
  assign tag_hit2x4 = {4{tag_hit2}};
   
  logic [31:0] el0or1_data;
  logic [31:0] storebuf_bypass_data_n;
  logic [3:0] storebuf_bypass_valid_n;

  assign storebuf_bypass_valid_n = {4{is_read_tl_i}}
    & ((tag_hit0x4 & el0_mask)
      |(tag_hit1x4 & el1_mask)
      |(tag_hit2x4 & write_mask_v_i));

  bsg_mux_segmented #(
    .segments_p(4)
    ,.segment_width_p(8) 
  ) SIMD_MUX_storebuf_merge0 (
    .data0_i(el1_data)
    ,.data1_i(el0_data)
    ,.sel_i(tag_hit0x4 & el0_mask)
    ,.data_o(el0or1_data)
  );

  bsg_mux_segmented #(
    .segments_p(4)
    ,.segment_width_p(8) 
  ) SIMD_MUX_storebuf_merge1 (
    .data0_i(el0or1_data)
    ,.data1_i(write_data_v_i)
    ,.sel_i(tag_hit2x4 & write_mask_v_i)
    ,.data_o(storebuf_bypass_data_n)
  );

  logic bypass_en;
  assign bypass_en = v_v_we_i & ld_op_tl_i;
  bsg_dff_en #(.width_p(32)) REG_storebuf_bypass_data (
    .clock_i(clock_i)
    ,.en_i(bypass_en)
    ,.data_i(storebuf_bypass_data_n)
    ,.data_o(storebuf_bypass_data_o)
  );

  bsg_dff_en #(.width_p(4)) REG_storebuf_bypass_valid (
    .clock_i(clock_i)
    ,.en_i(bypass_en)
    ,.data_i(storebuf_bypass_valid_n)
    ,.data_o(storebuf_bypass_valid_o)
  );

endmodule
