/**
 *    bsg_cache_to_test_dram_rx.v
 *
 */


`include "bsg_defines.v"

module bsg_cache_to_test_dram_rx
  #(parameter num_cache_p="inv"
    , parameter data_width_p="inv"
    , parameter dma_data_width_p="inv"
    , parameter block_size_in_words_p="inv"

    , parameter dram_data_width_p="inv"
    , parameter dram_channel_addr_width_p="inv"

    , parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    , parameter num_req_lp = (block_size_in_words_p*data_width_p/dram_data_width_p)

  )
  (
    input core_clk_i
    , input core_reset_i

    , output logic [num_cache_p-1:0][dma_data_width_p-1:0] dma_data_o
    , output logic [num_cache_p-1:0] dma_data_v_o
    , input [num_cache_p-1:0] dma_data_ready_i

    , input dram_clk_i
    , input dram_reset_i
    
    , input dram_data_v_i
    , input [dram_data_width_p-1:0] dram_data_i
    , input [dram_channel_addr_width_p-1:0] dram_ch_addr_i
  );


  // ch_addr CDC
  //
  logic ch_addr_afifo_full;
  logic ch_addr_afifo_deq;
  logic [dram_channel_addr_width_p-1:0] ch_addr_lo;
  logic ch_addr_v_lo;

  bsg_async_fifo #(
    .lg_size_p(`BSG_SAFE_CLOG2(`BSG_MAX(num_req_lp*num_cache_p,4)))
    ,.width_p(dram_channel_addr_width_p)
  ) ch_addr_afifo (
    .w_clk_i(dram_clk_i)
    ,.w_reset_i(dram_reset_i)
    ,.w_enq_i(dram_data_v_i)
    ,.w_data_i(dram_ch_addr_i)
    ,.w_full_o(ch_addr_afifo_full)

    ,.r_clk_i(core_clk_i)
    ,.r_reset_i(core_reset_i)
    ,.r_deq_i(ch_addr_afifo_deq)
    ,.r_data_o(ch_addr_lo)
    ,.r_valid_o(ch_addr_v_lo)
  );



  // data CDC
  //
  logic data_afifo_full;
  logic data_afifo_deq;
  logic [dram_data_width_p-1:0] dram_data_lo;
  logic dram_data_v_lo;

  bsg_async_fifo #(
    .lg_size_p(`BSG_SAFE_CLOG2(`BSG_MAX(num_req_lp*num_cache_p,4)))
    ,.width_p(dram_data_width_p)
  ) data_afifo (
    .w_clk_i(dram_clk_i)
    ,.w_reset_i(dram_reset_i)
    ,.w_enq_i(dram_data_v_i)
    ,.w_data_i(dram_data_i)
    ,.w_full_o(data_afifo_full)

    ,.r_clk_i(core_clk_i)
    ,.r_reset_i(core_reset_i)
    ,.r_deq_i(data_afifo_deq)
    ,.r_data_o(dram_data_lo)
    ,.r_valid_o(dram_data_v_lo)
  );


  // reorder buffer
  //
  logic [num_cache_p-1:0] reorder_v_li;

  for (genvar i = 0; i < num_cache_p; i++) begin: re
    bsg_cache_to_test_dram_rx_reorder #(
      .data_width_p(data_width_p)
      ,.dma_data_width_p(dma_data_width_p)
      ,.block_size_in_words_p(block_size_in_words_p)

      ,.dram_data_width_p(dram_data_width_p)
      ,.dram_channel_addr_width_p(dram_channel_addr_width_p)
    ) reorder0 (
      .core_clk_i(core_clk_i)
      ,.core_reset_i(core_reset_i)

      ,.dram_v_i(reorder_v_li[i])
      ,.dram_data_i(dram_data_lo)
      ,.dram_ch_addr_i(ch_addr_lo)

      ,.dma_data_o(dma_data_o[i])
      ,.dma_data_v_o(dma_data_v_o[i])
      ,.dma_data_ready_i(dma_data_ready_i[i])
    );
  end


  // using the ch address, forward the data to the correct cache.
  logic [lg_num_cache_lp-1:0] cache_id;

  if (num_cache_p == 1) begin
    assign cache_id = 1'b0;
  end
  else begin
    assign cache_id = ch_addr_lo[dram_channel_addr_width_p-1-:lg_num_cache_lp];
  end


  bsg_decode_with_v #(
    .num_out_p(num_cache_p)
  ) demux0 (
    .i(cache_id)
    ,.v_i(ch_addr_v_lo & dram_data_v_lo)
    ,.o(reorder_v_li)
  );

  assign data_afifo_deq = ch_addr_v_lo & dram_data_v_lo;
  assign ch_addr_afifo_deq = ch_addr_v_lo & dram_data_v_lo;


  // synopsys translate_off
  
  always_ff @ (negedge dram_clk_i) begin
    if (~dram_reset_i & dram_data_v_i) begin
      assert(~data_afifo_full) else $fatal("data async_fifo full!");
      assert(~ch_addr_afifo_full) else $fatal("ch_addr async_fifo full!");
    end
  end

  // synopsys translate_on


endmodule
