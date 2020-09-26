/**
 *    bsg_cache_to_test_dram_tx.v
 *
 */


`include "bsg_defines.v"

module bsg_cache_to_test_dram_tx
  #(parameter num_cache_p="inv"
    , parameter data_width_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter dma_data_width_p="inv"

    , parameter dram_data_width_p="inv"

    , parameter num_req_lp = (block_size_in_words_p*data_width_p/dram_data_width_p)
    , parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
  )
  (
    input core_clk_i
    , input core_reset_i

    , input v_i
    , input [lg_num_cache_lp-1:0] tag_i
    , output logic ready_o
      
    , input [num_cache_p-1:0][dma_data_width_p-1:0] dma_data_i
    , input [num_cache_p-1:0] dma_data_v_i
    , output logic [num_cache_p-1:0] dma_data_yumi_o

    , input dram_clk_i
    , input dram_reset_i

    , output logic dram_data_v_o
    , output logic [dram_data_width_p-1:0] dram_data_o
    , input dram_data_yumi_i
  );

  
  //  tag fifo
  //
  logic tag_v_lo;
  logic [lg_num_cache_lp-1:0] tag_lo;
  logic tag_yumi_li;  

  bsg_fifo_1r1w_small #(
    .width_p(lg_num_cache_lp)
    ,.els_p(num_cache_p*num_req_lp)
  ) tag_fifo (
    .clk_i(core_clk_i)
    ,.reset_i(core_reset_i)

    ,.v_i(v_i)
    ,.ready_o(ready_o)
    ,.data_i(tag_i)

    ,.v_o(tag_v_lo)
    ,.data_o(tag_lo)
    ,.yumi_i(tag_yumi_li)
  );

  logic [num_cache_p-1:0] cache_sel;
  bsg_decode_with_v #(
    .num_out_p(num_cache_p)
  ) demux (
    .i(tag_lo)
    ,.v_i(tag_v_lo)
    ,.o(cache_sel)
  );

  //  de-serialization
  //
  logic [num_cache_p-1:0] sipo_v_li;
  logic [num_cache_p-1:0] sipo_ready_lo;
  logic [num_cache_p-1:0][dma_data_width_p-1:0] sipo_data_li;

  logic [num_cache_p-1:0] sipo_v_lo;
  logic [num_cache_p-1:0][dram_data_width_p-1:0] sipo_data_lo;
  logic [num_cache_p-1:0] sipo_yumi_li;

  for (genvar i = 0; i < num_cache_p; i++) begin

    bsg_serial_in_parallel_out_full #(
      .width_p(dma_data_width_p)
      ,.els_p(dram_data_width_p/dma_data_width_p)
    ) sipo (
      .clk_i(core_clk_i)
      ,.reset_i(core_reset_i)

      ,.v_i(sipo_v_li[i])
      ,.data_i(sipo_data_li[i])
      ,.ready_o(sipo_ready_lo[i])

      ,.v_o(sipo_v_lo[i])
      ,.data_o(sipo_data_lo[i])
      ,.yumi_i(sipo_yumi_li[i])
    );

  end
 

  if (num_req_lp == 1) begin
    assign sipo_v_li = dma_data_v_i;
    assign sipo_data_li = dma_data_i;
    assign dma_data_yumi_o = dma_data_v_i & sipo_ready_lo;
  end
  else begin
    logic [num_cache_p-1:0] fifo_ready_lo;

    for (genvar i = 0; i < num_cache_p; i++) begin
      bsg_fifo_1r1w_small #(
        .width_p(dma_data_width_p)
        ,.els_p(block_size_in_words_p*data_width_p/dma_data_width_p)
      ) fifo0 (
        .clk_i(core_clk_i)
        ,.reset_i(core_reset_i)

        ,.v_i(dma_data_v_i[i])
        ,.ready_o(fifo_ready_lo[i])
        ,.data_i(dma_data_i[i])

        ,.v_o(sipo_v_li[i])
        ,.data_o(sipo_data_li[i])
        ,.yumi_i(sipo_v_li[i] & sipo_ready_lo[i])
      );
      
      assign dma_data_yumi_o[i] = fifo_ready_lo[i] & dma_data_v_i[i];
    end

  end 

 
  // async fifo
  //
  logic afifo_full;
  logic [dram_data_width_p-1:0] afifo_data_li;
  logic afifo_enq;

  bsg_async_fifo #(
    .lg_size_p(`BSG_SAFE_CLOG2(`BSG_MAX(num_cache_p*num_req_lp,4)))
    ,.width_p(dram_data_width_p)
  ) data_afifo (
    .w_clk_i(core_clk_i)
    ,.w_reset_i(core_reset_i)
    ,.w_enq_i(afifo_enq)
    ,.w_data_i(afifo_data_li)
    ,.w_full_o(afifo_full)
  
    ,.r_clk_i(dram_clk_i) 
    ,.r_reset_i(dram_reset_i)
    ,.r_deq_i(dram_data_yumi_i)
    ,.r_data_o(dram_data_o)
    ,.r_valid_o(dram_data_v_o)
  );

  wire send_data = tag_v_lo & ~afifo_full & sipo_v_lo[tag_lo];
  assign afifo_enq = send_data;
  assign tag_yumi_li = send_data;
  assign afifo_data_li = sipo_data_lo[tag_lo];

  bsg_decode_with_v #(
    .num_out_p(num_cache_p)  
  ) demux0 (
    .i(tag_lo)
    ,.v_i(send_data)
    ,.o(sipo_yumi_li)
  );



endmodule
