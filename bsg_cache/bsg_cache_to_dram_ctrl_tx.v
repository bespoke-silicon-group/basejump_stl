/**
 *  bsg_cache_to_dram_ctrl_tx.v
 *
 *  @author tommy
 *
 */


`include "bsg_defines.v"

module bsg_cache_to_dram_ctrl_tx
  #(parameter `BSG_INV_PARAM(num_dma_p)
    , parameter `BSG_INV_PARAM(dma_data_width_p)
    , parameter `BSG_INV_PARAM(dma_burst_len_p)

    , parameter `BSG_INV_PARAM(dram_ctrl_burst_len_p)

    , localparam mask_width_lp=(dma_data_width_p>>3)
    , localparam num_req_lp=(dma_burst_len_p/dram_ctrl_burst_len_p)
    , localparam lg_num_dma_lp=`BSG_SAFE_CLOG2(num_dma_p)
    , localparam lg_dram_ctrl_burst_len_lp=`BSG_SAFE_CLOG2(dram_ctrl_burst_len_p)
  )
  (
    input clk_i
    , input reset_i

    , input v_i
    , output logic ready_o

    , input [dma_data_width_p-1:0] dma_data_i
    , input dma_data_v_i
    , output logic dma_data_yumi_o

    , output logic app_wdf_wren_o
    , output logic [dma_data_width_p-1:0] app_wdf_data_o
    , output logic [mask_width_lp-1:0] app_wdf_mask_o
    , output logic app_wdf_end_o
    , input app_wdf_rdy_i
  );

  assign dma_data_yumi_o = dma_data_v_i & app_wdf_rdy_i;
  assign app_wdf_wren_o = dma_data_v_i;
  
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

  wire take_word = app_wdf_wren_o & app_wdf_rdy_i;

  always_comb begin
    if (count_lo == dram_ctrl_burst_len_p-1) begin
      clear_li = take_word;
      up_li = 1'b0;
      app_wdf_end_o = take_word;
    end
    else begin
      clear_li = 1'b0;
      up_li = take_word;
      app_wdf_end_o = 1'b0;
    end
  end

  assign app_wdf_data_o = dma_data_i;
  assign app_wdf_mask_o = '0; // negative active! we always write the whole word.

endmodule

`BSG_ABSTRACT_MODULE(bsg_cache_to_dram_ctrl_tx)
