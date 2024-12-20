
`include "bsg_chip_defines.svh"
`include "bsg_manycore_defines.svh"
`include "bsg_tag.svh"

module bsg_chip_subpod_tester
 import bsg_chip_pkg::*;
 import bsg_chip_test_pkg::*;
 import bsg_tag_pkg::*;
 import bsg_manycore_pkg::*;
 import bsg_link_pearl_pkg::*;
 #(parameter `BSG_INV_PARAM(tag_els_p)
   , parameter `BSG_INV_PARAM(tag_lg_width_p)
   , parameter `BSG_INV_PARAM(tag_lg_els_p)
   , parameter `BSG_INV_PARAM(gateway_tag_local_els_p)
   , parameter `BSG_INV_PARAM(gateway_tag_node_id_offset_p)
   , parameter `BSG_INV_PARAM(asic_tag_local_els_p)
   , parameter `BSG_INV_PARAM(asic_tag_node_id_offset_p)

   , parameter `BSG_INV_PARAM(tag_rom_str_p)
   , parameter `BSG_INV_PARAM(tag_rom_data_width_p)
   , parameter `BSG_INV_PARAM(tag_rom_addr_width_p)
   , parameter `BSG_INV_PARAM(tag_rom_payload_width_p)

   , parameter `BSG_INV_PARAM(test_rom_str_p)
   , parameter `BSG_INV_PARAM(test_rom_data_width_p)
   , parameter `BSG_INV_PARAM(test_rom_addr_width_p)
   , parameter `BSG_INV_PARAM(test_rom_payload_width_p)

   , parameter `BSG_INV_PARAM(sdr_lg_fifo_depth_p)
   , parameter `BSG_INV_PARAM(sdr_lg_credit_to_token_decimation_p)   
   , parameter `BSG_INV_PARAM(sdr_subpod_num_links_p)
   , parameter `BSG_INV_PARAM(sdr_pod_num_links_p)
   , parameter `BSG_INV_PARAM(num_raw_links_p)

   , parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
   , parameter `BSG_INV_PARAM(x_cord_width_p)
   , parameter `BSG_INV_PARAM(y_cord_width_p)
   , parameter `BSG_INV_PARAM(guts_data_width_p)

   , localparam fwd_width_lp =
        `bsg_manycore_packet_width(addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p)
   , localparam rev_width_lp =
        `bsg_manycore_return_packet_width(x_cord_width_p, y_cord_width_p, data_width_p)
   , localparam guts_width_lp = guts_data_width_p
   , localparam raw_link_sif_width_lp = `bsg_ready_and_link_sif_width(test_link_pkt_width_lp)
   )
  (
    output bit gateway_clk_o
    , output bit gateway_reset_o

    , output bit gateway_tag_clk_o
    , output bit gateway_tag_en_o
    , output bit gateway_tag_data_o
    , output logic [tag_lg_els_p-1:0] gateway_tag_node_id_offset_o
    , output bsg_tag_s [gateway_tag_local_els_p-1:0] gateway_tag_lines_o

    , output bit asic_clk_A_o
    , output bit asic_clk_B_o
    , output bit asic_clk_C_o
    , output bit asic_clk_D_o
    , output bit asic_rt_clk_o

    , output bit asic_tag_clk_o
    , output bit asic_tag_en_o
    , output bit asic_tag_data_o
    , output logic [tag_lg_els_p-1:0] asic_tag_node_id_offset_o
    , output bsg_tag_s [asic_tag_local_els_p-1:0] mirror_tag_lines_o

    , output logic [sdr_subpod_num_links_p-1:0]                          io_fwd_link_clk_o
    , output logic [sdr_subpod_num_links_p-1:0][fwd_width_lp-1:0]        io_fwd_link_data_o
    , output logic [sdr_subpod_num_links_p-1:0]                          io_fwd_link_v_o
    , input [sdr_subpod_num_links_p-1:0]                                 io_fwd_link_token_i

    , input [sdr_subpod_num_links_p-1:0]                                 io_rev_link_clk_i
    , input [sdr_subpod_num_links_p-1:0][rev_width_lp-1:0]               io_rev_link_data_i
    , input [sdr_subpod_num_links_p-1:0]                                 io_rev_link_v_i
    , output logic [sdr_subpod_num_links_p-1:0]                          io_rev_link_token_o

    , input [sdr_subpod_num_links_p-1:0]                                 io_fwd_link_clk_i
    , input [sdr_subpod_num_links_p-1:0][fwd_width_lp-1:0]               io_fwd_link_data_i
    , input [sdr_subpod_num_links_p-1:0]                                 io_fwd_link_v_i
    , output logic [sdr_subpod_num_links_p-1:0]                          io_fwd_link_token_o
 
    , output logic [sdr_subpod_num_links_p-1:0]                          io_rev_link_clk_o
    , output logic [sdr_subpod_num_links_p-1:0][rev_width_lp-1:0]        io_rev_link_data_o
    , output logic [sdr_subpod_num_links_p-1:0]                          io_rev_link_v_o
    , input [sdr_subpod_num_links_p-1:0]                                 io_rev_link_token_i

    , input [sdr_pod_num_links_p-1:0]                                    noc_link_clk_i
    , input [sdr_pod_num_links_p-1:0][guts_width_lp-1:0]                 noc_link_data_i
    , input [sdr_pod_num_links_p-1:0]                                    noc_link_v_i
    , output logic [sdr_pod_num_links_p-1:0]                             noc_link_token_o

    , output logic [sdr_pod_num_links_p-1:0]                             noc_link_clk_o
    , output logic [sdr_pod_num_links_p-1:0][guts_width_lp-1:0]          noc_link_data_o
    , output logic [sdr_pod_num_links_p-1:0]                             noc_link_v_o
    , input [sdr_pod_num_links_p-1:0]                                    noc_link_token_i

    , input [num_raw_links_p-1:0][raw_link_sif_width_lp-1:0]             test_raw_link_sif_i
    , output logic [num_raw_links_p-1:0][raw_link_sif_width_lp-1:0]      test_raw_link_sif_o

    , output logic done_o
    , output logic error_o
    );

  `declare_bsg_manycore_link_sif_s(addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p);
  `declare_bsg_ready_and_link_sif_s(guts_data_width_p, bsg_ready_and_link_sif_s);

  logic test_clk_lo, test_reset_lo;
  bsg_manycore_link_sif_s [sdr_subpod_num_links_p-1:0] test_io_link_sif_li, test_io_link_sif_lo;
  bsg_ready_and_link_sif_s [sdr_pod_num_links_p-1:0] test_noc_link_sif_li, test_noc_link_sif_lo;
  bsg_chip_manycore_tester
   #(.tag_els_p(tag_els_p)
     ,.tag_lg_width_p(tag_lg_width_p)
     ,.tag_lg_els_p(tag_lg_els_p)
     ,.gateway_tag_local_els_p(gateway_tag_local_els_p)
     ,.gateway_tag_node_id_offset_p(gateway_tag_node_id_offset_p)
     ,.asic_tag_local_els_p(asic_tag_local_els_p)
     ,.asic_tag_node_id_offset_p(asic_tag_node_id_offset_p)

     ,.tag_rom_str_p(tag_rom_str_p)
     ,.tag_rom_data_width_p(tag_rom_data_width_p)
     ,.tag_rom_addr_width_p(tag_rom_addr_width_p)
     ,.tag_rom_payload_width_p(tag_rom_payload_width_p)

     ,.test_rom_str_p(test_rom_str_p)
     ,.test_rom_data_width_p(test_rom_data_width_p)
     ,.test_rom_addr_width_p(test_rom_addr_width_p)
     ,.test_rom_payload_width_p(test_rom_payload_width_p)

     ,.addr_width_p(addr_width_p)
     ,.data_width_p(data_width_p)
     ,.x_cord_width_p(x_cord_width_p)
     ,.y_cord_width_p(y_cord_width_p)
     ,.guts_data_width_p(guts_data_width_p)

     ,.num_io_links_p(sdr_subpod_num_links_p)
     ,.num_noc_links_p(sdr_pod_num_links_p)
     ,.num_raw_links_p(num_raw_links_p)
     )
   tester
    (.*

     ,.test_clk_o(test_clk_lo)
     ,.test_reset_o(test_reset_lo)

     ,.test_io_link_sif_i(test_io_link_sif_li)
     ,.test_io_link_sif_o(test_io_link_sif_lo)

     ,.test_noc_link_sif_i(test_noc_link_sif_li)
     ,.test_noc_link_sif_o(test_noc_link_sif_lo)
     );

  //////////////////////////////////////////////////
  // Extract test data
  //////////////////////////////////////////////////

  `declare_bsg_manycore_packet_s(addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p);
  wire [tag_lg_els_p-1:0] gateway_tag_node_id_offset_li = black_tag_offset_gateway_gp;
  wire [tag_lg_els_p-1:0] gateway_ddr_node_id_offset_li = gateway_tag_node_id_offset_li + '0;
  wire [tag_lg_els_p-1:0] gateway_sdr_node_id_offset_li = gateway_tag_node_id_offset_li + bsg_ddr_link_pearl_tag_local_els_gp;

  for (genvar i = 0; i < sdr_subpod_num_links_p; i++)
    begin : io
       bsg_sdr_link_pearl
        #(.tag_els_p(tag_els_p)
          ,.tag_lg_width_p(tag_lg_width_p)
          ,.sdr_data_width_p($bits(bsg_manycore_packet_s))
          ,.sdr_lg_fifo_depth_p(sdr_lg_fifo_depth_p)
          ,.sdr_lg_credit_to_token_decimation_p(sdr_lg_credit_to_token_decimation_p)
          )
        fwd_sdr
         (.core_clk_i(test_clk_lo)
          ,.core_reset_i(test_reset_lo)  
 
          ,.tag_clk_i(gateway_tag_clk_o)
          ,.tag_data_i(gateway_tag_data_o)
          ,.tag_node_id_offset_i(gateway_sdr_node_id_offset_li)  
 
          ,.core_data_i(test_io_link_sif_lo[i].fwd.data)
          ,.core_v_i(test_io_link_sif_lo[i].fwd.v)
          ,.core_ready_and_o(test_io_link_sif_li[i].fwd.ready_and_rev)  
 
          ,.core_data_o(test_io_link_sif_li[i].fwd.data)
          ,.core_v_o(test_io_link_sif_li[i].fwd.v)
          ,.core_ready_and_i(test_io_link_sif_lo[i].fwd.ready_and_rev)  
 
          ,.link_clk_o(io_fwd_link_clk_o[i])
          ,.link_data_o(io_fwd_link_data_o[i])
          ,.link_v_o(io_fwd_link_v_o[i])
          ,.link_token_i(io_fwd_link_token_i[i])  
 
          ,.link_clk_i(io_fwd_link_clk_i[i])
          ,.link_data_i(io_fwd_link_data_i[i])
          ,.link_v_i(io_fwd_link_v_i[i])
          ,.link_token_o(io_fwd_link_token_o[i])  
 
          // Manycore subpod link uses global disable
          ,.async_link_i_disable_o()
          ,.async_link_o_disable_o()
          );

       bsg_sdr_link_pearl
        #(.tag_els_p(tag_els_p)
          ,.tag_lg_width_p(tag_lg_width_p)
          ,.sdr_data_width_p($bits(bsg_manycore_return_packet_s))
          ,.sdr_lg_fifo_depth_p(sdr_lg_fifo_depth_p)
          ,.sdr_lg_credit_to_token_decimation_p(sdr_lg_credit_to_token_decimation_p)
          )
        rev_sdr
         (.core_clk_i(test_clk_lo)
          ,.core_reset_i(test_reset_lo)  
 
          ,.tag_clk_i(gateway_tag_clk_o)
          ,.tag_data_i(gateway_tag_data_o)
          ,.tag_node_id_offset_i(gateway_sdr_node_id_offset_li)  
 
          ,.core_data_i(test_io_link_sif_lo[i].rev.data)
          ,.core_v_i(test_io_link_sif_lo[i].rev.v)
          ,.core_ready_and_o(test_io_link_sif_li[i].rev.ready_and_rev)  
 
          ,.core_data_o(test_io_link_sif_li[i].rev.data)
          ,.core_v_o(test_io_link_sif_li[i].rev.v)
          ,.core_ready_and_i(test_io_link_sif_lo[i].rev.ready_and_rev)  
 
          ,.link_clk_o(io_rev_link_clk_o[i])
          ,.link_data_o(io_rev_link_data_o[i])
          ,.link_v_o(io_rev_link_v_o[i])
          ,.link_token_i(io_rev_link_token_i[i])  
 
          ,.link_clk_i(io_rev_link_clk_i[i])
          ,.link_data_i(io_rev_link_data_i[i])
          ,.link_v_i(io_rev_link_v_i[i])
          ,.link_token_o(io_rev_link_token_o[i])  

          // Manycore subpod link uses global disable
          ,.async_link_i_disable_o()
          ,.async_link_o_disable_o()
          );
    end

  for (genvar i = 0; i < sdr_pod_num_links_p; i++)
    begin : noc
       bsg_sdr_link_pearl
        #(.tag_els_p(tag_els_p)
          ,.tag_lg_width_p(tag_lg_width_p)
          ,.sdr_data_width_p(guts_data_width_p)
          ,.sdr_lg_fifo_depth_p(sdr_lg_fifo_depth_p)
          ,.sdr_lg_credit_to_token_decimation_p(sdr_lg_credit_to_token_decimation_p)
          )
        sdr
         (.core_clk_i(test_clk_lo)
          ,.core_reset_i(test_reset_lo)  
 
          ,.tag_clk_i(gateway_tag_clk_o)
          ,.tag_data_i(gateway_tag_data_o)
          ,.tag_node_id_offset_i(gateway_sdr_node_id_offset_li)
 
          ,.core_data_i(test_noc_link_sif_lo[i].data)
          ,.core_v_i(test_noc_link_sif_lo[i].v)
          ,.core_ready_and_o(test_noc_link_sif_li[i].ready_and_rev)  
 
          ,.core_data_o(test_noc_link_sif_li[i].data)
          ,.core_v_o(test_noc_link_sif_li[i].v)
          ,.core_ready_and_i(test_noc_link_sif_lo[i].ready_and_rev)  
 
          ,.link_clk_o(noc_link_clk_o[i])
          ,.link_data_o(noc_link_data_o[i])
          ,.link_v_o(noc_link_v_o[i])
          ,.link_token_i(noc_link_token_i[i])  
 
          ,.link_clk_i(noc_link_clk_i[i])
          ,.link_data_i(noc_link_data_i[i])
          ,.link_v_i(noc_link_v_i[i])
          ,.link_token_o(noc_link_token_o[i])  
 
          // Manycore subpod link uses global disable
          ,.async_link_i_disable_o()
          ,.async_link_o_disable_o()
          );
    end

endmodule

