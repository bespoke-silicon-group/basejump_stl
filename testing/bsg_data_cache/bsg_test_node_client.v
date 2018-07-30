module bsg_test_node_client #(parameter incr_p="inv")
(
  input clk_i
  ,input rst_i
  ,input en_i

  ,input v_i
  ,input [79:0] data_i
  ,output logic ready_o

  ,output logic v_o
  ,output logic [79:0] data_o
  ,input yumi_i
);

if (incr_p == 1) begin : incr
  bsg_incrementer incr0 (
    .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.en_i(en_i)
    
    ,.v_i(v_i)
    ,.data_i(data_i)
    ,.ready_o(ready_o)
    
    ,.v_o(v_o)
    ,.data_o(data_o)
    ,.yumi_i(yumi_i)
  );
end
else begin : dcache

  wire unused = en_i;
  logic sigext_op;
  logic [1:0] size_op;
  logic [3:0] instr_op;
  logic [31:0] dc_data_i;
  logic [31:0] dc_addr_i;
  logic [31:0] dc_data_o;

  logic dma_rd_wr;
  logic [31:0] dma_addr;
  logic dma_req_v_lo;
  logic dma_req_yumi_li;
  
  logic [31:0] dma_rdata;
  logic dma_rvalid_li;
  logic dma_rready_lo;

  logic [31:0] dma_wdata;
  logic dma_wvalid_lo;
  logic dma_wready_li;

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
    .clk_i(clk_i)
    ,.rst_i(rst_i)

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

    ,.dma_rd_wr_o(dma_rd_wr)
    ,.dma_addr_o(dma_addr)
    ,.dma_req_v_o(dma_req_v_lo)
    ,.dma_req_yumi_i(dma_req_yumi_li)
    
    ,.dma_rdata_i(dma_rdata)
    ,.dma_rvalid_i(dma_rvalid_li)
    ,.dma_rready_o(dma_rready_lo)
  
    ,.dma_wdata_o(dma_wdata)
    ,.dma_wvalid_o(dma_wvalid_lo)
    ,.dma_wready_i(dma_wready_li)
  );

  mock_memory mm (
    .clk_i(clk_i)
    ,.rst_i(rst_i)
  
    ,.dma_rd_wr_i(dma_rd_wr)
    ,.dma_addr_i(dma_addr)
    ,.dma_req_v_i(dma_req_v_lo)
    ,.dma_req_yumi_o(dma_req_yumi_li)

    ,.dma_rdata_o(dma_rdata)
    ,.dma_rvalid_o(dma_rvalid_li)
    ,.dma_rready_i(dma_rready_lo)

    ,.dma_wdata_i(dma_wdata)
    ,.dma_wvalid_i(dma_wvalid_lo)
    ,.dma_wready_o(dma_wready_li)
  );

end

endmodule
