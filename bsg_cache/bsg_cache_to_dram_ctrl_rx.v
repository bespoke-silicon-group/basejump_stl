/**
 *  bsg_cache_to_dram_ctrl_rx.v
 *
 *  @author tommy
 */


`include "bsg_defines.v"

module bsg_cache_to_dram_ctrl_rx
  #(parameter num_cache_p="inv"
    , parameter data_width_p="inv"
    , parameter block_size_in_words_p="inv"

    , parameter dram_ctrl_burst_len_p="inv"
    
    , localparam lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    , localparam lg_dram_ctrl_burst_len_lp=`BSG_SAFE_CLOG2(dram_ctrl_burst_len_p)
    , localparam num_req_lp=(block_size_in_words_p/dram_ctrl_burst_len_p)
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , input [lg_num_cache_lp-1:0] tag_i
    , output logic ready_o
  
    , output logic [num_cache_p-1:0][data_width_p-1:0] dma_data_o
    , output logic [num_cache_p-1:0] dma_data_v_o
    , input [num_cache_p-1:0] dma_data_ready_i

    , input app_rd_data_valid_i
    , input app_rd_data_end_i
    , input [data_width_p-1:0] app_rd_data_i
  );

  wire unused = app_rd_data_end_i;

  // FIFO to sink incoming data
  // this FIFO should be as deep as the number of possible outstanding read request
  // that can be sent out (limited by the depth of tag_fifo) times the burst length.
  //
  logic fifo_v_lo;
  logic fifo_yumi_li;
  logic [data_width_p-1:0] fifo_data_lo;

  bsg_fifo_1r1w_large #(
    .width_p(data_width_p)
    ,.els_p(num_cache_p*dram_ctrl_burst_len_p)
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


  // tag_fifo
  //
  logic tag_fifo_v_lo;
  logic tag_fifo_yumi_li;
  logic [lg_num_cache_lp-1:0] tag_fifo_data_lo;

  bsg_fifo_1r1w_small #(
    .width_p(lg_num_cache_lp)
    ,.els_p(num_cache_p)
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

  assign fifo_yumi_li = fifo_v_lo & tag_fifo_v_lo & dma_data_ready_i[tag_fifo_data_lo];

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

  for (genvar i = 0; i < num_cache_p; i++) begin
    assign dma_data_o[i] = fifo_data_lo;
    assign dma_data_v_o[i] = cache_sel[i] & fifo_v_lo;
  end

  // counter
  //
  logic [lg_dram_ctrl_burst_len_lp-1:0] count_lo;
  logic counter_up_li;
  logic counter_clear_li;

  bsg_counter_clear_up #(
    .max_val_p(dram_ctrl_burst_len_p-1)
    ,.init_val_p(0)
  ) counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.clear_i(counter_clear_li)
    ,.up_i(counter_up_li)
    ,.count_o(count_lo)
  );

  always_comb begin
    if (count_lo == dram_ctrl_burst_len_p-1) begin
      counter_clear_li = fifo_yumi_li;
      counter_up_li = 1'b0;
      tag_fifo_yumi_li = fifo_yumi_li;
    end
    else begin
      counter_clear_li = 1'b0;
      counter_up_li = fifo_yumi_li;
      tag_fifo_yumi_li = 1'b0;
    end
  end
    
endmodule
