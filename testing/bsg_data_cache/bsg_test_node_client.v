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
  logic sigext_op;
  logic [1:0] size_op;
  logic [3:0] instr_op;
  logic [31:0] dc_data_i;
  logic [31:0] dc_addr_i;
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

  assign sigext_op = data_i[70];
  assign size_op = data_i[69:68];
  assign instr_op = data_i[67:64];
  assign dc_addr_i = data_i[63:32];
  assign dc_data_i = data_i[31:0];
  assign data_o = {48'b0, dc_data_o};

  bsg_data_cache #(
    .block_size_p(8)
    ,.els_p(512)
  ) dcache0 (
    .clock_i(clock_i)
    ,.reset_i(reset_i)

    ,.sigext_op_i(sigext_op)
    ,.size_op_i(size_op)
    ,.instr_op_i(instr_op)
    ,.addr_i(dc_addr_i)
    ,.data_i(dc_data_i)
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
