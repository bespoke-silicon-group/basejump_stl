/**
 *  bsg_cache_to_axi.sv
 *    
 *  @author tommy
 */

`include "bsg_defines.sv"
`include "bsg_cache.svh"

module bsg_cache_to_axi
  import bsg_axi_pkg::*;
  import bsg_cache_pkg::*;
  #(parameter `BSG_INV_PARAM(addr_width_p)
    ,parameter `BSG_INV_PARAM(block_size_in_words_p)
    ,parameter `BSG_INV_PARAM(data_width_p)
    ,parameter `BSG_INV_PARAM(mask_width_p)
    ,parameter `BSG_INV_PARAM(num_cache_p)
    
    // tag fifo size can be greater than number of cache dma interfaces
    // Set to maximum possible outstanding requests to avoid stalling
    ,parameter tag_fifo_els_p=num_cache_p

    ,parameter `BSG_INV_PARAM(axi_id_width_p) // 6
    ,parameter `BSG_INV_PARAM(axi_data_width_p)
    ,parameter `BSG_INV_PARAM(axi_burst_len_p)
    ,parameter `BSG_INV_PARAM(axi_burst_type_p)

    // enables read/write ordering
    ,parameter `BSG_INV_PARAM(ordering_en_p)

    ,parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    ,parameter dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p, mask_width_p)

    ,parameter axi_strb_width_lp=(axi_data_width_p>>3)
  )
  (
    input clk_i
    ,input reset_i

    // cache side
    ,input [num_cache_p-1:0][dma_pkt_width_lp-1:0] dma_pkt_i
    ,input [num_cache_p-1:0] dma_pkt_v_i
    ,output logic [num_cache_p-1:0] dma_pkt_yumi_o

    ,output logic [num_cache_p-1:0][data_width_p-1:0] dma_data_o
    ,output logic [num_cache_p-1:0] dma_data_v_o
    ,input [num_cache_p-1:0] dma_data_ready_and_i

    ,input [num_cache_p-1:0][data_width_p-1:0] dma_data_i
    ,input [num_cache_p-1:0] dma_data_v_i
    ,output logic [num_cache_p-1:0] dma_data_yumi_o

    // axi write address channel
    ,output logic [axi_id_width_p-1:0] axi_awid_o
    ,output logic [addr_width_p-1:0] axi_awaddr_addr_o
    ,output logic [lg_num_cache_lp-1:0] axi_awaddr_cache_id_o
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
    ,output logic [addr_width_p-1:0] axi_araddr_addr_o
    ,output logic [lg_num_cache_lp-1:0] axi_araddr_cache_id_o
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

  // dma packets from caches
  //
  `declare_bsg_cache_dma_pkt_s(addr_width_p, mask_width_p);
  bsg_cache_dma_pkt_s [num_cache_p-1:0] dma_pkt;
  assign dma_pkt = dma_pkt_i;

  // reader round-robin
  //
  logic [num_cache_p-1:0] read_rr_v_li;
  logic [num_cache_p-1:0] read_rr_yumi_lo;
  logic read_rr_v_lo;
  bsg_cache_dma_pkt_s read_rr_dma_pkt;
  logic [lg_num_cache_lp-1:0] read_rr_tag_lo;
  logic read_rr_yumi_li;

  for (genvar i = 0; i < num_cache_p; i++) begin
    assign read_rr_v_li[i] = dma_pkt_v_i[i] & ~dma_pkt[i].write_not_read;
  end

  bsg_round_robin_n_to_1 #(
    .width_p(dma_pkt_width_lp)
    ,.num_in_p(num_cache_p)
    ,.strict_p(0)
  ) read_rr (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.data_i(dma_pkt)
    ,.v_i(read_rr_v_li)
    ,.yumi_o(read_rr_yumi_lo)
    
    ,.v_o(read_rr_v_lo)
    ,.data_o(read_rr_dma_pkt)
    ,.tag_o(read_rr_tag_lo)
    ,.yumi_i(read_rr_yumi_li)
  );

  // writer round-robin
  //
  logic [num_cache_p-1:0] write_rr_v_li;
  logic [num_cache_p-1:0] write_rr_yumi_lo;
  logic write_rr_v_lo;
  bsg_cache_dma_pkt_s write_rr_dma_pkt;
  logic [lg_num_cache_lp-1:0] write_rr_tag_lo;
  logic write_rr_yumi_li;

  for (genvar i = 0; i < num_cache_p; i++) begin
    assign write_rr_v_li[i] = dma_pkt_v_i[i] & dma_pkt[i].write_not_read;
  end

  bsg_round_robin_n_to_1 #(
    .width_p(dma_pkt_width_lp)
    ,.num_in_p(num_cache_p)
    ,.strict_p(0)
  ) write_rr (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.data_i(dma_pkt)
    ,.v_i(write_rr_v_li)
    ,.yumi_o(write_rr_yumi_lo)

    ,.v_o(write_rr_v_lo)
    ,.data_o(write_rr_dma_pkt)
    ,.tag_o(write_rr_tag_lo)
    ,.yumi_i(write_rr_yumi_li)
  );

  // One example of address translation corresponding to tag and addr
  //
  // logic [axi_addr_width_p-1:0] rx_axi_addr;
  // logic [axi_addr_width_p-1:0] tx_axi_addr;

  // assign rx_axi_addr = {
  //   {(axi_addr_width_p-lg_num_cache_lp-addr_width_p){1'b0}}
  //   ,read_rr_tag_lo
  //   ,read_rr_dma_pkt.addr
  // };  

  // assign tx_axi_addr = {
  //   {(axi_addr_width_p-lg_num_cache_lp-addr_width_p){1'b0}}
  //   ,write_rr_tag_lo
  //   ,write_rr_dma_pkt.addr
  // };  

  // dma_pkt handshake
  //
  for (genvar i = 0; i < num_cache_p; i++) begin
    assign dma_pkt_yumi_o[i] = dma_pkt[i].write_not_read
      ? write_rr_yumi_lo[i]
      : read_rr_yumi_lo[i];
  end

  logic r_fence_lo, w_fence_lo;

  // rx
  //
  bsg_cache_to_axi_rx #(
    .num_cache_p(num_cache_p)
    ,.addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.tag_fifo_els_p(tag_fifo_els_p)
    ,.axi_id_width_p(axi_id_width_p)
    ,.axi_data_width_p(axi_data_width_p)
    ,.axi_burst_len_p(axi_burst_len_p)
    ,.axi_burst_type_p(axi_burst_type_p)
  ) axi_rx (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(read_rr_v_lo)
    ,.yumi_o(read_rr_yumi_li)
    ,.cache_id_i(read_rr_tag_lo)
    ,.addr_i(read_rr_dma_pkt.addr)

    ,.fence_i(r_fence_lo)

    ,.dma_data_o(dma_data_o)
    ,.dma_data_v_o(dma_data_v_o)
    ,.dma_data_ready_and_i(dma_data_ready_and_i)

    ,.axi_arid_o(axi_arid_o)
    ,.axi_araddr_addr_o(axi_araddr_addr_o)
    ,.axi_araddr_cache_id_o(axi_araddr_cache_id_o)
    ,.axi_arlen_o(axi_arlen_o)
    ,.axi_arsize_o(axi_arsize_o)
    ,.axi_arburst_o(axi_arburst_o)
    ,.axi_arcache_o(axi_arcache_o)
    ,.axi_arvalid_o(axi_arvalid_o)
    ,.axi_arlock_o(axi_arlock_o)
    ,.axi_arprot_o(axi_arprot_o)
    ,.axi_arready_i(axi_arready_i)

    ,.axi_rid_i(axi_rid_i)
    ,.axi_rdata_i(axi_rdata_i)
    ,.axi_rresp_i(axi_rresp_i)
    ,.axi_rlast_i(axi_rlast_i)
    ,.axi_rvalid_i(axi_rvalid_i)
    ,.axi_rready_o(axi_rready_o)
  );

  // tx
  //
  bsg_cache_to_axi_tx #(
    .num_cache_p(num_cache_p)
    ,.addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.mask_width_p(mask_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.tag_fifo_els_p(tag_fifo_els_p)
    ,.axi_id_width_p(axi_id_width_p)
    ,.axi_data_width_p(axi_data_width_p)
    ,.axi_burst_len_p(axi_burst_len_p)
    ,.axi_burst_type_p(axi_burst_type_p)
  ) axi_tx (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.v_i(write_rr_v_lo)
    ,.yumi_o(write_rr_yumi_li)
    ,.cache_id_i(write_rr_tag_lo)
    ,.addr_i(write_rr_dma_pkt.addr)
    ,.mask_i(write_rr_dma_pkt.mask)

    ,.fence_i(w_fence_lo)

    ,.dma_data_i(dma_data_i)
    ,.dma_data_v_i(dma_data_v_i)
    ,.dma_data_yumi_o(dma_data_yumi_o)

    ,.axi_awid_o(axi_awid_o)
    ,.axi_awaddr_addr_o(axi_awaddr_addr_o)
    ,.axi_awaddr_cache_id_o(axi_awaddr_cache_id_o)
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
  );

  // ordering
  //
  if(ordering_en_p) begin: ordering
    bsg_cache_to_axi_ordering #(
      .num_cache_p(num_cache_p)
      ,.addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.mask_width_p(mask_width_p)
      ,.block_size_in_words_p(block_size_in_words_p)
      ,.tag_fifo_els_p(tag_fifo_els_p)
      ,.axi_id_width_p(axi_id_width_p)
      ,.axi_data_width_p(axi_data_width_p)
      ,.axi_burst_len_p(axi_burst_len_p)
      ,.axi_burst_type_p(axi_burst_type_p)
    ) axi_ordering (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
  
      ,.r_v_i(read_rr_v_lo)
      ,.r_addr_i(read_rr_dma_pkt.addr)
      ,.r_fence_o(r_fence_lo)
  
      ,.w_v_i(write_rr_v_lo)
      ,.w_addr_i(write_rr_dma_pkt.addr)
      ,.w_fence_o(w_fence_lo)
  
      ,.axi_awvalid_i(axi_awvalid_o)
      ,.axi_awready_i(axi_awready_i)
      ,.axi_bvalid_i(axi_bvalid_i)
      ,.axi_bready_i(axi_bready_o)
  
      ,.axi_arvalid_i(axi_arvalid_o)
      ,.axi_arready_i(axi_arready_i)
      ,.axi_rlast_i(axi_rlast_i)
      ,.axi_rvalid_i(axi_rvalid_i)
      ,.axi_rready_i(axi_rready_o)
    );
  end
  else begin: noordering
    assign r_fence_lo = 1'b0;
    assign w_fence_lo = 1'b0;
  end

  // assertions
  //
`ifndef BSG_HIDE_FROM_SYNTHESIS
  initial begin
    assert(data_width_p*block_size_in_words_p == axi_data_width_p*axi_burst_len_p)
      else $error("cache block size and axi transfer size do not match.");
  end
`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_cache_to_axi)
