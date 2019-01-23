/**
 *  bsg_cache_to_dram_ctrl_rx.v
 *
 *  @author tommy
 */


module bsg_cache_to_dram_ctrl_rx
  #(parameter num_cache_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter dram_ctrl_data_width_p="inv"
    ,parameter dram_ctrl_burst_len_p="inv"
    
    ,parameter num_req_lp=(data_width_p*block_size_in_words_p)/(dram_ctrl_data_width_p*dram_ctrl_burst_len_p)
    ,parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    ,parameter data_width_ratio_lp=(dram_ctrl_data_width_p/data_width_p)
    ,parameter lg_data_width_ratio_lp=`BSG_SAFE_CLOG2(data_width_ratio_lp)
  )
  (
    input clk_i
    ,input reset_i

    ,input v_i
    ,input [lg_num_cache_lp-1:0] tag_i
    ,output logic ready_o
  
    ,output logic [num_cache_p-1:0][data_width_p-1:0] dma_data_o
    ,output logic [num_cache_p-1:0] dma_data_v_o
    ,input [num_cache_p-1:0] dma_data_ready_i

    ,input app_rd_data_valid_i
    ,input [dram_ctrl_data_width_p-1:0] app_rd_data_i
    ,input app_rd_data_end_i
  );

  // FIFO to sink incoming data
  //
  logic fifo_v_lo;
  logic fifo_yumi_li;
  logic [dram_ctrl_data_width_p-1:0] fifo_data_lo;

  bsg_fifo_1r1w_large #(
    .width_p(dram_ctrl_data_width_p)
    ,.els_p(num_cache_p*dram_ctrl_burst_len_p*num_req_lp)
  ) fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(app_rd_data_valid_i)
    ,.data_i(app_rd_data_i)
    ,.ready_o()

    ,.v_o(fifo_v_lo)
    ,.data_o(fifo_data_lo)
    ,.yumi_i(fifo_yumi_li)
  );
 
  // parallel in serial out
  // 
  logic piso_ready_lo;
  logic piso_v_lo;
  logic [data_width_p-1:0] piso_data_lo;
  logic piso_yumi_li;

  bsg_parallel_in_serial_out #(
    .width_p(data_width_p)
    ,.els_p(data_width_ratio_lp)
  ) piso (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.valid_i(fifo_v_lo)
    ,.data_i(fifo_data_lo)
    ,.ready_o(piso_ready_lo)

    ,.valid_o(piso_v_lo)
    ,.data_o(piso_data_lo)
    ,.yumi_i(piso_yumi_li)
  );

  assign fifo_yumi_li = fifo_v_lo & piso_ready_lo;

  // tag_fifo
  //
  logic tag_fifo_v_lo;
  logic tag_fifo_yumi_li;
  logic [lg_num_cache_lp-1:0] tag_fifo_data_lo;

  bsg_fifo_1r1w_small #(
    .width_p(lg_num_cache_lp)
    ,.els_p(num_cache_p*num_req_lp)
  ) tag_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(v_i)
    ,.ready_o(ready_o)
    ,.data_i(tag_i)

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

  assign dma_data_v_o = cache_sel & {(num_cache_p){piso_v_lo}};

  for (genvar i = 0; i < num_cache_p; i++) begin
    assign dma_data_o[i] = piso_data_lo;
  end

  // counter
  //
  logic [lg_data_width_ratio_lp-1:0] count_lo;
  logic counter_up_li;
  logic counter_clear_li;

  bsg_counter_clear_up #(
    .max_val_p(data_width_ratio_lp-1)
    ,.init_val_p(0)
  ) counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(counter_clear_li)
    ,.up_i(counter_up_li)
    ,.count_o(count_lo)
  );

  assign piso_yumi_li = dma_data_ready_i[tag_fifo_data_lo] & piso_v_lo & tag_fifo_v_lo;

  always_comb begin
    if (count_lo == data_width_ratio_lp-1) begin
      counter_clear_li = piso_yumi_li;
      counter_up_li = 1'b0;
      tag_fifo_yumi_li = piso_yumi_li;
    end
    else begin
      counter_clear_li = 1'b0;
      counter_up_li = piso_yumi_li;
      tag_fifo_yumi_li = 1'b0;
    end
  end
    
endmodule
