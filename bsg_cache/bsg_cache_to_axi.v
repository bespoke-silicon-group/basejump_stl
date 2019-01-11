/**
 *  bsg_cache_to_axi.v
 *
 *  @author 
 *
 *  @param data_width_p data width.
 *  @param addr_width_p address width. (byte addressing)
 *  @param block_size_in_words_p number of words in cache block.
 *  @param data_width_p bit-width of words in cache.
 *  @param burst_len_p number of bursts per request.
 *  @param burst_width_p bit-width of burst data.
 *  @param num_cache_p number of cache attached to this module.
 *  @param dram_addr_width_p number of dram offset width.
 */

`include "bsg_cache_dma_pkt.vh"

module bsg_cache_to_axi
  import bsg_dram_ctrl_pkg::*;
  #(
    parameter addr_width_p="inv"
   ,parameter block_size_in_words_p="inv"
   ,parameter data_width_p="inv"
   ,parameter burst_len_p="inv"
   ,parameter burst_width_p="inv"
   ,parameter num_cache_p="inv"
   ,parameter dram_addr_width_p="inv"
   ,parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
   ,parameter data_width_ratio_lp=burst_width_p/data_width_p
   ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
   ,parameter num_req_lp=(data_width_p*block_size_in_words_p)/(burst_width_p*burst_len_p)
   ,parameter block_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p*block_size_in_words_p/8)
   ,parameter dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
   )
  (
   input clk_i
  ,input reset_i

  ,input          [dma_pkt_width_lp-1:0]   dma_pkt_i
  ,input                                   dma_pkt_v_i
  ,output logic                            dma_pkt_yumi_o

  ,output logic   [data_width_p-1:0]       dma_data_o
  ,output logic                            dma_data_v_o
  ,input                                   dma_data_ready_i

  ,input          [data_width_p-1:0]       dma_data_i
  ,input                                   dma_data_v_i
  ,output logic                            dma_data_yumi_o

  // AXI write address channel signals
  ,output logic   [  5:0]     axi_awid_o
  ,output logic   [ 32:0]     axi_awaddr_o
  ,output logic   [  7:0]     axi_awlen_o
  ,output logic   [  2:0]     axi_awsize_o
  ,output logic   [  1:0]     axi_awburst_o
  ,output logic   [  3:0]     axi_awcache_o
  ,output logic   [  2:0]     axi_awprot_o
  ,output logic               axi_awvalid_o
  ,input                      axi_awready_i

  // AXI write data channel signals
  ,output logic   [255:0]     axi_wdata_o
  ,output logic   [ 31:0]     axi_wstrb_o
  ,output logic               axi_wlast_o
  ,output logic               axi_wvalid_o
  ,input                      axi_wready_o

  // AXI write response channel signals
  ,input          [  5:0]     axi_bid_i
  ,input          [  1:0]     axi_bresp_i
  ,input                      axi_bvalid_i
  ,output logic               axi_bready_o

  // AXI read address channel signals
  ,output logic   [  5:0]     axi_arid_o
  ,output logic   [ 32:0]     axi_araddr_o
  ,output logic   [  7:0]     axi_arlen_o
  ,output logic   [  2:0]     axi_arsize_o
  ,output logic   [  1:0]     axi_arburst_o
  ,output logic   [  3:0]     axi_arcache_o
  ,output logic               axi_arvalid_o
  ,input                      axi_arready_i

  // AXI read data channel signals
  ,input                      axi_rid_o
  ,input          [255:0]     axi_rdata_o
  ,input          [  1:0]     axi_rresp_o
  ,input                      axi_rlast_o
  ,input                      axi_rvalid_o
  ,output logic               axi_rready_o
  );

  // round robin for dma pkts
  /*
  logic rr_v_lo; // resp to dma_pkt_v_i
  logic [dma_pkt_width_lp-1:0]  rr_data_lo; // resp to dma_pkt_i
  logic [lg_num_cache_lp-1:0]   rr_tag_lo;
  logic rr_yumi_li;
  */

  /*
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
    ,.data_o(rr_data_lo)
    ,.tag_o(rr_tag_lo)
    ,.yumi_i(rr_yumi_li)
  );
  */

  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s dma_pkt;
  assign dma_pkt = data_lo;

  //logic [lg_num_cache_lp-1:0] tag_r, tag_n;

  // dma request
  //
  typedef enum logic {
    WAIT,
    SEND_REQ,
    FINISH_REQ
  } req_state_e;

  req_state_e req_state_r, req_state_n;
  logic write_not_read_r, write_not_read_n;
  logic [addr_width_p-1:0] addr_r, addr_n;
  logic [`BSG_SAFE_CLOG2(num_req_lp)-1:0] req_cnt_r, req_cnt_n;

  assign axi_arburst_o = 2'b01;  // set to incrementing mode
  assign axi_arcache_o = 3'b000; // set to non-bufferable

  assign axi_awburst_o = 2'b01;  // set to incrementing mode
  assign axi_awcache_o = 3'b000; // set to non-bufferable
  assign axi_awprot_o  = 2'b00;  // set to unprivileged access

  // handle the read/write address channels
  always_comb begin
    //initializations here
    axi_arvalid_o = 1'b0;
    axi_awvalid_o = 1'b0;

    case (req_state_r)
      WAIT: begin
        dma_pkt_yumi_o   = dma_pkt_v_i ;
        addr_n           = dma_pkt_v_i ? dma_pkt.addr           : addr_r;
        write_not_read_n = dma_pkt_v_i ? dma_pkt.write_not_read : write_not_read_r;
        req_cnt_n        = dma_pkt_v_i ? '0                     : req_cnt_r;
        req_state_n      = dma_pkt_v_i ? SEND_REQ               : WAIT;
      end
      SEND_REQ: begin
        case (write_not_read_r) // may need to use seperate module?
          1'b0: begin // reading request
            axi_arvalid_o = 1'b1;
            axi_araddr_o  = addr_r;
            axi_arlen_o   = num_req_lp;
            axi_arsize_o  = 3'(`BSG_SAFE_CLOG2(burst_width_p/8));
            req_state_n   = axi_arready_i ? FINISH_REQ : SEND_REQ;
          end
          1'b1: begin // writing request
            axi_awvalid_o = 1'b1;
            axi_awaddr_o  = addr_r;
            axi_awaddr_o  = num_req_lp;
            axi_awsize_o  = 3'(`BSG_SAFE_CLOG2(burst_width_p/8));
            req_state_n   = axi_awready_i ? FINISH_REQ : SEND_REQ;
          end
        endcase
      end
      FINISH_REQ: begin
        case (write_not_read_r)
          1'b0: // reading request
            axi_arvalid_o = 1'b0;
          1'b1: // writing request
            axi_awvalid_o = 1'b0;
          end
        endcase
        req_state_n = WAIT;
      end
    endcase
  end

  // sequential
  //
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      addr_r      <= '0;
      req_state_r <= WAIT;
      write_not_read_r <= 1'b0;
      //req_cnt_r <= '0;
    end
    else begin
      addr_r      <= addr_n;
      req_state_r <= req_state_n;
      write_not_read_r <= write_not_read_n;
      //req_cnt_r <= req_cnt_n;
    end
  end

  always_comb begin
    app_en_o = 1'b0;
    app_cmd_o = eAppRead;
    rr_yumi_li = 1'b0;
    tag_n = tag_r;
    write_not_read_n = write_not_read_r;
    rx_v_li = 1'b0;
    tx_v_li = 1'b0;
    
    case (req_state_r)
      WAIT: begin
        rr_yumi_li = rr_v_lo;
        tag_n = rr_v_lo ? rr_tag_lo : tag_r;
        addr_n = rr_v_lo ? dma_pkt.addr: addr_r;
        write_not_read_n = dma_pkt.write_not_read;
        req_cnt_n = rr_v_lo ? '0 : req_cnt_r;
        req_state_n = rr_v_lo 
          ? SEND_REQ
          : WAIT;
      end

      SEND_REQ: begin
        app_en_o = (write_not_read_r
          ? tx_ready_lo
          : rx_ready_lo);
        app_cmd_o = write_not_read_r
          ? eAppWrite
          : eAppRead;

        rx_v_li = ~write_not_read_r & rx_ready_lo & app_rdy_i;
        tx_v_li = write_not_read_r & tx_ready_lo & app_rdy_i;

        addr_n = (app_rdy_i & app_en_o)
          ? addr_r + (1 << `BSG_SAFE_CLOG2(burst_width_p*burst_len_p/8))
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

  assign app_addr_o = {tag_r, addr_r[0+:dram_addr_width_p]};

  assign app_hi_pri_o = 1'b1;
  assign app_ref_req_o = 1'b0;
  assign app_zq_req_o = 1'b0;
  assign app_sr_req_o = 1'b0;


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
