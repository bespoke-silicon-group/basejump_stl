/**
 *  testbench.sv
 */

`include "bsg_cache.svh"

module testbench();
  import bsg_cache_pkg::*;
  import bsg_axi_pkg::*;

  // parameters
  //

  parameter addr_width_p = 5;
  parameter data_width_p = 8;
  parameter block_width_p = 32;

  parameter ring_width_p = data_width_p;
  parameter rom_addr_width_p = 32;

  parameter wrap_type_p = e_axi_burst_wrap;

  // clock and reset
  //
  bit clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(100)
  ) clock_gen (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(1)
    ,.reset_cycles_hi_p(100)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  // trace_replay
  //
  logic [rom_addr_width_p-1:0] trace_rom_addr;
  logic [ring_width_p+4-1:0] trace_rom_data;

  logic [ring_width_p-1:0] tr_data_li, tr_data_lo;
  logic tr_v_li, tr_ready_lo;
  logic tr_v_lo, tr_yumi_li;
  logic done;

  bsg_trace_replay #(
    .payload_width_p(ring_width_p)
    ,.rom_addr_width_p(rom_addr_width_p)
  ) trace_replay (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.en_i(1'b1)

    ,.v_i(tr_v_li)
    ,.data_i(tr_data_li)
    ,.ready_o(tr_ready_lo)

    ,.v_o(tr_v_lo)
    ,.data_o(tr_data_lo)
    ,.yumi_i(tr_yumi_li)

    ,.rom_addr_o(trace_rom_addr)
    ,.rom_data_i(trace_rom_data)

    ,.done_o(done)
    ,.error_o()
  ); 

  bsg_trace_rom #(
    .width_p(ring_width_p+4)
    ,.addr_width_p(rom_addr_width_p)
  ) trace_rom (
    .addr_i(trace_rom_addr)
    ,.data_o(trace_rom_data)
  );

  // cache dma
  //
  `declare_bsg_cache_dma_pkt_s(addr_width_p, block_width_p/data_width_p);
  bsg_cache_dma_pkt_s dma_pkt_lo;
  logic dma_pkt_v_lo, dma_pkt_yumi_li;

  logic [data_width_p-1:0] dma_data_li;
  logic dma_data_v_li, dma_data_ready_and_lo;

  logic [data_width_p-1:0] dma_data_lo;
  logic dma_data_v_lo, dma_data_yumi_li;

  wire            pkt_not_data = tr_data_lo[addr_width_p+1];
  wire               wr_not_rd = tr_data_lo[addr_width_p];
  wire [addr_width_p-1:0] addr = tr_data_lo[0+:addr_width_p];

  assign dma_pkt_lo    = '{write_not_read: wr_not_rd, addr: addr, mask: '1};
  assign dma_data_lo   = tr_data_lo;
  assign dma_pkt_v_lo  = tr_v_lo & pkt_not_data;
  assign dma_data_v_lo = tr_v_lo & ~pkt_not_data;
  assign tr_yumi_li    = tr_v_lo & (dma_pkt_yumi_li | dma_data_yumi_li);

  assign tr_v_li           = dma_data_v_li;
  assign tr_data_li        = dma_data_li;
  assign dma_data_ready_and_lo = tr_ready_lo;

  logic [6-1:0] axi_awid;
  logic [addr_width_p-1:0] axi_awaddr;
  logic [7:0] axi_awlen;
  logic [2:0] axi_awsize;
  logic [1:0] axi_awburst;
  logic [3:0] axi_awcache;
  logic [2:0] axi_awprot;
  logic axi_awlock, axi_awvalid, axi_awready;

  logic [data_width_p-1:0] axi_wdata;
  logic [(data_width_p>>3)-1:0] axi_wstrb;
  logic axi_wlast, axi_wvalid, axi_wready;

  logic [6-1:0] axi_bid;
  logic [1:0] axi_bresp;
  logic axi_bvalid, axi_bready;

  logic [6-1:0] axi_arid;
  logic [addr_width_p-1:0] axi_araddr;
  logic [7:0] axi_arlen;
  logic [2:0] axi_arsize;
  logic [1:0] axi_arburst;
  logic [3:0] axi_arcache;
  logic [2:0] axi_arprot;
  logic axi_arlock, axi_arvalid, axi_arready;

  logic [6-1:0] axi_rid;
  logic [data_width_p-1:0] axi_rdata;
  logic [1:0] axi_rresp;
  logic axi_rlast, axi_rvalid, axi_rready;

  bsg_cache_to_axi
   #(.addr_width_p(addr_width_p)
     ,.data_width_p(data_width_p)
     ,.block_size_in_words_p(block_width_p/data_width_p)
     ,.mask_width_p(block_width_p/data_width_p)
     ,.num_cache_p(1)
     ,.axi_id_width_p(6)
     ,.axi_data_width_p(data_width_p)
     ,.axi_burst_len_p(block_width_p/data_width_p)
     ,.axi_burst_type_p(wrap_type_p)
     ,.ordering_en_p(1)
     )
  cache2axi
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.dma_pkt_i(dma_pkt_lo)
     ,.dma_pkt_v_i(dma_pkt_v_lo)
     ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

     ,.dma_data_o(dma_data_li)
     ,.dma_data_v_o(dma_data_v_li)
     ,.dma_data_ready_and_i(dma_data_ready_and_lo)

     ,.dma_data_i(dma_data_lo)
     ,.dma_data_v_i(dma_data_v_lo)
     ,.dma_data_yumi_o(dma_data_yumi_li)

     ,.axi_awid_o(axi_awid)
     ,.axi_awaddr_addr_o(axi_awaddr)
     ,.axi_awlen_o(axi_awlen)
     ,.axi_awsize_o(axi_awsize)
     ,.axi_awburst_o(axi_awburst)
     ,.axi_awcache_o(axi_awcache)
     ,.axi_awprot_o(axi_awprot)
     ,.axi_awlock_o(axi_awlock)
     ,.axi_awvalid_o(axi_awvalid)
     ,.axi_awready_i(axi_awready)

     ,.axi_wdata_o(axi_wdata)
     ,.axi_wstrb_o(axi_wstrb)
     ,.axi_wlast_o(axi_wlast)
     ,.axi_wvalid_o(axi_wvalid)
     ,.axi_wready_i(axi_wready)

     ,.axi_bid_i(axi_bid)
     ,.axi_bresp_i(axi_bresp)
     ,.axi_bvalid_i(axi_bvalid)
     ,.axi_bready_o(axi_bready)
     ,.axi_arid_o(axi_arid)
     ,.axi_araddr_addr_o(axi_araddr)
     ,.axi_arlen_o(axi_arlen)
     ,.axi_arsize_o(axi_arsize)
     ,.axi_arburst_o(axi_arburst)
     ,.axi_arcache_o(axi_arcache)
     ,.axi_arprot_o(axi_arprot)
     ,.axi_arlock_o(axi_arlock)
     ,.axi_arvalid_o(axi_arvalid)
     ,.axi_arready_i(axi_arready)

     ,.axi_rid_i(axi_rid)
     ,.axi_rdata_i(axi_rdata)
     ,.axi_rresp_i(axi_rresp)
     ,.axi_rlast_i(axi_rlast)
     ,.axi_rvalid_i(axi_rvalid)
     ,.axi_rready_o(axi_rready)

     // Unused
     ,.axi_awaddr_cache_id_o()
     ,.axi_araddr_cache_id_o()
     );

  bsg_nonsynth_axi_mem
   #(.axi_id_width_p(6)
     ,.axi_addr_width_p(addr_width_p)
     ,.axi_data_width_p(data_width_p)
     ,.axi_len_width_p(8)
     ,.mem_els_p(32)
     ,.init_data_p('0)
     ,.rd_delay_p(0)
     ,.wr_delay_p(8)
     )
   axi_mem
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.axi_awid_i(axi_awid)
     ,.axi_awaddr_i(axi_awaddr)
     ,.axi_awvalid_i(axi_awvalid)
     ,.axi_awready_o(axi_awready)
     ,.axi_awburst_i(axi_awburst)
     ,.axi_awlen_i(axi_awlen)

     ,.axi_wdata_i(axi_wdata)
     ,.axi_wstrb_i(axi_wstrb)
     ,.axi_wlast_i(axi_wlast)
     ,.axi_wvalid_i(axi_wvalid)
     ,.axi_wready_o(axi_wready)

     ,.axi_bid_o(axi_bid)
     ,.axi_bresp_o(axi_bresp)
     ,.axi_bvalid_o(axi_bvalid)
     ,.axi_bready_i(axi_bready)

     ,.axi_arid_i(axi_arid)
     ,.axi_araddr_i(axi_araddr)
     ,.axi_arburst_i(axi_arburst)
     ,.axi_arlen_i(axi_arlen)
     ,.axi_arvalid_i(axi_arvalid)
     ,.axi_arready_o(axi_arready)

     ,.axi_rid_o(axi_rid)
     ,.axi_rdata_o(axi_rdata)
     ,.axi_rresp_o(axi_rresp)
     ,.axi_rlast_o(axi_rlast)
     ,.axi_rvalid_o(axi_rvalid)
     ,.axi_rready_i(axi_rready)
     );
 
  initial begin
    wait(done)
    //for (integer i = 0; i < 100000; i++) begin
    //  @(posedge clk);
    //end
    $display("[BSG_FINISH] Test Successful.");
    $finish;
  end

endmodule
