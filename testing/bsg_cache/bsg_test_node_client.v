/**
 * bsg_test_node_client.v
 */

`include "bsg_cache_pkt.vh"
`include "bsg_cache_dma_pkt.vh"

module bsg_test_node_client 
  import bsg_cache_pkg::*;
  import bsg_dram_ctrl_pkg::*;
  #(parameter id_p="inv")
(
  input clock_i
  ,input reset_i
  ,input en_i

  ,input v_i
  ,input [79:0] data_i
  ,output logic ready_o

  ,output logic v_o
  ,output logic [79:0] data_o
  ,input yumi_i
);

  `declare_bsg_cache_pkt_s(32, 32);

  wire unused = en_i;
  bsg_cache_pkt_s packet;
  assign packet = data_i[73:0]; 
  logic [31:0] dc_data_o;

  `declare_bsg_cache_dma_pkt_s(32);
  bsg_cache_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo;
  logic dma_pkt_yumi_li;
  
  logic [31:0] dma_data_li;
  logic dma_data_v_li;
  logic dma_data_ready_lo;

  logic [31:0] dma_data_lo;
  logic dma_data_v_lo;
  logic dma_data_yumi_li;

  assign data_o = {48'b0, dc_data_o};

  bsg_cache #(
    .addr_width_p(32)
    ,.data_width_p(32)
    ,.block_size_in_words_p(8)
    ,.sets_p(512)
  ) cache (
    .clk_i(clock_i)
    ,.reset_i(reset_i)

    ,.cache_pkt_i(packet)
    ,.v_i(v_i)
    ,.ready_o(ready_o)

    ,.v_o(v_o)
    ,.yumi_i(yumi_i)
    ,.data_o(dc_data_o)

    ,.v_we_o()

    ,.dma_pkt_o(dma_pkt)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)

    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_o(dma_data_ready_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)
  );

  bsg_dram_ctrl_if #(
    .addr_width_p(32)
    ,.data_width_p(128)
  ) dram_if (
    .clk_i(clock_i)
  );

  bsg_cache_to_dram_ctrl #(
    .addr_width_p(32)
    ,.block_size_in_words_p(8)
    ,.cache_word_width_p(32)
    ,.burst_len_p(1)
    ,.burst_width_p(128)
  ) cache_to_dram_ctrl (
    .clock_i(clock_i)
    ,.reset_i(reset_i)
   
    ,.dma_pkt_i(dma_pkt)
    ,.dma_pkt_v_i(dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

    ,.dma_data_o(dma_data_li)
    ,.dma_data_v_o(dma_data_v_li)
    ,.dma_data_ready_i(dma_data_ready_lo)

    ,.dma_data_i(dma_data_lo)
    ,.dma_data_v_i(dma_data_v_lo)
    ,.dma_data_yumi_o(dma_data_yumi_li)
 
    ,.dram_ctrl_if(dram_if)
  );  

  mock_dram_ctrl #(
    .addr_width_p(32)
    ,.data_width_p(128)
    ,.burst_len_p(1)
    ,.mem_size_p(4096)
  ) dram_ctrl (
    .clock_i(clock_i)
    ,.reset_i(reset_i)
    ,.dram_ctrl_if(dram_if)
  );

endmodule
