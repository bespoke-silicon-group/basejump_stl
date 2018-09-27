/**
 *  mesh_top_cache.v
 */

`include "bsg_manycore_packet.vh"
`include "bsg_cache_dma_pkt.vh"

module mesh_top_cache
  import bsg_cache_pkg::*;
  import bsg_dram_ctrl_pkg::*;
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
    ,parameter cache_addr_width_lp=link_addr_width_lp+`BSG_SAFE_CLOG2(data_width_p>>3)
)
(
  input clk_i
  ,input reset_i

  ,output logic finish_o

  ,output logic app_en_o
  ,input app_rdy_i
  ,output logic app_hi_pri_o
  ,output eAppCmd app_cmd_o
  ,output logic [29:0] app_addr_o

  ,output logic app_wdf_wren_o
  ,input app_wdf_rdy_i
  ,output logic [dram_data_width_p-1:0] app_wdf_data_o
  ,output logic [(dram_data_width_p>>3)-1:0] app_wdf_mask_o
  ,output logic app_wdf_end_o

  ,input app_rd_data_valid_i
  ,input [dram_data_width_p-1:0] app_rd_data_i
  ,input app_rd_data_end_i

  ,output logic app_ref_req_o
  ,input app_ref_ack_i

  ,output logic app_zq_req_o
  ,input app_zq_ack_i
  ,input init_calib_complete_i

  ,output logic app_sr_req_o
  ,input app_sr_ack_i
);

  localparam nodes_lp = 4;
  localparam block_size_in_words_lp = 8;

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
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.links_sif_i(router_link_sif_li[i])
      ,.links_sif_o(router_link_sif_lo[i])
      ,.proc_link_sif_i(proc_link_sif_lo[i])
      ,.proc_link_sif_o(proc_link_sif_li[i])
      ,.my_x_i(x_cord_width_p'(i))
      ,.my_y_i(y_cord_width_p'(0))
    );
    if (i != nodes_lp-1) begin
      assign router_link_sif_li[i][bsg_noc_pkg::E] = router_link_sif_lo[i+1][bsg_noc_pkg::W];
    end
    if (i != 0) begin
      assign router_link_sif_li[i][bsg_noc_pkg::W] = router_link_sif_lo[i-1][bsg_noc_pkg::E];
    end
  end 

 
  logic [nodes_lp-1:0] master_finish; 
  for (i = 0; i < nodes_lp; i++) begin
    mesh_master_cache #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.data_width_p(data_width_p)
      ,.addr_width_p(link_addr_width_lp)
      ,.sets_p(sets_p)
      ,.mem_size_p(mem_size_p)
      ,.id_p(i)
      ,.block_size_in_words_p(block_size_in_words_lp)
    ) master (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.link_sif_i(proc_link_sif_li[i])
      ,.link_sif_o(proc_link_sif_lo[i])
    
      ,.my_x_i(x_cord_width_p'(i))
      ,.my_y_i(y_cord_width_p'(0))
      
      ,.dest_x_i(x_cord_width_p'(i))
      ,.dest_y_i(y_cord_width_p'(1)) 
 
      ,.finish_o(master_finish[i])
    );
  end

  assign finish_o = &master_finish;

  // tieoff
  for (i = 0; i < nodes_lp; i++) begin
    if (i == 0) begin
      bsg_manycore_link_sif_tieoff #(
        .addr_width_p(link_addr_width_lp)
        ,.data_width_p(data_width_p)
        ,.x_cord_width_p(x_cord_width_p)
        ,.y_cord_width_p(y_cord_width_p)
      ) node_w_tieoff (
        .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.link_sif_i(router_link_sif_lo[0][bsg_noc_pkg::W])
        ,.link_sif_o(router_link_sif_li[0][bsg_noc_pkg::W])
      );
    end

    bsg_manycore_link_sif_tieoff #(
      .addr_width_p(link_addr_width_lp)
      ,.data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
    ) node_n_tieoff (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::N])
      ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::N])
    );
  
    if (i == nodes_lp-1) begin
      bsg_manycore_link_sif_tieoff #(
        .addr_width_p(link_addr_width_lp)
        ,.data_width_p(data_width_p)
        ,.x_cord_width_p(x_cord_width_p)
        ,.y_cord_width_p(y_cord_width_p)
      ) node_e_tieoff (
        .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::E])
        ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::E])
      );
    end

  end

  // cache-side signals
  //
  `declare_bsg_cache_pkt_s(cache_addr_width_lp, data_width_p);
  bsg_cache_pkt_s [nodes_lp-1:0] cache_pkt;
  logic [nodes_lp-1:0] link_to_cache_v_lo;
  logic [nodes_lp-1:0] link_to_cache_yumi_lo;
  logic [nodes_lp-1:0] cache_ready_lo;
  logic [nodes_lp-1:0] [data_width_p-1:0] cache_data_lo;
  logic [nodes_lp-1:0] cache_v_lo;
  logic [nodes_lp-1:0] cache_v_we_lo;

  // link_to_cache
  //
  for (i = 0; i < nodes_lp; i++) begin
    bsg_manycore_link_to_cache #(
      .addr_width_p(link_addr_width_lp)
      ,.data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.sets_p(sets_p)
      ,.block_size_in_words_p(block_size_in_words_lp)
    ) link_to_cache (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.my_x_i((x_cord_width_p)'(i))
      ,.my_y_i((y_cord_width_p)'(1))
      ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::S])
      ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::S])

      ,.cache_pkt_o(cache_pkt[i])
      ,.v_o(link_to_cache_v_lo[i])
      ,.ready_i(cache_ready_lo[i])

      ,.data_i(cache_data_lo[i])
      ,.v_i(cache_v_lo[i])
      ,.yumi_o(link_to_cache_yumi_lo[i])

      ,.v_we_i(cache_v_we_lo[i])
    );
  end

  // cache
  //
  `declare_bsg_cache_dma_pkt_s(cache_addr_width_lp);
  bsg_cache_dma_pkt_s [nodes_lp-1:0] dma_pkt;
  logic [nodes_lp-1:0] dma_pkt_v_lo;
  logic [nodes_lp-1:0] dma_pkt_yumi_li;

  logic [nodes_lp-1:0] dma_data_ready_lo;
  logic [nodes_lp-1:0] [data_width_p-1:0] dma_data_li;
  logic [nodes_lp-1:0] dma_data_v_li;
  
  logic [nodes_lp-1:0][data_width_p-1:0] dma_data_lo;
  logic [nodes_lp-1:0] dma_data_v_lo;
  logic [nodes_lp-1:0] dma_data_yumi_li;

  for (i = 0; i < nodes_lp; i++) begin
    bsg_cache #(
      .data_width_p(32)
      ,.addr_width_p(cache_addr_width_lp)
      ,.block_size_in_words_p(block_size_in_words_lp)
      ,.sets_p(sets_p)
    ) cache (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.cache_pkt_i(cache_pkt[i])
      ,.v_i(link_to_cache_v_lo[i])
      ,.ready_o(cache_ready_lo[i])

      ,.data_o(cache_data_lo[i])
      ,.v_o(cache_v_lo[i])
      ,.yumi_i(link_to_cache_yumi_lo[i])

      ,.v_we_o(cache_v_we_lo[i])

      ,.dma_pkt_o(dma_pkt[i])
      ,.dma_pkt_v_o(dma_pkt_v_lo[i])
      ,.dma_pkt_yumi_i(dma_pkt_yumi_li[i])

      ,.dma_data_i(dma_data_li[i])
      ,.dma_data_v_i(dma_data_v_li[i])
      ,.dma_data_ready_o(dma_data_ready_lo[i])

      ,.dma_data_o(dma_data_lo[i])
      ,.dma_data_v_o(dma_data_v_lo[i])
      ,.dma_data_yumi_i(dma_data_yumi_li[i])
    );
  end
  

  // cache to dram_ctrl
  //
  bsg_cache_to_dram_ctrl #(
    .data_width_p(32)
    ,.addr_width_p(cache_addr_width_lp)
    ,.block_size_in_words_p(8)
    ,.burst_len_p(1)
    ,.burst_width_p(dram_data_width_p)
    ,.num_cache_p(nodes_lp)
    ,.dram_boundary_p(2**16)
    ,.dram_addr_width_p(30)
  ) cache_to_dram_ctrl (
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

    ,.app_en_o(app_en_o)
    ,.app_rdy_i(app_rdy_i)
    ,.app_hi_pri_o(app_hi_pri_o)
    ,.app_cmd_o(app_cmd_o)
    ,.app_addr_o(app_addr_o)

    ,.app_wdf_wren_o(app_wdf_wren_o)
    ,.app_wdf_rdy_i(app_wdf_rdy_i)
    ,.app_wdf_data_o(app_wdf_data_o)
    ,.app_wdf_mask_o(app_wdf_mask_o)
    ,.app_wdf_end_o(app_wdf_end_o)

    ,.app_rd_data_valid_i(app_rd_data_valid_i)
    ,.app_rd_data_i(app_rd_data_i)
    ,.app_rd_data_end_i(app_rd_data_end_i)

    ,.app_ref_req_o(app_ref_req_o)
    ,.app_ref_ack_i(app_ref_ack_i)

    ,.app_zq_req_o(app_zq_req_o)
    ,.app_zq_ack_i(app_zq_ack_i)
    ,.init_calib_complete_i(init_calib_complete_i)

    ,.app_sr_req_o(app_sr_req_o)
    ,.app_sr_ack_i(app_sr_ack_i)
  );
  
endmodule
