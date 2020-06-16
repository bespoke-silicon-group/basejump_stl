/**
 *    bsg_cache_to_test_dram.v
 *
 *    multiple caches can attach here and connect to one test dram channel.
 *
 *    @author tommy
 *
 */


module bsg_cache_to_test_dram 
  import bsg_cache_pkg::*;
  #(parameter num_cache_p="inv"
    , parameter num_subcache_p=1 // number of caches that are grouped together for the first-level of round robin.
    , parameter addr_width_p="inv" // cache addr (byte)
    , parameter data_width_p="inv" // cache data width
    , parameter block_size_in_words_p="inv" // cache block_size (word)
    , parameter cache_bank_addr_width_p="inv" // actual number of bits used for address (byte)

    , parameter dram_channel_addr_width_p="inv" // dram channel addr
    , parameter dram_data_width_p="inv" // dram channel data width

    , parameter dma_data_width_p=data_width_p // cache dma data width 

    , parameter num_cache_group_lp=(num_cache_p/num_subcache_p)
    , parameter lg_num_cache_group_lp=`BSG_SAFE_CLOG2(num_cache_group_lp)

    , parameter num_req_lp = (block_size_in_words_p*data_width_p/dram_data_width_p) // number of DRAM requests sent per cache miss.
    , parameter lg_num_req_lp = `BSG_SAFE_CLOG2(num_req_lp)
    , parameter dram_byte_offset_width_lp = `BSG_SAFE_CLOG2(dram_data_width_p>>3)

    , parameter lg_num_cache_lp=`BSG_SAFE_CLOG2(num_cache_p)
    , parameter lg_num_subcache_lp=`BSG_SAFE_CLOG2(num_subcache_p)
    , parameter dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
  )
  (
    // vcache dma interface
    input core_clk_i
    , input core_reset_i

    , input [num_cache_p-1:0][dma_pkt_width_lp-1:0] dma_pkt_i
    , input [num_cache_p-1:0] dma_pkt_v_i
    , output logic [num_cache_p-1:0] dma_pkt_yumi_o

    , output logic [num_cache_p-1:0][dma_data_width_p-1:0] dma_data_o
    , output logic [num_cache_p-1:0] dma_data_v_o
    , input [num_cache_p-1:0] dma_data_ready_i

    , input [num_cache_p-1:0][dma_data_width_p-1:0] dma_data_i
    , input [num_cache_p-1:0] dma_data_v_i
    , output logic [num_cache_p-1:0] dma_data_yumi_o

    // dram
    , input dram_clk_i
    , input dram_reset_i

    // dram request channel (valid-yumi)
    , output logic dram_req_v_o
    , output logic dram_write_not_read_o
    , output logic [dram_channel_addr_width_p-1:0] dram_ch_addr_o // read done addr
    , input dram_req_yumi_i

    // dram write data channel (valid-yumi)
    , output logic dram_data_v_o
    , output logic [dram_data_width_p-1:0] dram_data_o
    , input dram_data_yumi_i

    // dram read data channel (valid-only)
    , input dram_data_v_i
    , input [dram_data_width_p-1:0] dram_data_i
    , input [dram_channel_addr_width_p-1:0] dram_ch_addr_i // the address of incoming data
  );


  // dma pkt
  //
  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s [num_cache_p-1:0] dma_pkt;
  assign dma_pkt = dma_pkt_i;


  // round robin for subcaches
  //
  logic [num_cache_group_lp-1:0] sub_rr_v_lo;
  bsg_cache_dma_pkt_s [num_cache_group_lp-1:0] sub_rr_data_lo;
  logic [num_cache_group_lp-1:0][lg_num_subcache_lp-1:0] sub_rr_tag_lo;
  logic [num_cache_group_lp-1:0] sub_rr_yumi_li;

  for (genvar i = 0; i < num_cache_group_lp; i++) begin
    bsg_round_robin_n_to_1 #(
      .width_p(dma_pkt_width_lp)
      ,.num_in_p(num_subcache_p)
      ,.strict_p(0)
    ) sub_rr0 (
      .clk_i(core_clk_i)
      ,.reset_i(core_reset_i)

      ,.v_i(dma_pkt_v_i[num_subcache_p*i+:num_subcache_p])
      ,.data_i(dma_pkt[num_subcache_p*i+:num_subcache_p])
      ,.yumi_o(dma_pkt_yumi_o[num_subcache_p*i+:num_subcache_p])

      ,.v_o(sub_rr_v_lo[i])
      ,.data_o(sub_rr_data_lo[i])
      ,.tag_o(sub_rr_tag_lo[i])
      ,.yumi_i(sub_rr_yumi_li[i])
    );
  end


  // round robin for cache groups
  //
  logic cg_rr_v_lo;
  logic cg_rr_yumi_li;
  bsg_cache_dma_pkt_s cg_rr_data_lo;
  logic [lg_num_cache_group_lp-1:0] cg_rr_tag_lo;

  logic [lg_num_cache_lp-1:0] rr_tag_r, rr_tag_n;
  bsg_cache_dma_pkt_s dma_pkt_r, dma_pkt_n;

  bsg_round_robin_n_to_1 #(
    .width_p(dma_pkt_width_lp)
    ,.num_in_p(num_cache_group_lp)
    ,.strict_p(0)
  ) rr0 (
    .clk_i(core_clk_i)
    ,.reset_i(core_reset_i)

    ,.v_i(sub_rr_v_lo)
    ,.data_i(sub_rr_data_lo)
    ,.yumi_o(sub_rr_yumi_li)

    ,.v_o(cg_rr_v_lo)
    ,.data_o(cg_rr_data_lo)
    ,.tag_o(cg_rr_tag_lo)
    ,.yumi_i(cg_rr_yumi_li)
  );

  logic [lg_num_cache_lp-1:0] final_rr_tag;

  if (num_subcache_p == 1) begin
    assign final_rr_tag = cg_rr_tag_lo;
  end
  else begin
    if (num_cache_group_lp == 1) begin
      assign final_rr_tag = sub_rr_tag_lo;
    end
    else begin
      assign final_rr_tag = {cg_rr_tag_lo, sub_rr_tag_lo[cg_rr_tag_lo]};
    end
  end


  // request counter
  //
  logic counter_clear;
  logic counter_up;
  logic [lg_num_req_lp-1:0] count_r; // this counts the number of DRAM requests sent for a cache miss.

  bsg_counter_clear_up #(
    .max_val_p(num_req_lp-1)
    ,.init_val_p(0)
  ) ccu0 (
    .clk_i(core_clk_i)
    ,.reset_i(core_reset_i)
    ,.clear_i(counter_clear)
    ,.up_i(counter_up)
    ,.count_o(count_r)
  );

  logic [dram_channel_addr_width_p-1:0] dram_req_addr;
  
  // request async fifo
  //
  logic req_afifo_enq;
  logic req_afifo_full;

  bsg_async_fifo #(
    .lg_size_p(`BSG_SAFE_CLOG2(4*num_cache_p))
    ,.width_p(1+dram_channel_addr_width_p)
  ) req_afifo (
    .w_clk_i(core_clk_i)
    ,.w_reset_i(core_reset_i)
    ,.w_enq_i(req_afifo_enq)
    ,.w_data_i({dma_pkt_n.write_not_read, dram_req_addr})
    ,.w_full_o(req_afifo_full)

    ,.r_clk_i(dram_clk_i)
    ,.r_reset_i(dram_reset_i)
    ,.r_deq_i(dram_req_yumi_i)
    ,.r_data_o({dram_write_not_read_o, dram_ch_addr_o})
    ,.r_valid_o(dram_req_v_o)
  );


  // RX
  //
  bsg_cache_to_test_dram_rx #(
    .num_cache_p(num_cache_p)
    ,.num_subcache_p(num_subcache_p)
    ,.data_width_p(data_width_p)
    ,.dma_data_width_p(dma_data_width_p)
    ,.dram_data_width_p(dram_data_width_p)
    ,.dram_channel_addr_width_p(dram_channel_addr_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
  ) rx0 (
    .core_clk_i(core_clk_i)
    ,.core_reset_i(core_reset_i)

    ,.dma_data_o(dma_data_o)
    ,.dma_data_v_o(dma_data_v_o)
    ,.dma_data_ready_i(dma_data_ready_i)

    ,.dram_clk_i(dram_clk_i)
    ,.dram_reset_i(dram_reset_i)

    ,.dram_data_v_i(dram_data_v_i)
    ,.dram_data_i(dram_data_i)
    ,.dram_ch_addr_i(dram_ch_addr_i)
  );


  // TX
  //
  logic tx_v_li;
  logic tx_ready_lo;

  bsg_cache_to_test_dram_tx #(
    .num_cache_p(num_cache_p)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
    ,.dma_data_width_p(dma_data_width_p)
    ,.dram_data_width_p(dram_data_width_p)
  ) tx0 (
    .core_clk_i(core_clk_i)
    ,.core_reset_i(core_reset_i)

    ,.v_i(tx_v_li)
    ,.tag_i(rr_tag_n)
    ,.ready_o(tx_ready_lo)

    ,.dma_data_i(dma_data_i)
    ,.dma_data_v_i(dma_data_v_i)
    ,.dma_data_yumi_o(dma_data_yumi_o)

    ,.dram_clk_i(dram_clk_i)
    ,.dram_reset_i(dram_reset_i)

    ,.dram_data_v_o(dram_data_v_o)
    ,.dram_data_o(dram_data_o)
    ,.dram_data_yumi_i(dram_data_yumi_i)
  );
 

  if (num_req_lp == 1) begin
    assign counter_up = 1'b0;
    assign counter_clear = 1'b0;
    assign cg_rr_yumi_li = cg_rr_v_lo & ~req_afifo_full & (cg_rr_data_lo.write_not_read ? tx_ready_lo : 1'b1);
    assign req_afifo_enq = cg_rr_v_lo & ~req_afifo_full & (cg_rr_data_lo.write_not_read ? tx_ready_lo : 1'b1);
    assign tx_v_li = cg_rr_v_lo & ~req_afifo_full & cg_rr_data_lo.write_not_read & tx_ready_lo;
    assign rr_tag_n = final_rr_tag;
    assign dma_pkt_n = cg_rr_data_lo;
  end
  else begin

    always_comb begin
      counter_up = 1'b0;
      counter_clear = 1'b0;
      cg_rr_yumi_li = 1'b0;
      req_afifo_enq = 1'b0;
      tx_v_li = 1'b0;
      rr_tag_n = rr_tag_r;
      dma_pkt_n = dma_pkt_r;

      if (count_r == 0) begin
        if (cg_rr_v_lo & ~req_afifo_full & (cg_rr_data_lo.write_not_read ? tx_ready_lo : 1'b1)) begin
          counter_up = 1'b1;
          cg_rr_yumi_li = 1'b1;
          req_afifo_enq = 1'b1;
          tx_v_li = cg_rr_data_lo.write_not_read;
          rr_tag_n = final_rr_tag;
          dma_pkt_n = cg_rr_data_lo;
        end
      end
      else if (count_r == num_req_lp-1) begin
        if (~req_afifo_full & (dma_pkt_r.write_not_read ? tx_ready_lo : 1'b1)) begin
          counter_clear = 1'b1;
          req_afifo_enq = 1'b1;
          tx_v_li = dma_pkt_r.write_not_read;
        end
      end
      else begin
        if (~req_afifo_full & (dma_pkt_r.write_not_read ? tx_ready_lo : 1'b1)) begin
          counter_up = 1'b1;
          req_afifo_enq = 1'b1;
          tx_v_li = dma_pkt_r.write_not_read;
        end
      end      
    end

  end


  always_ff @ (posedge core_clk_i) begin
    if (core_reset_i) begin
      dma_pkt_r <= '0;
      rr_tag_r <= '0;
    end
    else begin
      dma_pkt_r <= dma_pkt_n;
      rr_tag_r <= rr_tag_n;
    end
  end


  // address logic
  // cache_id goes to MSBs.
  // cache_id can be decomposed into cache_group id in upper bits, and subcache_id in lower bits.
  if (num_cache_p == 1) begin
    if (num_req_lp == 1) begin
      assign dram_req_addr = {
        {(dram_channel_addr_width_p-cache_bank_addr_width_p){1'b0}},
        dma_pkt_n.addr[cache_bank_addr_width_p-1:dram_byte_offset_width_lp],
        {dram_byte_offset_width_lp{1'b0}}
      };
    end
    else begin
      assign dram_req_addr = {
        {(dram_channel_addr_width_p-cache_bank_addr_width_p){1'b0}},
        dma_pkt_n.addr[cache_bank_addr_width_p-1:dram_byte_offset_width_lp+lg_num_req_lp],
        count_r,
        {dram_byte_offset_width_lp{1'b0}}
      };
    end
  end
  else begin
    if (num_req_lp == 1) begin
      assign dram_req_addr = {
        rr_tag_n,
        {(dram_channel_addr_width_p-cache_bank_addr_width_p-lg_num_cache_lp){1'b0}},
        dma_pkt_n.addr[cache_bank_addr_width_p-1:dram_byte_offset_width_lp],
        {dram_byte_offset_width_lp{1'b0}}
      };
    end
    else begin
      assign dram_req_addr = {
        rr_tag_n,
        {(dram_channel_addr_width_p-cache_bank_addr_width_p-lg_num_cache_lp){1'b0}},
        dma_pkt_n.addr[cache_bank_addr_width_p-1:dram_byte_offset_width_lp+lg_num_req_lp],
        count_r,
        {dram_byte_offset_width_lp{1'b0}}
      };
    end
  end


endmodule
