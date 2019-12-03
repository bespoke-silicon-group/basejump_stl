/**
 *    bsg_cache_to_ramulator_hbm.v 
 *
 */

module bsg_cache_to_ramulator_hbm
  import bsg_cache_pkg::*;
  #(parameter num_cache_p="inv"
    , parameter addr_width_p="inv" // cache addr (byte)
    , parameter data_width_p="inv" // cache data width
    , parameter block_size_in_words_p="inv" // cache block size (word)
    , parameter cache_bank_addr_width_p="inv" // number of bits used for address (byte)

    , parameter hbm_channel_addr_width_p="inv"  // hbm channel addr width
    , parameter hbm_data_width_p="inv"  // hbm channel data width

    , parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    , parameter hbm_data_mask_width_lp=(hbm_data_width_p>>3)
    , parameter dma_pkt_width_lp=`bsg_cache_non_blocking_dma_pkt_width(addr_width_p)
  )
  (
    
    // vcache
    input core_clk_i
    , input core_reset_i
    
    , input [num_cache_p-1:0][dma_pkt_width_lp-1:0] dma_pkt_i 
    , input [num_cache_p-1:0] dma_pkt_v_i
    , output logic [num_cache_p-1:0] dma_pkt_yumi_o

    , output logic [num_cache_p-1:0][data_width_p-1:0] dma_data_o
    , output logic [num_cache_p-1:0] dma_data_v_o
    , input [num_cache_p-1:0] dma_data_ready_i

    , input [num_cache_p-1:0][data_width_p-1:0] dma_data_i
    , input [num_cache_p-1:0] dma_data_v_i
    , output logic [num_cache_p-1:0] dma_data_yumi_o


    // hbm
    , input hbm_clk_i
    , input hbm_reset_i

    , output logic hbm_req_v_o 
    , output logic hbm_write_not_read_o
    , output logic [hbm_channel_addr_width_p-1:0] hbm_ch_addr_o
    , input hbm_req_yumi_i

    , output logic hbm_data_v_o
    , output logic [hbm_data_width_p-1:0] hbm_data_o
    , input hbm_data_yumi_i

    , input hbm_data_v_i
    , input [hbm_data_width_p-1:0] hbm_data_i
  );


  // dma pkt
  //
  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s [num_cache_p-1:0] dma_pkt;
  assign dma_pkt = dma_pkt_i;


  // round robin for dma pkts
  //
  logic rr_v_lo;
  bsg_cache_dma_pkt_s rr_pkt_lo;  
  logic [lg_num_cache_lp-1:0] rr_tag_lo;
  logic rr_yumi_li;

  bsg_round_robin_n_to_1 #(
    .width_p(dma_pkt_width_lp)
    ,.num_in_p(num_cache_p)
    ,.strict_p(0)
  ) cache_rr (
    .clk_i(core_clk_i)
    ,.reset_i(core_reset_i)
    
    ,.data_i(dma_pkt)
    ,.v_i(dma_pkt_v_i)
    ,.yumi_o(dma_pkt_yumi_o)

    ,.v_o(rr_v_lo)
    ,.data_o(rr_pkt_lo)
    ,.tag_o(rr_tag_lo)
    ,.yumi_i(rr_yumi_li)
  );


  //  request
  //
  logic [hbm_channel_addr_width_p-1:0] req_addr;

  if (num_cache_p == 1) begin
    assign req_addr = {
      {(hbm_channel_addr_width_p-cache_bank_addr_width_p){1'b0}},
      rr_pkt_lo.addr[0+:cache_bank_addr_width_p]
    };
  end
  else begin
    assign req_addr = {
      {(hbm_channel_addr_width_p-lg_num_cache_lp-cache_bank_addr_width_p){1'b0}},
      rr_tag_lo,
      rr_pkt_lo.addr[0+:cache_bank_addr_width_p]
    };
  end

  logic req_afifo_enq;
  logic req_afifo_full;

  bsg_async_fifo #(
    .lg_size_p(`BSG_SAFE_CLOG2(4*num_cache_p))
    ,.width_p(1+hbm_channel_addr_width_p)
  ) req_afifo (
    .w_clk_i(core_clk_i)
    ,.w_reset_i(core_reset_i)
    ,.w_enq_i(req_afifo_enq)
    ,.w_data_i({rr_pkt_lo.write_not_read, req_addr})
    ,.w_full_o(req_afifo_full)
  
    ,.r_clk_i(hbm_clk_i) 
    ,.r_reset_i(hbm_reset_i)
    ,.r_deq_i(hbm_req_yumi_i)
    ,.r_data_o({hbm_write_not_read_o, hbm_ch_addr_o})
    ,.r_valid_o(hbm_req_v_o)
  );


  //  RX
  //
  logic rx_v_li;
  logic rx_ready_lo;

  bsg_cache_to_ramulator_hbm_rx #(
    .num_cache_p(num_cache_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.hbm_data_width_p(hbm_data_width_p)
  ) rx0 (
    .core_clk_i(core_clk_i)
    ,.core_reset_i(core_reset_i)

    ,.v_i(rx_v_li)
    ,.tag_i(rr_tag_lo)
    ,.ready_o(rx_ready_lo)

    ,.dma_data_o(dma_data_o)
    ,.dma_data_v_o(dma_data_v_o)
    ,.dma_data_ready_i(dma_data_ready_i)

    ,.hbm_clk_i(hbm_clk_i)
    ,.hbm_reset_i(hbm_reset_i)

    ,.hbm_data_v_i(hbm_data_v_i)
    ,.hbm_data_i(hbm_data_i)
  );


  //  TX
  //
  logic tx_v_li;
  logic tx_ready_lo;

  bsg_cache_to_ramulator_hbm_tx #(
    .num_cache_p(num_cache_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.hbm_data_width_p(hbm_data_width_p)
  ) tx0 (
    .core_clk_i(core_clk_i)
    ,.core_reset_i(core_reset_i)

    ,.v_i(tx_v_li)
    ,.tag_i(rr_tag_lo)
    ,.ready_o(tx_ready_lo)

    ,.dma_data_i(dma_data_i)
    ,.dma_data_v_i(dma_data_v_i)
    ,.dma_data_yumi_o(dma_data_yumi_o)

    ,.hbm_clk_i(hbm_clk_i)
    ,.hbm_reset_i(hbm_reset_i)

    ,.hbm_data_v_o(hbm_data_v_o)
    ,.hbm_data_o(hbm_data_o)
    ,.hbm_data_yumi_i(hbm_data_yumi_i)
  );



  //  handshake logic
  //
  always_comb begin

    rr_yumi_li = 1'b0;
    rx_v_li = 1'b0;
    tx_v_li = 1'b0;
    req_afifo_enq = 1'b0;

    if (rr_pkt_lo.write_not_read) begin
      rr_yumi_li = rr_v_lo & ~req_afifo_full & tx_ready_lo;
      tx_v_li = rr_v_lo & ~req_afifo_full & tx_ready_lo;
      req_afifo_enq = rr_v_lo & ~req_afifo_full & tx_ready_lo;
    end
    else begin
      rr_yumi_li = rr_v_lo & ~req_afifo_full & rx_ready_lo;
      rx_v_li = rr_v_lo & ~req_afifo_full & rx_ready_lo;
      req_afifo_enq = rr_v_lo & ~req_afifo_full & rx_ready_lo;
    end

  end




endmodule
