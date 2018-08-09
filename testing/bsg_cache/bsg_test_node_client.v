/**
 * bsg_test_node_client.v
 */

import bsg_cache_pkg::*;

module bsg_test_node_client
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

  wire unused = en_i;
  
  bsg_cache_pkt_s packet;
  assign packet = data_i[73:0]; 
  logic [31:0] dc_data_o;

  logic dma_req_ch_write_not_read;
  logic [31:0] dma_req_ch_addr;
  logic dma_req_ch_v_lo;
  logic dma_req_ch_yumi_li;
  
  logic [31:0] dma_read_ch_data;
  logic dma_read_ch_v_li;
  logic dma_read_ch_ready_lo;

  logic [31:0] dma_write_ch_data;
  logic dma_write_ch_v_lo;
  logic dma_write_ch_yumi_li;

  assign data_o = {48'b0, dc_data_o};

  bsg_cache #(
    .block_size_in_words_p(8)
    ,.sets_p(512)
  ) dcache0 (
    .clock_i(clock_i)
    ,.reset_i(reset_i)

    ,.packet_i(packet)
    ,.v_i(v_i)
    ,.ready_o(ready_o)

    ,.v_o(v_o)
    ,.yumi_i(yumi_i)
    ,.data_o(dc_data_o)

    ,.dma_req_ch_write_not_read_o(dma_req_ch_write_not_read)
    ,.dma_req_ch_addr_o(dma_req_ch_addr)
    ,.dma_req_ch_v_o(dma_req_ch_v_lo)
    ,.dma_req_ch_yumi_i(dma_req_ch_yumi_li)
    
    ,.dma_read_ch_data_i(dma_read_ch_data)
    ,.dma_read_ch_v_i(dma_read_ch_v_li)
    ,.dma_read_ch_ready_o(dma_read_ch_ready_lo)
  
    ,.dma_write_ch_data_o(dma_write_ch_data)
    ,.dma_write_ch_v_o(dma_write_ch_v_lo)
    ,.dma_write_ch_yumi_i(dma_write_ch_yumi_li)
  );

  mock_memory mm (
    .clock_i(clock_i)
    ,.reset_i(reset_i)
  
    ,.dma_req_ch_write_not_read_i(dma_req_ch_write_not_read)
    ,.dma_req_ch_addr_i(dma_req_ch_addr)
    ,.dma_req_ch_v_i(dma_req_ch_v_lo)
    ,.dma_req_ch_yumi_o(dma_req_ch_yumi_li)

    ,.dma_read_ch_data_o(dma_read_ch_data)
    ,.dma_read_ch_v_o(dma_read_ch_v_li)
    ,.dma_read_ch_ready_i(dma_read_ch_ready_lo)

    ,.dma_write_ch_data_i(dma_write_ch_data)
    ,.dma_write_ch_v_i(dma_write_ch_v_lo)
    ,.dma_write_ch_yumi_o(dma_write_ch_yumi_li)
  );

endmodule
