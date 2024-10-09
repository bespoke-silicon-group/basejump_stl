/**
 *  bsg_cache_to_dram_ctrl_rx.sv
 *
 *  @author tommy
 */


`include "bsg_defines.sv"

module bsg_cache_to_dram_ctrl_rx
  #(parameter `BSG_INV_PARAM(num_dma_p)
    , parameter `BSG_INV_PARAM(dma_data_width_p)
    , parameter `BSG_INV_PARAM(dma_burst_len_p)

    , parameter `BSG_INV_PARAM(dram_ctrl_burst_len_p)
    
    , localparam lg_num_dma_lp=`BSG_SAFE_CLOG2(num_dma_p)
    , localparam lg_dram_ctrl_burst_len_lp=`BSG_SAFE_CLOG2(dram_ctrl_burst_len_p)
    , localparam num_req_lp=(dma_burst_len_p/dram_ctrl_burst_len_p)
  )
  (
    input clk_i
    , input reset_i

    , output logic [dma_data_width_p-1:0] dma_data_o
    , output logic dma_data_v_o
    , input dma_data_ready_and_i

    , input app_rd_data_valid_i
    , input app_rd_data_end_i
    , input [dma_data_width_p-1:0] app_rd_data_i
  );

  wire unused = app_rd_data_end_i;

  // FIFO to sink incoming data
  // this FIFO should be as deep as the number of possible outstanding read request
  // that can be sent out (limited by the depth of tag_fifo) times the burst length.
  //
  logic fifo_v_lo;
  logic fifo_yumi_li;
  logic [dma_data_width_p-1:0] fifo_data_lo;

  bsg_fifo_1r1w_large #(
    .width_p(dma_data_width_p)
    ,.els_p(num_dma_p*dram_ctrl_burst_len_p)
  ) fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(app_rd_data_valid_i)
    ,.data_i(app_rd_data_i)
    ,.ready_and_o()

    ,.v_o(fifo_v_lo)
    ,.data_o(fifo_data_lo)
    ,.yumi_i(fifo_yumi_li)
  );

  assign fifo_yumi_li = fifo_v_lo & dma_data_ready_and_i;

  // demux
  //

  assign dma_data_o = fifo_data_lo;
  assign dma_data_v_o = fifo_v_lo;

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
    end
    else begin
      counter_clear_li = 1'b0;
      counter_up_li = fifo_yumi_li;
    end
  end
    
endmodule

`BSG_ABSTRACT_MODULE(bsg_cache_to_dram_ctrl_rx)
