/**
 *  bsg_cache_to_dram_ctrl.sv
 *
 *  @author tommy
 *
 */

`include "bsg_defines.sv"
`include "bsg_cache.svh"
`include "bsg_dmc.svh"

module bsg_cache_to_dram_ctrl
  import bsg_cache_pkg::*;
  import bsg_dmc_pkg::*;
  #(parameter `BSG_INV_PARAM(num_dma_p)
    , parameter `BSG_INV_PARAM(dma_addr_width_p)
    , parameter `BSG_INV_PARAM(dma_data_width_p)
    , parameter `BSG_INV_PARAM(dma_burst_len_p)
    , parameter `BSG_INV_PARAM(dram_ctrl_burst_len_p)
    , parameter `BSG_INV_PARAM(dma_mask_width_p)
    
    , localparam lg_num_dma_lp=`BSG_SAFE_CLOG2(num_dma_p)
    , localparam mask_width_lp=(dma_data_width_p>>3)
    , localparam dma_pkt_width_lp=`bsg_cache_dma_pkt_width(dma_addr_width_p,dma_mask_width_p)
    , localparam num_req_lp=(dma_burst_len_p/dram_ctrl_burst_len_p)
  )
  (
    input clk_i
    , input reset_i
    
    // dram size selection
    // {0:256Mb, 1:512Mb, 2:1Gb, 3:2Gb, 4:4Gb}
    , input [2:0] dram_size_i

    // cache side
    , input [dma_pkt_width_lp-1:0] dma_pkt_i
    , input dma_pkt_v_i
    , output logic dma_pkt_yumi_o
    , input [lg_num_dma_lp-1:0] dma_pkt_id_i

    , output logic [dma_data_width_p-1:0] dma_data_o
    , output logic dma_data_v_o
    , input dma_data_ready_and_i

    , input [dma_data_width_p-1:0] dma_data_i
    , input dma_data_v_i
    , output logic dma_data_yumi_o

    // dmc side
    , output logic app_en_o
    , input app_rdy_i
    , output app_cmd_e app_cmd_o
    , output logic [dma_addr_width_p-1:0] app_addr_raw_o
    , output logic [lg_num_dma_lp-1:0] app_addr_id_o

    , output logic app_wdf_wren_o
    , input app_wdf_rdy_i
    , output logic [dma_data_width_p-1:0] app_wdf_data_o
    , output logic [mask_width_lp-1:0] app_wdf_mask_o
    , output logic app_wdf_end_o

    , input app_rd_data_valid_i
    , input [dma_data_width_p-1:0] app_rd_data_i
    , input app_rd_data_end_i
  );

  // round robin for dma pkts
  //
  `declare_bsg_cache_dma_pkt_s(dma_addr_width_p,dma_mask_width_p);
  bsg_cache_dma_pkt_s dma_pkt;
  assign dma_pkt = dma_pkt_i;

  // rx module
  //

  bsg_cache_to_dram_ctrl_rx #(
    .num_dma_p(num_dma_p)
    ,.dma_data_width_p(dma_data_width_p)
    ,.dma_burst_len_p(dma_burst_len_p)
    ,.dram_ctrl_burst_len_p(dram_ctrl_burst_len_p)
  ) rx (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.dma_data_o(dma_data_o)
    ,.dma_data_v_o(dma_data_v_o)
    ,.dma_data_ready_and_i(dma_data_ready_and_i)

    ,.app_rd_data_valid_i(app_rd_data_valid_i)
    ,.app_rd_data_i(app_rd_data_i)
    ,.app_rd_data_end_i(app_rd_data_end_i)
  );

  // tx module
  //
  logic [dma_mask_width_p-1:0] mask_r, mask_n;

  bsg_cache_to_dram_ctrl_tx #(
    .num_dma_p(num_dma_p)
    ,.dma_data_width_p(dma_data_width_p)
    ,.dma_burst_len_p(dma_burst_len_p)
    ,.dma_mask_width_p(dma_mask_width_p)
    ,.dram_ctrl_burst_len_p(dram_ctrl_burst_len_p)
  ) tx (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.dma_mask_i(mask_r)
    ,.dma_data_i(dma_data_i)
    ,.dma_data_v_i(dma_data_v_i)
    ,.dma_data_yumi_o(dma_data_yumi_o)
    ,.app_wdf_wren_o(app_wdf_wren_o)
    ,.app_wdf_rdy_i(app_wdf_rdy_i)
    ,.app_wdf_data_o(app_wdf_data_o)
    ,.app_wdf_mask_o(app_wdf_mask_o)
    ,.app_wdf_end_o(app_wdf_end_o)
  );

  // dma request
  //
  typedef enum logic {
    WAIT,
    SEND_REQ
  } req_state_e;

  req_state_e req_state_r, req_state_n;
  logic [dma_addr_width_p-1:0] addr_r, addr_n;
  logic write_not_read_r, write_not_read_n;
  logic [`BSG_SAFE_CLOG2(num_req_lp)-1:0] req_cnt_r, req_cnt_n;
  logic [lg_num_dma_lp-1:0] tag_r, tag_n;

  always_comb begin
    app_en_o = 1'b0;
    app_cmd_o = WR;
    dma_pkt_yumi_o = 1'b0;
    write_not_read_n = write_not_read_r;
    req_state_n = req_state_r;
    req_cnt_n = req_cnt_r;
    addr_n = addr_r;
    mask_n = mask_r;
    tag_n = tag_r;
    
    case (req_state_r)
      WAIT: begin
        if (dma_pkt_v_i) begin
          dma_pkt_yumi_o = 1'b1;
          addr_n = dma_pkt.addr;
          mask_n = dma_pkt.mask;
          tag_n = dma_pkt_id_i;
          write_not_read_n = dma_pkt.write_not_read;
          req_cnt_n = '0;
          req_state_n = SEND_REQ;
        end
      end

      SEND_REQ: begin
        app_en_o = 1'b1;
        app_cmd_o = write_not_read_r
          ? WR
          : RD;

        addr_n = (app_rdy_i & app_en_o)
          ? addr_r + (1 << `BSG_SAFE_CLOG2(dram_ctrl_burst_len_p*dma_data_width_p/8))
          : addr_r;
        req_cnt_n = (app_rdy_i & app_en_o)
          ? req_cnt_r + 1
          : req_cnt_r;
        req_state_n = app_rdy_i & app_en_o & (req_cnt_r == num_req_lp-1)
          ? WAIT
          : SEND_REQ;
      end
    endcase
  end

  assign app_addr_raw_o = addr_r;
  assign app_addr_id_o = tag_r;

  // sequential
  //
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      req_state_r <= WAIT;
      addr_r <= '0;
      mask_r <= '0;
      tag_r <= '0;
      req_cnt_r <= '0;
      write_not_read_r <= 1'b0;
    end
    else begin
      req_state_r <= req_state_n;
      addr_r <= addr_n;
      mask_r <= mask_n;
      tag_r <= tag_n;
      req_cnt_r <= req_cnt_n;
      write_not_read_r <= write_not_read_n;
    end
  end


endmodule

`BSG_ABSTRACT_MODULE(bsg_cache_to_dram_ctrl)
