/**
 *  testbench.v
 */

`include "bsg_cache_pkt.vh"
`include "bsg_cache_dma_pkt.vh"

module testbench();

  // parameters
  //
  parameter num_cache_p = 4;
  parameter data_width_p = 32;
  parameter addr_width_p = 32;
  parameter block_size_in_words_p = 16;
  parameter sets_p = 16;
  parameter lo_addr_width_p = 10;

  parameter axi_id_width_p = 4;
  parameter axi_addr_width_p = 32;
  parameter axi_data_width_p = 256;
  parameter axi_burst_len_p = 2;
  parameter axi_strb_width_lp = (axi_data_width_p>>3);

  // clock and reset
  //
  logic clk;
  logic reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(10)
  ) clock_gen (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(4)
    ,.reset_cycles_hi_p(4)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
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
    ) master (
      .clk_i(clk)
      ,.reset_i(reset)
  
      ,.cache_pkt_o(cache_pkt[i])
      ,.v_o(v_lo[i])
      ,.ready_i(ready_li[i])   

      ,.data_i(data_li[i])
      ,.v_i(v_li[i])
      ,.yumi_o(yumi_lo[i]) 
      
      ,.done_o(done_lo[i])
    );
  end

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
      .clk_i(clk)
      ,.reset_i(reset)
      
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
  logic [axi_id_width_p-1:0] awid;
  logic [axi_addr_width_p-1:0] awaddr;
  logic [7:0] awlen;
  logic [2:0] awsize;
  logic [1:0] awburst;
  logic [3:0] awcache;
  logic [2:0] awprot;
  logic [1:0] awlock;
  logic awvalid;
  logic awready;

  logic [axi_data_width_p-1:0] wdata;
  logic [axi_strb_width_lp-1:0] wstrb;
  logic wlast;
  logic wvalid;
  logic wready;

  logic [axi_id_width_p-1:0] bid;
  logic [1:0] bresp;
  logic bvalid;
  logic bready;

  logic [axi_id_width_p-1:0] arid;
  logic [axi_addr_width_p-1:0] araddr;
  logic [7:0] arlen;
  logic [2:0] arsize;
  logic [1:0] arburst;
  logic [3:0] arcache;
  logic [2:0] arprot;
  logic [1:0] arlock;
  logic arvalid;
  logic arready;

  logic [axi_id_width_p-1:0] rid;
  logic [axi_data_width_p-1:0] rdata;
  logic [1:0] rresp;
  logic rlast;
  logic rvalid;
  logic rready;

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
    .clk_i(clk)
    ,.reset_i(reset)

    ,.dma_pkt_i(dma_pkt)
    ,.dma_pkt_v_i(dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

    ,.dma_data_o(dma_data_li)
    ,.dma_data_v_o(dma_data_v_li)
    ,.dma_data_ready_i(dma_data_ready_lo)

    ,.dma_data_i(dma_data_lo)
    ,.dma_data_v_i(dma_data_v_lo)
    ,.dma_data_yumi_o(dma_data_yumi_li)

    ,.axi_awid_o(awid)
    ,.axi_awaddr_o(awaddr)
    ,.axi_awlen_o(awlen)
    ,.axi_awsize_o(awsize)
    ,.axi_awburst_o(awburst)
    ,.axi_awcache_o(awcache)
    ,.axi_awprot_o(awprot)
    ,.axi_awlock_o(awlock)
    ,.axi_awvalid_o(awvalid)
    ,.axi_awready_i(awready)

    ,.axi_wdata_o(wdata)
    ,.axi_wstrb_o(wstrb)
    ,.axi_wlast_o(wlast)
    ,.axi_wvalid_o(wvalid)
    ,.axi_wready_i(wready)

    ,.axi_bid_i(bid)
    ,.axi_bresp_i(bresp)
    ,.axi_bvalid_i(bvalid)
    ,.axi_bready_o(bready)

    ,.axi_arid_o(arid)
    ,.axi_araddr_o(araddr)
    ,.axi_arlen_o(arlen)
    ,.axi_arsize_o(arsize)
    ,.axi_arburst_o(arburst)
    ,.axi_arcache_o(arcache)
    ,.axi_arprot_o(arprot)
    ,.axi_arlock_o(arlock)
    ,.axi_arvalid_o(arvalid)
    ,.axi_arready_i(arready)

    ,.axi_rid_i(rid)
    ,.axi_rdata_i(rdata)
    ,.axi_rresp_i(rresp)
    ,.axi_rlast_i(rlast)
    ,.axi_rvalid_i(rvalid)
    ,.axi_rready_o(rready)
  );

  // AXI BRAM
  //
  axi_bram_ctrl_v4_0_14 #(
    .C_BRAM_INST_MODE("INTERNAL")
  ) axi_bram (
    .s_axi_aclk(clk)
    ,.s_axi_aresetn(~reset)
    
    ,.s_axi_awid(awid)
    ,.s_axi_awaddr(awaddr)
    ,.s_axi_awlen(awlen)
    ,.s_axi_awsize(awsize)
    ,.s_axi_awburst(awburst)
    ,.s_axi_awlock(awlock)
    ,.s_axi_awcache(awcache)
    ,.s_axi_awprot(awprot)
    ,.s_axi_awvalid(awvalid)
    ,.s_axi_awready(awready)

    ,.s_axi_wdata(wdata)
    ,.s_axi_wstrb(wstrb)
    ,.s_axi_wlast(wlast)
    ,.s_axi_wvalid(wvalid)
    ,.s_axi_wready(wready)

    ,.s_axi_bid(bid)
    ,.s_axi_bresp(bresp)
    ,.s_axi_bvalid(bvalid)
    ,.s_axi_bready(bready)

    ,.s_axi_arid(arid)
    ,.s_axi_araddr(araddr)
    ,.s_axi_arlen(arsize)
    ,.s_axi_arsize(arsize)
    ,.s_axi_arburst(arburst)
    ,.s_axi_arlock(arlock)
    ,.s_axi_arcache(arcache)
    ,.s_axi_arprot(arprot)
    ,.s_axi_arvalid(arvalid)
    ,.s_axi_arready(arready)

    ,.s_axi_rid(rid)
    ,.s_axi_rdata(rdata)
    ,.s_axi_rresp(rresp)
    ,.s_axi_rlast(rlast)
    ,.s_axi_rvalid(rvalid)
    ,.s_axi_rready(rready)
  );

  initial begin
    wait(&done_lo);
    $finish;
  end

endmodule
