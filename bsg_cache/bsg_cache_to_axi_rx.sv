/**
 *  bsg_cache_to_axi_rx.sv
 *
 *  @author tommy
 */

`include "bsg_defines.sv"

module bsg_cache_to_axi_rx
 import bsg_axi_pkg::*;
  #(parameter `BSG_INV_PARAM(num_cache_p)
    ,parameter `BSG_INV_PARAM(addr_width_p)
    ,parameter `BSG_INV_PARAM(data_width_p)
    ,parameter `BSG_INV_PARAM(block_size_in_words_p)
    ,parameter tag_fifo_els_p=num_cache_p

    ,parameter `BSG_INV_PARAM(axi_id_width_p)
    ,parameter `BSG_INV_PARAM(axi_data_width_p)
    ,parameter `BSG_INV_PARAM(axi_burst_len_p)
    ,parameter `BSG_INV_PARAM(axi_burst_type_p)

    ,parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    ,parameter data_width_ratio_lp=(axi_data_width_p/data_width_p)
  )
  (
    input clk_i
    ,input reset_i

    ,input v_i
    ,output logic yumi_o
    ,input [lg_num_cache_lp-1:0] cache_id_i
    ,input [addr_width_p-1:0] addr_i

    ,input fence_i

    // cache dma read channel
    ,output logic [num_cache_p-1:0][data_width_p-1:0] dma_data_o
    ,output logic [num_cache_p-1:0] dma_data_v_o
    ,input [num_cache_p-1:0] dma_data_ready_and_i

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

  // suppress unused
  //
  wire [axi_id_width_p-1:0] unused_rid = axi_rid_i;
  wire [1:0] unused_rresp = axi_rresp_i;
  wire unused_rlast = axi_rlast_i;

  // tag fifo
  //
  logic tag_fifo_v_li;
  logic tag_fifo_ready_lo;
  logic tag_fifo_v_lo;
  logic tag_fifo_yumi_li;
  logic [lg_num_cache_lp-1:0] tag_lo;

  bsg_fifo_1r1w_small #(
    .width_p(lg_num_cache_lp)
    ,.els_p(tag_fifo_els_p)
  ) tag_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(tag_fifo_v_li)
    ,.ready_param_o(tag_fifo_ready_lo)
    ,.data_i(cache_id_i)

    ,.v_o(tag_fifo_v_lo)
    ,.data_o(tag_lo)
    ,.yumi_i(tag_fifo_yumi_li)
  );
  
  // yumi when address packet is consumed
  assign yumi_o = axi_arvalid_o & axi_arready_i;
  // tag_fifo is valid when address packet is consumed
  assign tag_fifo_v_li = axi_arvalid_o & axi_arready_i;
  
  // axi read address channel
  //
  assign axi_arid_o = {axi_id_width_p{1'b0}};
  assign axi_araddr_addr_o = addr_i;
  assign axi_araddr_cache_id_o = cache_id_i;
  assign axi_arlen_o = (8)'(axi_burst_len_p-1); // burst length
  assign axi_arsize_o = (3)'(`BSG_SAFE_CLOG2(axi_data_width_p>>3));
  assign axi_arburst_o = 2'(axi_burst_type_p);   // fixed, incr or wrap
  assign axi_arcache_o = e_axi_cache_wnarnanmnb; // non-bufferable
  assign axi_arprot_o = e_axi_prot_dsn;    // unprivileged
  assign axi_arlock_o = 1'b0;    // normal access
  // axi_ar is valid when tag_fifo is ready and there's no ordering fence
  assign axi_arvalid_o = v_i & tag_fifo_ready_lo & ~fence_i;

 
  // axi read data channel
  //
  logic piso_v_lo;
  logic [data_width_p-1:0] piso_data_lo;
  logic piso_yumi_li;

  bsg_parallel_in_serial_out #(
    .width_p(data_width_p)
    ,.els_p(data_width_ratio_lp)
  ) piso (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.valid_i(axi_rvalid_i)
    ,.data_i(axi_rdata_i)
    ,.ready_and_o(axi_rready_o)

    ,.valid_o(piso_v_lo)
    ,.data_o(piso_data_lo)
    ,.yumi_i(piso_yumi_li)
  );

  logic [num_cache_p-1:0] cache_sel;

  // demux
  //
  bsg_decode_with_v #(
    .num_out_p(num_cache_p)
  ) demux (
    .i(tag_lo)
    ,.v_i(tag_fifo_v_lo)
    ,.o(cache_sel)
  );

  assign dma_data_v_o = cache_sel & {num_cache_p{piso_v_lo}};

  for (genvar i = 0; i < num_cache_p; i++) begin
    assign dma_data_o[i] = piso_data_lo;
  end

  // counter
  //
  logic [`BSG_SAFE_CLOG2(block_size_in_words_p)-1:0] count_lo;
  logic counter_clear_li;
  logic counter_up_li;
  
  bsg_counter_clear_up #(
    .max_val_p(block_size_in_words_p-1)
    ,.init_val_p(0)
  ) counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.clear_i(counter_clear_li)
    ,.up_i(counter_up_li)
    ,.count_o(count_lo)
  );
  
  assign piso_yumi_li = dma_data_ready_and_i[tag_lo] & piso_v_lo & tag_fifo_v_lo;

  always_comb begin
    if (count_lo == block_size_in_words_p-1) begin
      counter_clear_li = piso_yumi_li;
      counter_up_li = 1'b0;
      tag_fifo_yumi_li = piso_yumi_li;
    end
    else begin
      counter_clear_li = 1'b0;
      counter_up_li = piso_yumi_li;
      tag_fifo_yumi_li = 1'b0;
    end
  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_cache_to_axi_rx)
