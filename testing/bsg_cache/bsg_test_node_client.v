/**
 * bsg_test_node_client.v
 */

`include "bsg_cache_pkt.vh"
`include "bsg_cache_dma_pkt.vh"

module bsg_test_node_client 
  import bsg_cache_pkg::*;
  import bsg_dram_ctrl_pkg::*;
  #(parameter id_p="inv")
(
  input clk_i
  ,input reset_i
  ,input en_i

  ,input v_i
  ,input [79:0] data_i
  ,output logic ready_o

  ,output logic v_o
  ,output logic [79:0] data_o
  ,input yumi_i
);

  `declare_bsg_cache_pkt_s(32, 32);

  wire unused = en_i;
  bsg_cache_pkt_s packet;
  assign packet = data_i[73:0]; 

  `declare_bsg_cache_dma_pkt_s(32);
  bsg_cache_dma_pkt_s dma_pkt;
  logic dma_pkt_v_lo;
  logic dma_pkt_yumi_li;
  
  logic [31:0] dma_data_li;
  logic dma_data_v_li;
  logic dma_data_ready_lo;

  logic [31:0] dma_data_lo;
  logic dma_data_v_lo;
  logic dma_data_yumi_li;

 

  logic cache_v_lo;
  logic cache_yumi_li;
  logic [31:0] cache_data_lo;
  bsg_cache #(
    .addr_width_p(32)
    ,.data_width_p(32)
    ,.block_size_in_words_p(8)
    ,.sets_p(512)
  ) cache (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.cache_pkt_i(packet)
    ,.v_i(v_i)
    ,.ready_o(ready_o)

    ,.v_o(cache_v_lo)
    ,.yumi_i(cache_yumi_li)
    ,.data_o(cache_data_lo)

    ,.v_we_o()

    ,.dma_pkt_o(dma_pkt)
    ,.dma_pkt_v_o(dma_pkt_v_lo)
    ,.dma_pkt_yumi_i(dma_pkt_yumi_li)

    ,.dma_data_i(dma_data_li)
    ,.dma_data_v_i(dma_data_v_li)
    ,.dma_data_ready_o(dma_data_ready_lo)

    ,.dma_data_o(dma_data_lo)
    ,.dma_data_v_o(dma_data_v_lo)
    ,.dma_data_yumi_i(dma_data_yumi_li)
  );

  // put a big fifo at the output.
  //
  logic fifo_ready_lo;
  logic [31:0] fifo_data_lo;

  bsg_fifo_1r1w_large #(
    .width_p(32)
    ,.els_p(2**12)
  ) output_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.data_i(cache_data_lo)
    ,.v_i(cache_v_lo)
    ,.ready_o(fifo_ready_lo)
    
    ,.v_o(v_o)
    ,.data_o(fifo_data_lo)
    ,.yumi_i(yumi_i)
  );

  assign cache_yumi_li = cache_v_lo & fifo_ready_lo;
  assign data_o = {48'b0, fifo_data_lo};

  logic app_en;
  logic app_rdy;
  logic app_hi_pri;
  eAppCmd app_cmd;
  logic [31:0] app_addr;
  logic app_wdf_wren;
  logic app_wdf_rdy;
  logic [127:0] app_wdf_data;
  logic [15:0] app_wdf_mask;
  logic app_wdf_end;
  logic app_rd_data_valid;
  logic [127:0] app_rd_data;
  logic app_rd_data_end;
  logic app_ref_req;
  logic app_ref_ack;
  logic app_zq_req;
  logic app_zq_ack;
  logic init_calib_complete;
  logic app_sr_req;
  logic app_sr_ack;

  bsg_cache_to_dram_ctrl #(
    .addr_width_p(32)
    ,.block_size_in_words_p(8)
    ,.data_width_p(32)
    ,.burst_len_p(1)
    ,.burst_width_p(128)
    ,.num_cache_p(1)
    ,.dram_boundary_p(2**27)
    ,.dram_addr_width_p(32)
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
 
    ,.app_en_o(app_en)
    ,.app_rdy_i(app_rdy)
    ,.app_hi_pri_o(app_hi_pri)
    ,.app_cmd_o(app_cmd)
    ,.app_addr_o(app_addr)

    ,.app_wdf_wren_o(app_wdf_wren)
    ,.app_wdf_rdy_i(app_wdf_rdy)
    ,.app_wdf_data_o(app_wdf_data)
    ,.app_wdf_mask_o(app_wdf_mask)
    ,.app_wdf_end_o(app_wdf_end)

    ,.app_rd_data_valid_i(app_rd_data_valid)
    ,.app_rd_data_i(app_rd_data)
    ,.app_rd_data_end_i(app_rd_data_end)

    ,.app_ref_req_o(app_ref_req)
    ,.app_ref_ack_i(app_ref_ack)

    ,.app_zq_req_o(app_zq_req)
    ,.app_zq_ack_i(app_zq_ack)
    ,.init_calib_complete_i(init_calib_complete)

    ,.app_sr_req_o(app_sr_req)
    ,.app_sr_ack_i(app_sr_ack)
  );  

  mock_dram_ctrl #(
    .addr_width_p(32)
    ,.data_width_p(128)
    ,.burst_len_p(1)
    ,.mem_size_p(4096)
  ) dram_ctrl (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.app_addr_i(app_addr) // short address!!!
    ,.app_cmd_i(app_cmd) 
    ,.app_hi_pri_i(app_hi_pri)
    ,.app_en_i(app_en)
    ,.app_rdy_o(app_rdy)

    ,.app_wdf_wren_i(app_wdf_wren)
    ,.app_wdf_data_i(app_wdf_data)
    ,.app_wdf_mask_i(app_wdf_mask)
    ,.app_wdf_end_i(app_wdf_end)
    ,.app_wdf_rdy_o(app_wdf_rdy)

    ,.app_rd_data_valid_o(app_rd_data_valid)
    ,.app_rd_data_o(app_rd_data)
    ,.app_rd_data_end_o(app_rd_data_end)

    ,.app_ref_req_i(app_ref_req)
    ,.app_ref_ack_o(app_ref_ack)
    ,.app_zq_req_i(app_zq_req)
    ,.app_zq_ack_o(app_zq_ack)
    ,.app_sr_req_i(app_sr_req)
    ,.app_sr_ack_o(app_sr_ack)
    ,.init_calib_complete_o(init_calib_complete)
  );

endmodule
