/**
 *  bsg_cache_to_dram_ctrl_tx.v
 *
 *  @author tommy
 *
 */


`include "bsg_defines.v"

module bsg_cache_to_dram_ctrl_tx
  #(parameter `BSG_INV_PARAM(num_cache_p)
    , parameter `BSG_INV_PARAM(data_width_p)
    , parameter `BSG_INV_PARAM(block_size_in_words_p)
    , parameter `BSG_INV_PARAM(dma_mask_width_p)
    , parameter `BSG_INV_PARAM(dram_ctrl_burst_len_p)

    , localparam mask_width_lp=(data_width_p>>3)
    , localparam dma_byte_mask_width_lp=(block_size_in_words_p*mask_width_lp)
    , localparam num_req_lp=(block_size_in_words_p/dram_ctrl_burst_len_p)
    , localparam lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    , localparam lg_dram_ctrl_burst_len_lp=`BSG_SAFE_CLOG2(dram_ctrl_burst_len_p)
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [lg_num_cache_lp-1:0] tag_i
    , input [dma_mask_width_p-1:0] mask_i
    , output logic ready_o

    , input [num_cache_p-1:0][data_width_p-1:0] dma_data_i
    , input [num_cache_p-1:0] dma_data_v_i
    , output logic [num_cache_p-1:0] dma_data_yumi_o

    , output logic app_wdf_wren_o
    , output logic [data_width_p-1:0] app_wdf_data_o
    , output logic [mask_width_lp-1:0] app_wdf_mask_o
    , output logic app_wdf_end_o
    , input app_wdf_rdy_i
  );


  // tag FIFO
  //
  logic [lg_num_cache_lp-1:0] tag_lo;
  logic [dma_mask_width_p-1:0] mask_lo;
  logic tag_fifo_v_lo;
  logic tag_fifo_yumi_li;

  bsg_fifo_1r1w_small #(
    .width_p(lg_num_cache_lp+dma_mask_width_p)
    ,.els_p(num_cache_p*num_req_lp)
  ) tag_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.v_i(v_i)
    ,.data_i({tag_i, mask_i})
    ,.ready_o(ready_o)

    ,.v_o(tag_fifo_v_lo)
    ,.data_o({tag_lo, mask_lo})
    ,.yumi_i(tag_fifo_yumi_li)
  );

  // demux
  //
  logic [num_cache_p-1:0] cache_sel;

  bsg_decode_with_v #(
    .num_out_p(num_cache_p)
  ) demux (
    .i(tag_lo)
    ,.v_i(tag_fifo_v_lo)
    ,.o(cache_sel)
  );

  assign dma_data_yumi_o = cache_sel & dma_data_v_i & {num_cache_p{app_wdf_rdy_i}};
  assign app_wdf_wren_o = tag_fifo_v_lo & dma_data_v_i[tag_lo];
  
  // burst counter
  //
  logic [lg_dram_ctrl_burst_len_lp-1:0] count_lo;
  logic up_li;
  logic clear_li;

  bsg_counter_clear_up #(
    .max_val_p(dram_ctrl_burst_len_p-1)
    ,.init_val_p(0)
  ) word_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.clear_i(clear_li)
    ,.up_i(up_li)

    ,.count_o(count_lo)
  );

  logic [dma_byte_mask_width_lp-1:0] byte_mask_lo;
  bsg_expand_bitmask #(
    .in_width_p(dma_mask_width_p)
    ,.expand_p(dma_byte_mask_width_lp/dma_mask_width_p)
  ) expand (
    .i(mask_lo)
    ,.o(byte_mask_lo)
  );

  bsg_mux #(
    .width_p(mask_width_lp)
    ,.els_p(dram_ctrl_burst_len_p)
  ) wdf_mask_mux (
    .data_i(~byte_mask_lo[(dma_byte_mask_width_lp/num_req_lp)-1:0])
    ,.sel_i(count_lo)
    ,.data_o(app_wdf_mask_o)
  );

  logic take_word;
  assign take_word = app_wdf_wren_o & app_wdf_rdy_i;

  always_comb begin
    if (count_lo == dram_ctrl_burst_len_p-1) begin
      clear_li = take_word;
      up_li = 1'b0;
      app_wdf_end_o = take_word;
      tag_fifo_yumi_li = take_word;
    end
    else begin
      clear_li = 1'b0;
      up_li = take_word;
      app_wdf_end_o = 1'b0;
      tag_fifo_yumi_li = 1'b0;
    end
  end

  assign app_wdf_data_o = dma_data_i[tag_lo];

endmodule

`BSG_ABSTRACT_MODULE(bsg_cache_to_dram_ctrl_tx)
