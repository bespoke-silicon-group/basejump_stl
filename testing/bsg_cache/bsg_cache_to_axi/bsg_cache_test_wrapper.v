/**
 *  bsg_cache_test_wrapper.v
 */

`include "bsg_cache_pkt.vh"
`include "bsg_cache_dma_pkt.vh"

module bsg_cache_test_wrapper
  #(parameter num_cache_p = 4
    ,parameter data_width_p = 32
    ,parameter addr_width_p = 32
    ,parameter block_size_in_words_p = 16
    ,parameter sets_p = 16
    ,parameter lo_addr_width_p = 10

    ,parameter axi_id_width_p = 6
    ,parameter axi_addr_width_p = 32
    ,parameter axi_data_width_p = 256
    ,parameter axi_burst_len_p = 2
    ,parameter axi_strb_width_lp = (axi_data_width_p>>3)
  )
  (
    input clk_i
    ,input reset_i

    ,output logic done_o

    // axi write address channel
    ,output logic [axi_id_width_p-1:0] axi_awid_o
    ,output logic [axi_addr_width_p-1:0] axi_awaddr_o
    ,output logic [7:0] axi_awlen_o
    ,output logic [2:0] axi_awsize_o
    ,output logic [1:0] axi_awburst_o
    ,output logic [3:0] axi_awcache_o
    ,output logic [2:0] axi_awprot_o
    ,output logic axi_awlock_o
    ,output logic axi_awvalid_o
    ,input axi_awready_i

    // axi write data channel
    ,output logic [axi_data_width_p-1:0] axi_wdata_o
    ,output logic [axi_strb_width_lp-1:0] axi_wstrb_o
    ,output logic axi_wlast_o
    ,output logic axi_wvalid_o
    ,input axi_wready_i

    // axi write response channel
    ,input [axi_id_width_p-1:0] axi_bid_i
    ,input [1:0] axi_bresp_i
    ,input axi_bvalid_i
    ,output logic axi_bready_o

    // axi read address channel
    ,output logic [axi_id_width_p-1:0] axi_arid_o
    ,output logic [axi_addr_width_p-1:0] axi_araddr_o
    ,output logic [7:0] axi_arlen_o
    ,output logic [2:0] axi_arsize_o
    ,output logic [1:0] axi_arburst_o
    ,output logic [3:0] axi_arcache_o
    ,output logic [2:0] axi_arprot_o
    ,output logic axi_arlock_o
    ,output logic axi_arvalid_o
    ,input axi_arready_i

    // axi read data channel
    ,input [axi_id_width_p-1:0] axi_rid_i
    ,input [axi_data_width_p-1:0] axi_rdata_i
    ,input [1:0] axi_rresp_i
    ,input axi_rlast_i
    ,input axi_rvalid_i
    ,output logic axi_rready_o
  );

  // bsg_test_node_master
  //
  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);
  bsg_cache_pkt_s [num_cache_p-1:0] cache_pkt;
  logic [num_cache_p-1:0] v_lo;
  logic [num_cache_p-1:0] ready_li;
  
  logic [num_cache_p-1:0][data_width_p-1:0] data_li;
  logic [num_cache_p-1:0] v_li;
  logic [num_cache_p-1:0] yumi_lo;

  logic [num_cache_p-1:0] done_lo;

  for (genvar i = 0; i < num_cache_p; i++) begin
    bsg_test_node_master #(
      .id_p(i)
      ,.sets_p(sets_p)
      ,.data_width_p(data_width_p)
      ,.addr_width_p(addr_width_p)
      ,.lo_addr_width_p(lo_addr_width_p)
      ,.block_size_in_words_p(block_size_in_words_p)
    ) master (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
  
      ,.cache_pkt_o(cache_pkt[i])
      ,.v_o(v_lo[i])
      ,.ready_i(ready_li[i])   

      ,.data_i(data_li[i])
      ,.v_i(v_li[i])
      ,.yumi_o(yumi_lo[i]) 
      
      ,.done_o(done_lo[i])
    );
  end

  assign done_o = &done_lo;

  // bsg_cache
  //
  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s [num_cache_p-1:0] dma_pkt;
  logic [num_cache_p-1:0] dma_pkt_v_lo;
  logic [num_cache_p-1:0] dma_pkt_yumi_li;

  logic [num_cache_p-1:0][data_width_p-1:0] dma_data_li;
  logic [num_cache_p-1:0] dma_data_v_li;
  logic [num_cache_p-1:0] dma_data_ready_lo;

  logic [num_cache_p-1:0][data_width_p-1:0] dma_data_lo;
  logic [num_cache_p-1:0] dma_data_v_lo;
  logic [num_cache_p-1:0] dma_data_yumi_li;

  for (genvar i = 0; i < num_cache_p; i++) begin
    bsg_cache #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.block_size_in_words_p(block_size_in_words_p)
      ,.sets_p(sets_p)
    ) cache (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      
      ,.cache_pkt_i(cache_pkt[i])
      ,.v_i(v_lo[i])
      ,.ready_o(ready_li[i])

      ,.data_o(data_li[i])
      ,.v_o(v_li[i])
      ,.yumi_i(yumi_lo[i])

      ,.dma_pkt_o(dma_pkt[i])
      ,.dma_pkt_v_o(dma_pkt_v_lo[i])
      ,.dma_pkt_yumi_i(dma_pkt_yumi_li[i])

      ,.dma_data_i(dma_data_li[i])
      ,.dma_data_v_i(dma_data_v_li[i])
      ,.dma_data_ready_o(dma_data_ready_lo[i])

      ,.dma_data_o(dma_data_lo[i])
      ,.dma_data_v_o(dma_data_v_lo[i])
      ,.dma_data_yumi_i(dma_data_yumi_li[i])

      ,.v_we_o()
    );
  end

  // bsg_cache_to_axi
  //

  bsg_cache_to_axi #(
    .addr_width_p(addr_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.data_width_p(data_width_p)
    ,.num_cache_p(num_cache_p)
    ,.lo_addr_width_p(lo_addr_width_p)

    ,.axi_id_width_p(axi_id_width_p)
    ,.axi_addr_width_p(axi_addr_width_p)
    ,.axi_data_width_p(axi_data_width_p)
    ,.axi_burst_len_p(axi_burst_len_p)
  ) cache_to_axi (
    .clk_i(clk_i)
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

    ,.axi_awid_o(axi_awid_o)
    ,.axi_awaddr_o(axi_awaddr_o)
    ,.axi_awlen_o(axi_awlen_o)
    ,.axi_awsize_o(axi_awsize_o)
    ,.axi_awburst_o(axi_awburst_o)
    ,.axi_awcache_o(axi_awcache_o)
    ,.axi_awprot_o(axi_awprot_o)
    ,.axi_awlock_o(axi_awlock_o)
    ,.axi_awvalid_o(axi_awvalid_o)
    ,.axi_awready_i(axi_awready_i)

    ,.axi_wdata_o(axi_wdata_o)
    ,.axi_wstrb_o(axi_wstrb_o)
    ,.axi_wlast_o(axi_wlast_o)
    ,.axi_wvalid_o(axi_wvalid_o)
    ,.axi_wready_i(axi_wready_i)

    ,.axi_bid_i(axi_bid_i)
    ,.axi_bresp_i(axi_bresp_i)
    ,.axi_bvalid_i(axi_bvalid_i)
    ,.axi_bready_o(axi_bready_o)

    ,.axi_arid_o(axi_arid_o)
    ,.axi_araddr_o(axi_araddr_o)
    ,.axi_arlen_o(axi_arlen_o)
    ,.axi_arsize_o(axi_arsize_o)
    ,.axi_arburst_o(axi_arburst_o)
    ,.axi_arcache_o(axi_arcache_o)
    ,.axi_arprot_o(axi_arprot_o)
    ,.axi_arlock_o(axi_arlock_o)
    ,.axi_arvalid_o(axi_arvalid_o)
    ,.axi_arready_i(axi_arready_i)

    ,.axi_rid_i(axi_rid_i)
    ,.axi_rdata_i(axi_rdata_i)
    ,.axi_rresp_i(axi_rresp_i)
    ,.axi_rlast_i(axi_rlast_i)
    ,.axi_rvalid_i(axi_rvalid_i)
    ,.axi_rready_o(axi_rready_o)
  );

endmodule
