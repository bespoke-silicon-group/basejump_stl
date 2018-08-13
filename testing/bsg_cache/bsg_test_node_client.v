/**
 * bsg_test_node_client.v
 */


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
    .addr_width_p(32)
    ,.block_size_in_words_p(8)
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

if (id_p == 0) begin : mm

  mock_memory mm (
    .clock_i(clock_i)
    ,.reset_i(reset_i)
  
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
end
else if (id_p == 1) begin : cache_to_dram_ctrl
  
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

end

endmodule
