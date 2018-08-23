/**
 *  mesh_top_cache.v
 */

`include "bsg_manycore_packet.vh"

module mesh_top_cache
  import bsg_cache_pkg::*;
  #(parameter x_cord_width_p="inv"
    ,parameter y_cord_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter dram_data_width_p="inv"
    ,parameter link_addr_width_lp=32-1-x_cord_width_p-y_cord_width_p // remote addr width
    ,parameter sets_p="inv"
    ,parameter mem_size_p="inv"
    ,parameter packet_width_lp=`bsg_manycore_packet_width(link_addr_width_lp,data_width_p,x_cord_width_p,y_cord_width_p)
    ,parameter return_packet_width_lp=`bsg_manycore_return_packet_width(x_cord_width_p,y_cord_width_p,data_width_p)
    ,parameter link_sif_width_lp=`bsg_manycore_link_sif_width(link_addr_width_lp,data_width_p,x_cord_width_p,y_cord_width_p)
    ,parameter cache_addr_width_lp=`BSG_SAFE_CLOG2(2-1)+link_addr_width_lp+`BSG_SAFE_CLOG2(data_width_p>>3)
)
(
  input clock_i
  ,input reset_i

  ,bsg_dram_ctrl_if.master dram_ctrl_if

  ,output logic finish_o
);

  localparam nodes_lp = 2;

  logic [nodes_lp-1:0][bsg_noc_pkg::S:bsg_noc_pkg::W][link_sif_width_lp-1:0] router_link_sif_li, router_link_sif_lo;
  logic [nodes_lp-1:0][link_sif_width_lp-1:0] proc_link_sif_li, proc_link_sif_lo;

  genvar i, j;
  for (i = 0; i < nodes_lp; i++) begin
    bsg_manycore_mesh_node #(
      .stub_p(4'b0)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.data_width_p(data_width_p)
      ,.addr_width_p(link_addr_width_lp)  
    ) mesh_node (
      .clk_i(clock_i)
      ,.reset_i(reset_i)
      ,.links_sif_i(router_link_sif_li[i])
      ,.links_sif_o(router_link_sif_lo[i])
      ,.proc_link_sif_i(proc_link_sif_lo[i])
      ,.proc_link_sif_o(proc_link_sif_li[i])
      ,.my_x_i(x_cord_width_p'(i))
      ,.my_y_i(y_cord_width_p'(0))
    );
  end 

  assign router_link_sif_li[0][bsg_noc_pkg::E] = router_link_sif_lo[1][bsg_noc_pkg::W];
  assign router_link_sif_li[1][bsg_noc_pkg::W] = router_link_sif_lo[0][bsg_noc_pkg::E];

  mesh_master_cache #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.data_width_p(data_width_p)
    ,.addr_width_p(link_addr_width_lp)
    ,.sets_p(sets_p)
    ,.ways_p(2)
    ,.mem_size_p(mem_size_p)
  ) master (
    .clock_i(clock_i)
    ,.reset_i(reset_i)

    ,.link_sif_i(proc_link_sif_li[0])
    ,.link_sif_o(proc_link_sif_lo[0])
    
    ,.my_x_i(x_cord_width_p'(0))
    ,.my_y_i(y_cord_width_p'(0))
  
    ,.finish_o(finish_o)
  );

  // tieoff
  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node00_w_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(router_link_sif_lo[0][bsg_noc_pkg::W])
    ,.link_sif_o(router_link_sif_li[0][bsg_noc_pkg::W])
  );

  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node00_n_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(router_link_sif_lo[0][bsg_noc_pkg::N])
    ,.link_sif_o(router_link_sif_li[0][bsg_noc_pkg::N])
  );

  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node11_n_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(router_link_sif_lo[1][bsg_noc_pkg::N])
    ,.link_sif_o(router_link_sif_li[1][bsg_noc_pkg::N])
  );

  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node11_e_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(router_link_sif_lo[1][bsg_noc_pkg::E])
    ,.link_sif_o(router_link_sif_li[1][bsg_noc_pkg::E])
  );

  bsg_manycore_link_sif_tieoff #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
  ) node01_p_tieoff (
    .clk_i(clock_i)
    ,.reset_i(reset_i)
    ,.link_sif_i(proc_link_sif_li[1])
    ,.link_sif_o(proc_link_sif_lo[1])
  );

  // cache-side signals
  //
  `declare_bsg_cache_pkt_s(cache_addr_width_lp, data_width_p);
  bsg_cache_pkt_s cache_packet;
  logic links_to_cache_v_lo;
  logic links_to_cache_yumi_lo;
  logic cache_ready_lo;
  logic [data_width_p-1:0] cache_data_lo;
  logic cache_v_lo;
  logic cache_v_v_we_lo;

  logic dma_req_ch_write_not_read;
  logic [cache_addr_width_lp-1:0] dma_req_ch_addr;
  logic dma_req_ch_v;
  logic dma_req_ch_yumi;

  logic dma_read_ch_ready;
  logic [data_width_p-1:0] dma_read_ch_data;
  logic dma_read_ch_v;
  
  logic [data_width_p-1:0] dma_write_ch_data;
  logic dma_write_ch_v;
  logic dma_write_ch_yumi;

  // links_to_cache
  //
  bsg_manycore_links_to_cache #(
    .addr_width_p(link_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.num_links_p(nodes_lp)
  ) links_to_cache (
    .clock_i(clock_i)
    ,.reset_i(reset_i)
    ,.my_x_i({(x_cord_width_p)'(1), (x_cord_width_p)'(0)})
    ,.my_y_i({(y_cord_width_p)'(1), (y_cord_width_p)'(1)})
    ,.links_sif_i({router_link_sif_lo[1][bsg_noc_pkg::S], router_link_sif_lo[0][bsg_noc_pkg::S]})
    ,.links_sif_o({router_link_sif_li[1][bsg_noc_pkg::S], router_link_sif_li[0][bsg_noc_pkg::S]})

    ,.packet_o(cache_packet)
    ,.v_o(links_to_cache_v_lo)
    ,.ready_i(cache_ready_lo)

    ,.data_i(cache_data_lo)
    ,.v_i(cache_v_lo)
    ,.yumi_o(links_to_cache_yumi_lo)

    ,.v_v_we_i(cache_v_v_we_lo)
  ); 
  
  // cache
  //
  bsg_cache #(
    .addr_width_p(cache_addr_width_lp)
    ,.block_size_in_words_p(8)
    ,.sets_p(sets_p)
  ) cache (
    .clock_i(clock_i)
    ,.reset_i(reset_i)

    ,.packet_i(cache_packet)
    ,.v_i(links_to_cache_v_lo)
    ,.ready_o(cache_ready_lo)

    ,.data_o(cache_data_lo)
    ,.v_o(cache_v_lo)
    ,.yumi_i(links_to_cache_yumi_lo)

    ,.v_v_we_o(cache_v_v_we_lo)

    ,.dma_req_ch_write_not_read_o(dma_req_ch_write_not_read)
    ,.dma_req_ch_addr_o(dma_req_ch_addr)
    ,.dma_req_ch_v_o(dma_req_ch_v)
    ,.dma_req_ch_yumi_i(dma_req_ch_yumi)

    ,.dma_read_ch_data_i(dma_read_ch_data)
    ,.dma_read_ch_v_i(dma_read_ch_v)
    ,.dma_read_ch_ready_o(dma_read_ch_ready)

    ,.dma_write_ch_data_o(dma_write_ch_data)
    ,.dma_write_ch_v_o(dma_write_ch_v)
    ,.dma_write_ch_yumi_i(dma_write_ch_yumi)
  );
  

  // cache to dram_ctrl
  //
  bsg_cache_to_dram_ctrl #(
    .addr_width_p(cache_addr_width_lp)
    ,.block_size_in_words_p(8)
    ,.cache_word_width_p(data_width_p)
    ,.burst_len_p(1)
    ,.burst_width_p(dram_data_width_p)
  ) cache_to_dram_ctrl (
    .clock_i(clock_i)
    ,.reset_i(reset_i)

    ,.dma_req_ch_write_not_read_i(dma_req_ch_write_not_read)
    ,.dma_req_ch_addr_i(dma_req_ch_addr)
    ,.dma_req_ch_v_i(dma_req_ch_v)
    ,.dma_req_ch_yumi_o(dma_req_ch_yumi)

    ,.dma_read_ch_data_o(dma_read_ch_data)
    ,.dma_read_ch_v_o(dma_read_ch_v)
    ,.dma_read_ch_ready_i(dma_read_ch_ready)

    ,.dma_write_ch_data_i(dma_write_ch_data)
    ,.dma_write_ch_v_i(dma_write_ch_v)
    ,.dma_write_ch_yumi_o(dma_write_ch_yumi)

    ,.dram_ctrl_if(dram_ctrl_if)
  );
  
endmodule
