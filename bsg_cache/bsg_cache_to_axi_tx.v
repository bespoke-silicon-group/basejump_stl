/**
 *  bsg_cache_to_axi_tx.v
 *
 *  @author tommy
 */


`include "bsg_defines.v"

module bsg_cache_to_axi_tx
  #(parameter num_cache_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter tag_fifo_els_p=num_cache_p
    
    ,parameter axi_id_width_p="inv"
    ,parameter axi_addr_width_p="inv"
    ,parameter axi_data_width_p="inv"
    ,parameter axi_burst_len_p="inv"

    ,parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)

    ,parameter axi_strb_width_lp=(axi_data_width_p>>3)
    ,parameter data_width_ratio_lp=(axi_data_width_p/data_width_p)
  )
  (
    input clk_i
    ,input reset_i

    ,input v_i
    ,output logic yumi_o
    ,input [lg_num_cache_lp-1:0] tag_i
    ,input [axi_addr_width_p-1:0] axi_addr_i

    // cache dma write channel
    ,input  [num_cache_p-1:0][data_width_p-1:0] dma_data_i
    ,input [num_cache_p-1:0] dma_data_v_i
    ,output logic [num_cache_p-1:0] dma_data_yumi_o

    // axi write address channel
    ,output logic [axi_id_width_p-1:0] axi_awid_o
    ,output logic [axi_addr_width_p-1:0] axi_awaddr_o
    ,output logic [7:0] axi_awlen_o
    ,output logic [2:0] axi_awsize_o
    ,output logic [1:0] axi_awburst_o
    ,output logic [3:0] axi_awcache_o
    ,output logic [2:0] axi_awprot_o
    ,output logic axi_awlock_o
    ,output logic axi_awvalid_o
    ,input axi_awready_i

    // axi write data channel
    ,output logic [axi_data_width_p-1:0] axi_wdata_o
    ,output logic [axi_strb_width_lp-1:0] axi_wstrb_o
    ,output logic axi_wlast_o
    ,output logic axi_wvalid_o
    ,input axi_wready_i

    // axi write response channel
    ,input [axi_id_width_p-1:0] axi_bid_i
    ,input [1:0] axi_bresp_i
    ,input axi_bvalid_i
    ,output logic axi_bready_o
  );

  // tag fifo
  //
  logic tag_fifo_v_li;
  logic tag_fifo_ready_lo;
  logic tag_fifo_v_lo;
  logic tag_fifo_yumi_li;
  logic [lg_num_cache_lp-1:0] tag_lo;

  bsg_fifo_1r1w_small #(
    .width_p(lg_num_cache_lp)
    ,.els_p(tag_fifo_els_p)
  ) tag_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(tag_fifo_v_li)
    ,.ready_o(tag_fifo_ready_lo)
    ,.data_i(tag_i)

    ,.v_o(tag_fifo_v_lo)
    ,.data_o(tag_lo)
    ,.yumi_i(tag_fifo_yumi_li)
  );

  // suppress unused
  //
  wire [axi_id_width_p-1:0] unused_bid = axi_bid_i;
  wire [1:0] unused_bresp = axi_bresp_i;
  wire unused_bvalid = axi_bvalid_i;
  

  // tag 
  //
  // yumi when both tag_fifo and axi_aw are ready
  assign yumi_o = v_i & axi_awready_i & tag_fifo_ready_lo;
  // tag_fifo is valid when axi_aw is ready
  assign tag_fifo_v_li = v_i & axi_awready_i;

  // axi write address channel
  //
  assign axi_awid_o = {axi_id_width_p{1'b0}};
  assign axi_awaddr_o = axi_addr_i;
  assign axi_awlen_o = (8)'(axi_burst_len_p-1); // burst len
  assign axi_awsize_o = (3)'(`BSG_SAFE_CLOG2(axi_data_width_p>>3));
  assign axi_awburst_o = 2'b01;   // incr
  assign axi_awcache_o = 4'b0000; // non-bufferable
  assign axi_awprot_o = 2'b00;    // unprivileged
  assign axi_awlock_o = 1'b0;    // normal access
  // axi_aw is valid when tag_fifo is ready
  assign axi_awvalid_o = v_i & tag_fifo_ready_lo;

  // axi write data channel
  //
  logic sipo_v_li;
  logic sipo_ready_lo;
  logic [data_width_p-1:0] sipo_data_li;
  logic [$clog2(data_width_ratio_lp+1)-1:0] sipo_yumi_cnt_li;
  logic [data_width_ratio_lp-1:0] sipo_v_lo;
  logic [num_cache_p-1:0] cache_sel;
  
  bsg_decode_with_v #(
    .num_out_p(num_cache_p)
  ) demux (
    .i(tag_lo)
    ,.v_i(tag_fifo_v_lo)
    ,.o(cache_sel)
  );

  assign sipo_data_li = dma_data_i[tag_lo];
  assign dma_data_yumi_o = cache_sel & dma_data_v_i & {num_cache_p{sipo_ready_lo}};
 
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
    ,.data_o(axi_wdata_o)
    ,.yumi_cnt_i(sipo_yumi_cnt_li)
  );

  assign axi_wvalid_o = &sipo_v_lo;
  assign sipo_v_li = tag_fifo_v_lo & dma_data_v_i[tag_lo];
  assign sipo_yumi_cnt_li = axi_wvalid_o & axi_wready_i
    ? ($clog2(data_width_ratio_lp+1))'(data_width_ratio_lp)
    : '0;
 
  assign axi_wstrb_o = {axi_strb_width_lp{1'b1}};

  // word counter
  //
  logic [`BSG_SAFE_CLOG2(block_size_in_words_p)-1:0] word_count_lo;
  logic word_up_li;
  logic word_clear_li;

  bsg_counter_clear_up #(
    .max_val_p(block_size_in_words_p-1)
    ,.init_val_p(0)
  ) word_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(word_clear_li)
    ,.up_i(word_up_li)
    ,.count_o(word_count_lo)
  );
  


  logic pop_word;
  assign pop_word = dma_data_v_i[tag_lo] & dma_data_yumi_o[tag_lo] & tag_fifo_v_lo;

  always_comb begin
    if (word_count_lo == block_size_in_words_p-1) begin
      word_clear_li = pop_word;
      word_up_li = 1'b0;
      tag_fifo_yumi_li = pop_word;
    end
    else begin
      word_clear_li = 1'b0;
      word_up_li = pop_word;
      tag_fifo_yumi_li = 1'b0;
    end
  end


  // burst counter
  //
  logic [`BSG_SAFE_CLOG2(axi_burst_len_p)-1:0] burst_count_lo;
  logic burst_up_li;
  logic burst_clear_li;

  bsg_counter_clear_up #(
    .max_val_p(axi_burst_len_p-1)
    ,.init_val_p(0)
  ) burst_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(burst_clear_li)
    ,.up_i(burst_up_li)
    ,.count_o(burst_count_lo)
  );

  always_comb begin
    if (burst_count_lo == axi_burst_len_p-1) begin
      burst_clear_li = axi_wvalid_o & axi_wready_i;
      burst_up_li = 1'b0;
      axi_wlast_o = axi_wvalid_o;
    end
    else begin
      burst_clear_li = 1'b0;
      burst_up_li = axi_wvalid_o & axi_wready_i;
      axi_wlast_o = 1'b0;
    end
  end

  // axi write response channel
  //
  assign axi_bready_o = 1'b1; // don't really care about the resp.
  

endmodule
