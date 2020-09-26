/**
 *  bsg_cache_to_dram_ctrl.v
 *
 *  @author tommy
 *
 */

`include "bsg_defines.v"

module bsg_cache_to_dram_ctrl
  import bsg_cache_pkg::*;
  #(parameter num_cache_p="inv"
    , parameter addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter block_size_in_words_p="inv"
    
    , localparam mask_width_lp=(data_width_p>>3)
    , localparam lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    , localparam dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)

    , parameter dram_ctrl_burst_len_p="inv"
    , parameter dram_ctrl_addr_width_p=(addr_width_p+lg_num_cache_lp)

    , localparam num_req_lp=(block_size_in_words_p/dram_ctrl_burst_len_p)
  )
  (
    input clk_i
    , input reset_i
    
    // dram size selection
    // {0:256Mb, 1:512Mb, 2:1Gb, 3:2Gb, 4:4Gb}
    , input [2:0] dram_size_i

    // cache side
    , input [num_cache_p-1:0][dma_pkt_width_lp-1:0] dma_pkt_i
    , input [num_cache_p-1:0] dma_pkt_v_i
    , output logic [num_cache_p-1:0] dma_pkt_yumi_o

    , output logic [num_cache_p-1:0][data_width_p-1:0] dma_data_o
    , output logic [num_cache_p-1:0] dma_data_v_o
    , input [num_cache_p-1:0] dma_data_ready_i

    , input [num_cache_p-1:0][data_width_p-1:0] dma_data_i
    , input [num_cache_p-1:0] dma_data_v_i
    , output logic [num_cache_p-1:0] dma_data_yumi_o

    // dmc side
    , output logic app_en_o
    , input app_rdy_i
    , output logic [2:0] app_cmd_o
    , output logic [dram_ctrl_addr_width_p-1:0] app_addr_o

    , output logic app_wdf_wren_o
    , input app_wdf_rdy_i
    , output logic [data_width_p-1:0] app_wdf_data_o
    , output logic [mask_width_lp-1:0] app_wdf_mask_o
    , output logic app_wdf_end_o

    , input app_rd_data_valid_i
    , input [data_width_p-1:0] app_rd_data_i
    , input app_rd_data_end_i
  );

  // round robin for dma pkts
  //
  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s dma_pkt;
  logic rr_v_lo;
  logic [lg_num_cache_lp-1:0] rr_tag_lo;
  logic rr_yumi_li;

  bsg_round_robin_n_to_1 #(
    .width_p(dma_pkt_width_lp)
    ,.num_in_p(num_cache_p)
    ,.strict_p(0)
  ) cache_rr (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(dma_pkt_i)
    ,.v_i(dma_pkt_v_i)
    ,.yumi_o(dma_pkt_yumi_o)
    ,.v_o(rr_v_lo)
    ,.data_o(dma_pkt)
    ,.tag_o(rr_tag_lo)
    ,.yumi_i(rr_yumi_li)
  );

  logic [lg_num_cache_lp-1:0] tag_r, tag_n;

  // rx module
  //
  logic rx_v_li;
  logic rx_ready_lo;

  bsg_cache_to_dram_ctrl_rx #(
    .num_cache_p(num_cache_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.dram_ctrl_burst_len_p(dram_ctrl_burst_len_p)
  ) rx (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(rx_v_li)
    ,.tag_i(tag_r)
    ,.ready_o(rx_ready_lo)

    ,.dma_data_o(dma_data_o)
    ,.dma_data_v_o(dma_data_v_o)
    ,.dma_data_ready_i(dma_data_ready_i)

    ,.app_rd_data_valid_i(app_rd_data_valid_i)
    ,.app_rd_data_i(app_rd_data_i)
    ,.app_rd_data_end_i(app_rd_data_end_i)
  );

  // tx module
  //
  logic tx_v_li;
  logic tx_ready_lo;

  bsg_cache_to_dram_ctrl_tx #(
    .num_cache_p(num_cache_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.dram_ctrl_burst_len_p(dram_ctrl_burst_len_p)
  ) tx (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i(tx_v_li)
    ,.tag_i(tag_r)
    ,.ready_o(tx_ready_lo)
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
  logic [addr_width_p-1:0] addr_r, addr_n;
  logic write_not_read_r, write_not_read_n;
  logic [`BSG_SAFE_CLOG2(num_req_lp)-1:0] req_cnt_r, req_cnt_n;

  always_comb begin
    app_en_o = 1'b0;
    app_cmd_o = 3'b000;
    rr_yumi_li = 1'b0;
    tag_n = tag_r;
    write_not_read_n = write_not_read_r;
    rx_v_li = 1'b0;
    tx_v_li = 1'b0;
    req_state_n = req_state_r;
    req_cnt_n = req_cnt_r;
    addr_n = addr_r;
    
    case (req_state_r)
      WAIT: begin
        if (rr_v_lo) begin
          rr_yumi_li = 1'b1;
          tag_n = rr_tag_lo;
          addr_n = dma_pkt.addr;
          write_not_read_n = dma_pkt.write_not_read;
          req_cnt_n = '0;
          req_state_n = SEND_REQ;
        end
      end

      SEND_REQ: begin
        app_en_o = (write_not_read_r
          ? tx_ready_lo
          : rx_ready_lo);
        app_cmd_o = write_not_read_r
          ? 3'b000
          : 3'b001;

        rx_v_li = ~write_not_read_r & rx_ready_lo & app_rdy_i;
        tx_v_li = write_not_read_r & tx_ready_lo & app_rdy_i;

        addr_n = (app_rdy_i & app_en_o)
          ? addr_r + (1 << `BSG_SAFE_CLOG2(dram_ctrl_burst_len_p*data_width_p/8))
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

  // Append tag_r to top bits of dram address
  // tag_r not used when only 1 cache exists
  always_comb
    case (dram_size_i)
      0: app_addr_o = dram_ctrl_addr_width_p'({tag_r, addr_r[25-$clog2(num_cache_p)-1:0]});
      1: app_addr_o = dram_ctrl_addr_width_p'({tag_r, addr_r[26-$clog2(num_cache_p)-1:0]});
      2: app_addr_o = dram_ctrl_addr_width_p'({tag_r, addr_r[27-$clog2(num_cache_p)-1:0]});
      3: app_addr_o = dram_ctrl_addr_width_p'({tag_r, addr_r[28-$clog2(num_cache_p)-1:0]});
      4: app_addr_o = dram_ctrl_addr_width_p'({tag_r, addr_r[29-$clog2(num_cache_p)-1:0]});
      default: app_addr_o = {tag_r, addr_r};
    endcase

  // sequential
  //
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      req_state_r <= WAIT;
      tag_r <= '0;
      addr_r <= '0;
      req_cnt_r <= '0;
      write_not_read_r <= 1'b0;
    end
    else begin
      req_state_r <= req_state_n;
      tag_r <= tag_n;
      addr_r <= addr_n;
      req_cnt_r <= req_cnt_n;
      write_not_read_r <= write_not_read_n;
    end
  end


endmodule
