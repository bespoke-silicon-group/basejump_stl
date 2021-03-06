
`include "bsg_noc_links.vh"

module testbench;

  import bsg_cache_pkg::*;

  // clock/reset
  bit clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(20)
  ) cg (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(10)
  ) rg (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  // TB Parameters
  localparam mem_size_p = 2**17;
  parameter addr_width_p = 32;
  parameter data_width_p = 32;
  parameter block_size_in_words_p = 8;
  parameter sets_p = 512;
  parameter ways_p = `WAYS_P;

  parameter ring_width_p = `bsg_cache_pkt_width(addr_width_p, data_width_p);
  parameter rom_addr_width_p = 32;

  // DUT Parameters
  localparam wh_flit_width_p=32;
  localparam wh_cid_width_p=1;
  localparam wh_cord_width_p=1;
  localparam wh_len_width_p=3;
  localparam num_dma_p=1;
  localparam addr_width_p=wh_flit_width_p;
  localparam data_width_p=wh_flit_width_p;
  localparam dma_data_width_p=data_width_p;
  localparam data_len_p=block_size_in_words_p*data_width_p/dma_data_width_p;

  `declare_bsg_cache_pkt_s(addr_width_p,data_width_p);
  bsg_cache_pkt_s cache_pkt_li;
  logic ready_lo, v_li;
  logic [data_width_p-1:0] cache_data_lo;
  logic v_lo, yumi_li;

  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s dma_pkt_lo;
  logic dma_pkt_v_lo, dma_pkt_yumi_li;
  logic [wh_flit_width_p-1:0] dma_data_li;
  logic dma_data_v_li, dma_data_ready_lo;
  logic [dma_data_width_p-1:0] dma_data_lo;
  logic dma_data_v_lo, dma_data_yumi_li;
  bsg_cache #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.sets_p(sets_p)
    ,.ways_p(ways_p)
  ) cache (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.cache_pkt_i(cache_pkt_li)
    ,.v_i(v_li)
    ,.ready_o(ready_lo)

    ,.data_o(cache_data_lo)
    ,.v_o(v_lo)
    ,.yumi_i(yumi_li)

    ,.dma_pkt_o(dma_pkt_lo)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)

    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_o(dma_data_ready_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)

    ,.v_we_o()
  );

  `declare_bsg_ready_and_link_sif_s(wh_flit_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s wh_link_sif_li, wh_link_sif_lo;
  bsg_cache_dma_to_wormhole #(
     .addr_width_p(addr_width_p)
     ,.data_len_p(data_len_p)
     ,.wh_flit_width_p(wh_flit_width_p)
     ,.wh_cid_width_p(wh_cid_width_p)
     ,.wh_cord_width_p(wh_cord_width_p)
     ,.wh_len_width_p(wh_len_width_p)
   ) dma2wh (
     .clk_i(clk)
     ,.reset_i(reset)

     ,.dma_pkt_i(dma_pkt_lo)
     ,.dma_pkt_v_i(dma_pkt_v_lo)
     ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

     ,.dma_data_o(dma_data_li)
     ,.dma_data_v_o(dma_data_v_li)
     ,.dma_data_ready_i(dma_data_ready_lo)

     ,.dma_data_i(dma_data_lo)
     ,.dma_data_v_i(dma_data_v_lo)
     ,.dma_data_yumi_o(dma_data_yumi_li)

     ,.wh_link_sif_i(wh_link_sif_li)
     ,.wh_link_sif_o(wh_link_sif_lo)

     ,.my_wh_cord_i('0)
     ,.dest_wh_cord_i('1)
     ,.my_wh_cid_i('0)
     );

  bsg_cache_dma_pkt_s mem_dma_pkt_lo;
  logic mem_dma_pkt_v_lo, mem_dma_pkt_yumi_li;
  logic [wh_flit_width_p-1:0] mem_dma_data_li;
  logic mem_dma_data_v_li, mem_dma_data_ready_lo;
  logic [dma_data_width_p-1:0] mem_dma_data_lo;
  logic mem_dma_data_v_lo, mem_dma_data_yumi_li;
  wire [`BSG_SAFE_CLOG2(num_dma_p)-1:0] wh_dma_id_li;
  bsg_wormhole_to_cache_dma #(
     .addr_width_p(addr_width_p)
     ,.num_dma_p(num_dma_p)
     ,.data_len_p(data_len_p)
     ,.wh_flit_width_p(wh_flit_width_p)
     ,.wh_cid_width_p(wh_cid_width_p)
     ,.wh_cord_width_p(wh_cord_width_p)
     ,.wh_len_width_p(wh_len_width_p)
   ) wh2dma (
     .clk_i(clk)
     ,.reset_i(reset)

     ,.wh_link_sif_i(wh_link_sif_lo)
     ,.wh_dma_id_i('0)
     ,.wh_link_sif_o(wh_link_sif_li)

     ,.dma_pkt_o(mem_dma_pkt_lo)
     ,.dma_pkt_v_o(mem_dma_pkt_v_lo)
     ,.dma_pkt_yumi_i(mem_dma_pkt_yumi_li)

     ,.dma_data_i(mem_dma_data_li)
     ,.dma_data_v_i(mem_dma_data_v_li)
     ,.dma_data_ready_o(mem_dma_data_ready_lo)

     ,.dma_data_o(mem_dma_data_lo)
     ,.dma_data_v_o(mem_dma_data_v_lo)
     ,.dma_data_yumi_i(mem_dma_data_yumi_li)
  );

  bsg_nonsynth_dma_model #(
    .addr_width_p(addr_width_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.els_p(mem_size_p)

    ,.read_delay_p(`DMA_READ_DELAY_P)
    ,.write_delay_p(`DMA_WRITE_DELAY_P)
    ,.dma_req_delay_p(`DMA_REQ_DELAY_P)
    ,.dma_data_delay_p(`DMA_DATA_DELAY_P)
  ) dma0 (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.dma_pkt_i(mem_dma_pkt_lo)
    ,.dma_pkt_v_i(mem_dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(mem_dma_pkt_yumi_li)

    ,.dma_data_o(mem_dma_data_li)
    ,.dma_data_v_o(mem_dma_data_v_li)
    ,.dma_data_ready_i(mem_dma_data_ready_lo)

    ,.dma_data_i(mem_dma_data_lo)
    ,.dma_data_v_i(mem_dma_data_v_lo)
    ,.dma_data_yumi_o(mem_dma_data_yumi_li)
  );

  initial begin
    cache_pkt_li = '0;
    v_li = '0;
    yumi_li = '0;

    @(posedge clk);
    @(negedge reset);
    @(posedge clk);
    v_li = 1'b1;
    cache_pkt_li = '{opcode: LW, addr: '0, data: '0, mask: '1};
    
    @(posedge v_lo);
    yumi_li = v_lo;;
    @(posedge clk);

  end


endmodule

