
`include "bsg_chip_defines.svh"
`include "bsg_manycore_defines.svh"
`include "bsg_tag.svh"

module bsg_chip_manycore_tester
 import bsg_chip_pkg::*;
 import bsg_chip_test_pkg::*;
 import bsg_tag_pkg::*;
 import bsg_manycore_pkg::*;
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

   , parameter `BSG_INV_PARAM(addr_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)
   , parameter `BSG_INV_PARAM(x_cord_width_p)
   , parameter `BSG_INV_PARAM(y_cord_width_p)
   , parameter `BSG_INV_PARAM(guts_data_width_p)

   , parameter `BSG_INV_PARAM(num_io_links_p)
   , parameter `BSG_INV_PARAM(num_noc_links_p)
   , parameter `BSG_INV_PARAM(num_raw_links_p)

   , localparam manycore_link_sif_width_lp = `bsg_manycore_link_sif_width(addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p)
   , localparam noc_link_sif_width_lp = `bsg_ready_and_link_sif_width(guts_data_width_p)
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

    // Synchronized to gateway clock 
    , output bit test_clk_o
    , output bit test_reset_o
    , input [num_io_links_p-1:0][manycore_link_sif_width_lp-1:0] test_io_link_sif_i
    , output logic [num_io_links_p-1:0][manycore_link_sif_width_lp-1:0] test_io_link_sif_o
    , input [num_noc_links_p-1:0][noc_link_sif_width_lp-1:0] test_noc_link_sif_i
    , output logic [num_noc_links_p-1:0][noc_link_sif_width_lp-1:0] test_noc_link_sif_o
    , input [num_raw_links_p-1:0][raw_link_sif_width_lp-1:0] test_raw_link_sif_i
    , output logic [num_raw_links_p-1:0][raw_link_sif_width_lp-1:0] test_raw_link_sif_o

    , output logic done_o
    , output logic error_o
    );

  logic [test_rom_payload_width_p-1:0] test_data_lo;
  logic test_v_lo, test_yumi_li;
  logic [test_rom_payload_width_p-1:0] test_data_li;
  logic test_v_li, test_ready_and_lo;
  logic tag_error_lo, tag_done_lo;
  logic test_error_lo, test_done_lo;
  bsg_chip_tester
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
     )
   tester
    (.*

     ,.test_data_o(test_data_lo)
     ,.test_v_o(test_v_lo)
     ,.test_yumi_i(test_yumi_li)

     ,.test_data_i(test_data_li)
     ,.test_v_i(test_v_li)
     ,.test_ready_and_o(test_ready_and_lo)

     ,.tag_done_o(tag_done_lo)
     ,.tag_error_o(tag_error_lo)
     ,.test_done_o(test_done_lo)
     ,.test_error_o(test_error_lo)
     );

  //////////////////////////////////////////////////
  // Convert to SIF links
  //////////////////////////////////////////////////

  wire test_reset_lo = gateway_reset_o || !tag_done_lo;
  bsg_sync_sync
   #(.width_p(1))
   bss
    (.oclk_i(test_clk_o)
     ,.iclk_data_i(test_reset_lo)
     ,.oclk_data_o(test_reset_o)
     );
  assign test_clk_o = gateway_clk_o;

  `declare_bsg_manycore_link_sif_s(addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p);
  bsg_manycore_link_sif_s [num_io_links_p-1:0] test_io_link_sif_li, test_io_link_sif_lo;
  assign test_io_link_sif_li = test_io_link_sif_i;
  assign test_io_link_sif_o = test_io_link_sif_lo;

  `declare_bsg_ready_and_link_sif_s(guts_data_width_p, bsg_ready_and_link_noc_sif_s);
  bsg_ready_and_link_noc_sif_s [num_noc_links_p-1:0] test_noc_link_sif_li, test_noc_link_sif_lo;
  assign test_noc_link_sif_li = test_noc_link_sif_i;
  assign test_noc_link_sif_o = test_noc_link_sif_lo;

  `declare_bsg_ready_and_link_sif_s(test_link_pkt_width_lp, bsg_ready_and_link_sif_raw_s);
  bsg_ready_and_link_sif_raw_s [num_noc_links_p-1:0] test_raw_link_sif_li, test_raw_link_sif_lo;
  assign test_raw_link_sif_li = test_raw_link_sif_i;
  assign test_raw_link_sif_o = test_raw_link_sif_lo;

  `declare_bsg_manycore_packet_s(addr_width_p, data_width_p, x_cord_width_p, y_cord_width_p);
  bsg_manycore_packet_s test_packet_lo;
  logic [num_io_links_p-1:0] test_packet_v_lo, test_packet_ready_and_li;
  bsg_manycore_return_packet_s [num_io_links_p-1:0] test_return_packet_li;
  logic [num_io_links_p-1:0] test_return_packet_v_li, test_return_packet_yumi_lo;

  bsg_manycore_packet_s [num_io_links_p-1:0] test_packet_li;
  logic [num_io_links_p-1:0] test_packet_v_li, test_packet_yumi_lo;
  bsg_manycore_return_packet_s test_return_packet_lo;
  logic [num_io_links_p-1:0] test_return_packet_v_lo, test_return_packet_ready_and_li;

  logic [num_noc_links_p-1:0][guts_data_width_p-1:0] test_noc_packet_li;
  logic [num_noc_links_p-1:0] test_noc_packet_v_li, test_noc_packet_yumi_lo;
  logic [guts_data_width_p-1:0] test_noc_packet_lo;
  logic [num_noc_links_p-1:0] test_noc_packet_v_lo, test_noc_packet_ready_and_li;

  logic [num_raw_links_p-1:0][test_link_pkt_width_lp-1:0] test_raw_packet_li;
  logic [num_raw_links_p-1:0] test_raw_packet_v_li, test_raw_packet_yumi_lo;
  logic [test_link_pkt_width_lp-1:0] test_raw_packet_lo;
  logic [num_raw_links_p-1:0] test_raw_packet_v_lo, test_raw_packet_ready_and_li;
 
  localparam io_fifo_els_lp = 8;
  for (genvar i = 0; i < num_io_links_p; i++)
    begin : io_in
      bsg_fifo_1r1w_small
       #(.width_p($bits(bsg_manycore_packet_s)), .els_p(io_fifo_els_lp))
       fwd_fifo
        (.clk_i(test_clk_o)
         ,.reset_i(test_reset_o)

         ,.data_i(test_io_link_sif_li[i].fwd.data)
         ,.v_i(test_io_link_sif_li[i].fwd.v)
         ,.ready_param_o(test_io_link_sif_lo[i].fwd.ready_and_rev)

         ,.data_o(test_packet_li[i])
         ,.v_o(test_packet_v_li[i])
         ,.yumi_i(test_packet_yumi_lo[i])
         );

      bsg_fifo_1r1w_small
       #(.width_p($bits(bsg_manycore_return_packet_s)), .els_p(io_fifo_els_lp))
       rev_fifo
        (.clk_i(test_clk_o)
         ,.reset_i(test_reset_o)

         ,.data_i(test_return_packet_lo)
         ,.v_i(test_return_packet_v_lo[i])
         ,.ready_param_o(test_return_packet_ready_and_li[i])

         ,.data_o(test_io_link_sif_lo[i].rev.data)
         ,.v_o(test_io_link_sif_lo[i].rev.v)
         ,.yumi_i(test_io_link_sif_li[i].rev.ready_and_rev & test_io_link_sif_lo[i].rev.v)
         );
    end

  for (genvar i = 0; i < num_io_links_p; i++)
    begin : io_out
      bsg_fifo_1r1w_small
       #(.width_p($bits(bsg_manycore_packet_s)), .els_p(io_fifo_els_lp))
       fwd_fifo
        (.clk_i(test_clk_o)
         ,.reset_i(test_reset_o)

         ,.data_i(test_packet_lo)
         ,.v_i(test_packet_v_lo[i])
         ,.ready_param_o(test_packet_ready_and_li[i])

         ,.data_o(test_io_link_sif_lo[i].fwd.data)
         ,.v_o(test_io_link_sif_lo[i].fwd.v)
         ,.yumi_i(test_io_link_sif_li[i].fwd.ready_and_rev & test_io_link_sif_lo[i].fwd.v)
         );

      bsg_fifo_1r1w_small
       #(.width_p($bits(bsg_manycore_return_packet_s)), .els_p(io_fifo_els_lp))
       rev_fifo
        (.clk_i(test_clk_o)
         ,.reset_i(test_reset_o)

         ,.data_i(test_io_link_sif_li[i].rev.data)
         ,.v_i(test_io_link_sif_li[i].rev.v)
         ,.ready_param_o(test_io_link_sif_lo[i].rev.ready_and_rev)

         ,.data_o(test_return_packet_li[i])
         ,.v_o(test_return_packet_v_li[i])
         ,.yumi_i(test_return_packet_yumi_lo[i])
         );
    end

  localparam noc_fifo_els_lp = 8;
  for (genvar i = 0; i < num_noc_links_p; i++)
    begin : noc
      bsg_fifo_1r1w_small
       #(.width_p(guts_data_width_p), .els_p(noc_fifo_els_lp))
       out_fifo
        (.clk_i(test_clk_o)
         ,.reset_i(test_reset_o)

         ,.data_i(test_noc_packet_lo)
         ,.v_i(test_noc_packet_v_lo[i])
         ,.ready_param_o(test_noc_packet_ready_and_li[i])

         ,.data_o(test_noc_link_sif_lo[i].data)
         ,.v_o(test_noc_link_sif_lo[i].v)
         ,.yumi_i(test_noc_link_sif_li[i].ready_and_rev & test_noc_link_sif_lo[i].v)
         );

      bsg_fifo_1r1w_small
       #(.width_p(guts_data_width_p), .els_p(noc_fifo_els_lp))
       in_fifo
        (.clk_i(test_clk_o)
         ,.reset_i(test_reset_o)

         ,.data_i(test_noc_link_sif_li[i].data)
         ,.v_i(test_noc_link_sif_li[i].v)
         ,.ready_param_o(test_noc_link_sif_lo[i].ready_and_rev)

         ,.data_o(test_noc_packet_li[i])
         ,.v_o(test_noc_packet_v_li[i])
         ,.yumi_i(test_noc_packet_yumi_lo[i])
         );
    end

  localparam raw_fifo_els_lp = 8;
  for (genvar i = 0; i < num_raw_links_p; i++)
    begin : raw
      bsg_fifo_1r1w_small
       #(.width_p(test_link_pkt_width_lp), .els_p(raw_fifo_els_lp))
       out_fifo
        (.clk_i(test_clk_o)
         ,.reset_i(test_reset_o)

         ,.data_i(test_raw_packet_lo)
         ,.v_i(test_raw_packet_v_lo[i])
         ,.ready_param_o(test_raw_packet_ready_and_li[i])

         ,.data_o(test_raw_link_sif_lo[i].data)
         ,.v_o(test_raw_link_sif_lo[i].v)
         ,.yumi_i(test_raw_link_sif_li[i].ready_and_rev & test_raw_link_sif_lo[i].v)
         );

      bsg_fifo_1r1w_small
       #(.width_p(test_link_pkt_width_lp), .els_p(raw_fifo_els_lp))
       in_fifo
        (.clk_i(test_clk_o)
         ,.reset_i(test_reset_o)

         ,.data_i(test_raw_link_sif_li[i].data)
         ,.v_i(test_raw_link_sif_li[i].v)
         ,.ready_param_o(test_raw_link_sif_lo[i].ready_and_rev)

         ,.data_o(test_raw_packet_li[i])
         ,.v_o(test_raw_packet_v_li[i])
         ,.yumi_i(test_raw_packet_yumi_lo[i])
         );

    end

  //////////////////////////////////////////////////
  // Driving output data
  //////////////////////////////////////////////////
  bsg_test_rom_manycore_s test_payload_lo;
  assign test_payload_lo = test_data_lo;

  wire test_rom_packet_v_li = test_v_lo & (test_payload_lo.typ == e_link_type_fwd);
  wire [`BSG_SAFE_CLOG2(num_io_links_p)-1:0] test_rom_packet_tag_li = test_payload_lo.idx;
  logic test_rom_packet_yumi_lo;
  bsg_1_to_n_tagged
   #(.num_out_p(num_io_links_p))
   botont_fwd
    (.clk_i(test_clk_o)
     ,.reset_i(test_reset_o)

     ,.v_i(test_rom_packet_v_li)
     ,.tag_i(test_rom_packet_tag_li)
     ,.yumi_o(test_rom_packet_yumi_lo)

     ,.v_o(test_packet_v_lo)
     ,.ready_and_i(test_packet_ready_and_li)
     );
  assign test_packet_lo = test_payload_lo.pkt.fwd;

  wire test_rom_return_packet_v_li = test_v_lo & (test_payload_lo.typ == e_link_type_rev);
  wire [`BSG_SAFE_CLOG2(num_io_links_p)-1:0] test_rom_return_packet_tag_li = test_payload_lo.idx;
  logic test_rom_return_packet_yumi_lo;
  bsg_1_to_n_tagged
   #(.num_out_p(num_io_links_p))
   botont_rev
    (.clk_i(test_clk_o)
     ,.reset_i(test_reset_o)

     ,.v_i(test_rom_return_packet_v_li)
     ,.tag_i(test_rom_return_packet_tag_li)
     ,.yumi_o(test_rom_return_packet_yumi_lo)

     ,.v_o(test_return_packet_v_lo)
     ,.ready_and_i(test_return_packet_ready_and_li)
     );
  assign test_return_packet_lo = test_payload_lo.pkt.rev;

  wire test_rom_noc_packet_v_li = test_v_lo & (test_payload_lo.typ == e_link_type_noc);
  wire [`BSG_SAFE_CLOG2(num_io_links_p)-1:0] test_rom_noc_packet_tag_li = test_payload_lo.idx;
  logic test_rom_noc_packet_yumi_lo;
  bsg_1_to_n_tagged
   #(.num_out_p(num_noc_links_p))
   botont_noc
    (.clk_i(test_clk_o)
     ,.reset_i(test_reset_o)

     ,.v_i(test_rom_noc_packet_v_li)
     ,.tag_i(test_rom_noc_packet_tag_li)
     ,.yumi_o(test_rom_noc_packet_yumi_lo)

     ,.v_o(test_noc_packet_v_lo)
     ,.ready_and_i(test_noc_packet_ready_and_li)
     );
  assign test_noc_packet_lo = test_payload_lo.pkt.noc;

  wire test_rom_raw_packet_v_li = test_v_lo & (test_payload_lo.typ == e_link_type_raw);
  wire [`BSG_SAFE_CLOG2(num_io_links_p)-1:0] test_rom_raw_packet_tag_li = test_payload_lo.idx;
  logic test_rom_raw_packet_yumi_lo;
  bsg_1_to_n_tagged
   #(.num_out_p(num_raw_links_p))
   botont_raw
    (.clk_i(test_clk_o)
     ,.reset_i(test_reset_o)

     ,.v_i(test_rom_raw_packet_v_li)
     ,.tag_i(test_rom_raw_packet_tag_li)
     ,.yumi_o(test_rom_raw_packet_yumi_lo)

     ,.v_o(test_raw_packet_v_lo)
     ,.ready_and_i(test_raw_packet_ready_and_li)
     );
  assign test_raw_packet_lo = test_payload_lo.pkt.raw;

  assign test_yumi_li = test_rom_packet_yumi_lo | test_rom_return_packet_yumi_lo | test_rom_noc_packet_yumi_lo | test_rom_raw_packet_yumi_lo;

  //////////////////////////////////////////////////
  // Check input data
  //////////////////////////////////////////////////
  bsg_test_rom_manycore_s test_payload_li;
  assign test_data_li = test_payload_li;

  bsg_manycore_packet_s selected_test_packet_li;
  bsg_mux
   #(.width_p($bits(bsg_manycore_packet_s)), .els_p(num_io_links_p))
   fwd_mux
    (.data_i(test_packet_li)
     ,.sel_i(test_rom_packet_tag_li)
     ,.data_o(selected_test_packet_li)
     );

  bsg_manycore_return_packet_s selected_test_return_packet_li;
  bsg_mux
   #(.width_p($bits(bsg_manycore_return_packet_s)), .els_p(num_io_links_p))
   rev_mux
    (.data_i(test_return_packet_li)
     ,.sel_i(test_rom_return_packet_tag_li)
     ,.data_o(selected_test_return_packet_li)
     );

  logic [guts_data_width_p-1:0] selected_test_noc_packet_li;
  bsg_mux
   #(.width_p(guts_data_width_p), .els_p(num_noc_links_p))
   noc_mux
    (.data_i(test_noc_packet_li)
     ,.sel_i(test_rom_noc_packet_tag_li)
     ,.data_o(selected_test_noc_packet_li)
     );

  wire [max_test_links_lp-1:0] test_packet_select_mask = (test_ready_and_lo & (test_payload_lo.typ == e_link_type_fwd)) << test_payload_lo.idx;
  wire [max_test_links_lp-1:0] test_return_packet_select_mask = (test_ready_and_lo & (test_payload_lo.typ == e_link_type_rev)) << test_payload_lo.idx;
  wire [max_test_links_lp-1:0] test_noc_packet_select_mask = (test_ready_and_lo & (test_payload_lo.typ == e_link_type_noc)) << test_payload_lo.idx;

  assign test_packet_yumi_lo = test_packet_v_li & test_packet_select_mask;
  assign test_return_packet_yumi_lo = test_return_packet_v_li & test_return_packet_select_mask;
  assign test_noc_packet_yumi_lo = test_noc_packet_v_li & test_noc_packet_select_mask;

  assign test_v_li = |{test_packet_yumi_lo, test_return_packet_yumi_lo, test_noc_packet_yumi_lo};

  always_comb
    begin
      test_payload_li = test_payload_lo;
      case (test_payload_lo.typ)
        e_link_type_fwd: test_payload_li.pkt.fwd = selected_test_packet_li;
        e_link_type_rev: test_payload_li.pkt.rev = selected_test_return_packet_li;
        e_link_type_noc: test_payload_li.pkt.noc = selected_test_noc_packet_li;
      endcase
    end

  assign done_o = tag_done_lo && test_done_lo;
  assign error_o = tag_error_lo || test_error_lo;
    
endmodule
