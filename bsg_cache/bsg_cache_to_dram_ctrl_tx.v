/**
 *  bsg_cache_to_dram_ctrl_tx.v
 *
 *  @author tommy
 */


module bsg_cache_to_dram_ctrl_tx
  #(parameter num_cache_p="inv"
    ,parameter data_width_p="inv"
    ,parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    ,parameter burst_width_p="inv"
    ,parameter burst_len_p="inv"
    ,parameter data_width_ratio_lp=burst_width_p/data_width_p
  )
  (
    input clk_i
    ,input reset_i

    ,input v_i
    ,input [lg_num_cache_lp-1:0] tag_i
    ,output logic ready_o

    ,input [num_cache_p-1:0][data_width_p-1:0] dma_data_i
    ,input [num_cache_p-1:0] dma_data_v_i
    ,output logic [num_cache_p-1:0] dma_data_yumi_o

    ,output logic app_wdf_wren_o
    ,input app_wdf_rdy_i
    ,output logic [burst_width_p-1:0] app_wdf_data_o
    ,output logic [(burst_width_p>>3)-1:0] app_wdf_mask_o
    ,output logic app_wdf_end_o
  );

  // tag FIFO
  //
  logic [lg_num_cache_lp-1:0] tag_fifo_data_lo;
  logic tag_fifo_v_lo;
  logic tag_fifo_yumi_li;
  bsg_fifo_1r1w_small #(
    .width_p(lg_num_cache_lp)
    ,.els_p(num_cache_p*2)
  ) fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.v_i(v_i)
    ,.data_i(tag_i)
    ,.ready_o(ready_o)

    ,.v_o(tag_fifo_v_lo)
    ,.data_o(tag_fifo_data_lo)
    ,.yumi_i(tag_fifo_yumi_li)
  );

  // demux
  //
  logic [num_cache_p-1:0] cache_sel;

  bsg_decode_with_v #(
    .num_out_p(num_cache_p)
  ) demux (
    .i(tag_fifo_data_lo)
    ,.v_i(tag_fifo_v_lo)
    ,.o(cache_sel)
  );
  
  // word_counter
  //
  logic [`BSG_SAFE_CLOG2(data_width_ratio_lp)-1:0] word_count_lo;
  logic word_up_li;
  logic word_clear_li;
  bsg_counter_clear_up #(
    .max_val_p(data_width_ratio_lp-1)
    ,.init_val_p(0)
  ) tag_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(word_clear_li)
    ,.up_i(word_up_li)
    ,.count_o(word_count_lo)
  );

  always_comb begin
    if (word_count_lo == data_width_ratio_lp-1) begin
      word_up_li = 1'b0;
      word_clear_li = dma_data_v_i[tag_fifo_data_lo]
        & dma_data_yumi_o[tag_fifo_data_lo] & tag_fifo_v_lo;
      tag_fifo_yumi_li = dma_data_v_i[tag_fifo_data_lo]
        & dma_data_yumi_o[tag_fifo_data_lo] & tag_fifo_v_lo;
    end
    else begin
      word_clear_li = 1'b0;
      word_up_li = dma_data_v_i[tag_fifo_data_lo]
        & dma_data_yumi_o[tag_fifo_data_lo] & tag_fifo_v_lo;
      tag_fifo_yumi_li = 1'b0;
    end
  end

  // serial in parallel out
  //
  logic sipo_v_li;
  logic sipo_ready_lo;
  logic [data_width_p-1:0] sipo_data_li;
  logic [$clog2(data_width_ratio_lp+1)-1:0] sipo_yumi_cnt_li;
  logic [data_width_ratio_lp-1:0] sipo_v_lo;

  assign sipo_data_li = dma_data_i[tag_fifo_data_lo];
  assign dma_data_yumi_o = cache_sel & dma_data_v_i
    & {num_cache_p{sipo_ready_lo}};

  bsg_serial_in_parallel_out #(
    .width_p(data_width_p)
    ,.els_p(data_width_ratio_lp)
  ) sipo (
    .clk_i(clk_i)
    ,.reset_i(reset_i) 

    ,.valid_i(sipo_v_li)
    ,.data_i(sipo_data_li)
    ,.ready_o(sipo_ready_lo) 

    ,.valid_o(sipo_v_lo)
    ,.data_o(app_wdf_data_o)
    ,.yumi_cnt_i(sipo_yumi_cnt_li)
  );

  assign sipo_v_li = tag_fifo_v_lo & dma_data_v_i[tag_fifo_data_lo];

  // burst counter
  //
  logic [`BSG_SAFE_CLOG2(burst_len_p)-1:0] burst_count_lo;
  logic burst_up_li;
  logic burst_clear_li;

  bsg_counter_clear_up #(
    .max_val_p(burst_len_p-1)
    ,.init_val_p(0)
  ) burst_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(burst_clear_li)
    ,.up_i(burst_up_li)
    ,.count_o(burst_count_lo)
  );


  logic dram_wren;
  assign dram_wren = &sipo_v_lo;

  assign sipo_yumi_cnt_li = app_wdf_rdy_i & dram_wren
    ? ($clog2(data_width_ratio_lp+1))'(data_width_ratio_lp)
    : '0;
  assign app_wdf_wren_o = dram_wren;

  always_comb begin
    if (burst_count_lo == burst_len_p-1) begin
      burst_clear_li = dram_wren & app_wdf_rdy_i;
      burst_up_li = 1'b0;
      app_wdf_end_o = dram_wren;
    end
    else begin
      burst_clear_li = 1'b0;
      burst_up_li = dram_wren & app_wdf_rdy_i;
      app_wdf_end_o = 1'b0;
    end
  end


  assign app_wdf_mask_o = '0;

endmodule
