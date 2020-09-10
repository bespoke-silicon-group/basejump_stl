/**
 *    bsg_cache_non_blocking_dma.v
 *
 *    DMA engine
 *
 *    @author tommy
 *
 */


`include "bsg_defines.v"

module bsg_cache_non_blocking_dma
  import bsg_cache_non_blocking_pkg::*;
  #(parameter addr_width_p="inv"
    , parameter data_width_p="inv"
    , parameter block_size_in_words_p="inv"
    , parameter sets_p="inv"
    , parameter ways_p="inv"
   
    , parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    , parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p) 
    , parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    , parameter byte_sel_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    , parameter tag_width_lp=(addr_width_p-lg_sets_lp-lg_block_size_in_words_lp-byte_sel_width_lp)

    , parameter dma_cmd_width_lp=`bsg_cache_non_blocking_dma_cmd_width(ways_p,sets_p,tag_width_lp)
    , parameter dma_pkt_width_lp=`bsg_cache_non_blocking_dma_pkt_width(addr_width_p)

    , parameter data_mem_pkt_width_lp=
      `bsg_cache_non_blocking_data_mem_pkt_width(ways_p,sets_p,block_size_in_words_p,data_width_p)
  )
  (
    input clk_i
    , input reset_i

    // MHU
    , input [dma_cmd_width_lp-1:0] dma_cmd_i
    , input dma_cmd_v_i

    , output logic [dma_cmd_width_lp-1:0] dma_cmd_return_o
    , output logic done_o
    , output logic pending_o
    , input ack_i

    , output logic [lg_ways_lp-1:0] curr_dma_way_id_o
    , output logic [lg_sets_lp-1:0] curr_dma_index_o
    , output logic curr_dma_v_o

    // data_mem
    , output logic data_mem_pkt_v_o
    , output logic [data_mem_pkt_width_lp-1:0] data_mem_pkt_o
    , input [data_width_p-1:0] data_mem_data_i

    // DMA request
    , output logic [dma_pkt_width_lp-1:0] dma_pkt_o
    , output logic dma_pkt_v_o
    , input dma_pkt_yumi_i

    // DMA data in
    , input [data_width_p-1:0] dma_data_i
    , input dma_data_v_i
    , output logic dma_data_ready_o    

    // DMA data out
    , output logic [data_width_p-1:0] dma_data_o
    , output logic dma_data_v_o
    , input dma_data_yumi_i
  );

  
  // localparam
  //
  localparam counter_width_lp=`BSG_SAFE_CLOG2(block_size_in_words_p+1);
  localparam block_offset_width_lp=byte_sel_width_lp+lg_block_size_in_words_lp;
  localparam data_mask_width_lp=(data_width_p>>3);


  // casting structs
  //
  `declare_bsg_cache_non_blocking_dma_cmd_s(ways_p,sets_p,tag_width_lp);
  `declare_bsg_cache_non_blocking_dma_pkt_s(addr_width_p);
 
  bsg_cache_non_blocking_dma_cmd_s dma_cmd_in;
  bsg_cache_non_blocking_dma_cmd_s dma_cmd_r;
  bsg_cache_non_blocking_dma_pkt_s dma_pkt;

  assign dma_cmd_in = dma_cmd_i;
  assign dma_cmd_return_o = dma_cmd_r;
  assign dma_pkt_o = dma_pkt;

  `declare_bsg_cache_non_blocking_data_mem_pkt_s(ways_p,sets_p,block_size_in_words_p,data_width_p);
  bsg_cache_non_blocking_data_mem_pkt_s data_mem_pkt;
  
  assign data_mem_pkt_o = data_mem_pkt; 

  // data_cmd dff
  //
  logic dma_cmd_dff_en;

  bsg_dff_reset_en #(
    .width_p(dma_cmd_width_lp)
  ) dma_cmd_dff (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.en_i(dma_cmd_dff_en)
    ,.data_i(dma_cmd_in)
    ,.data_o(dma_cmd_r)
  );

  // dma states
  //
  typedef enum logic [2:0] {
    DMA_IDLE
    ,SEND_REFILL_ADDR
    ,SEND_EVICT_ADDR
    ,SEND_EVICT_DATA
    ,RECV_REFILL_DATA
    ,DMA_DONE
  } dma_state_e;


  dma_state_e dma_state_r;
  dma_state_e dma_state_n;

  // dma counter
  //
  logic counter_clear;
  logic counter_up;
  logic [counter_width_lp-1:0] counter_r;

  bsg_counter_clear_up #(
    .max_val_p(block_size_in_words_p)
    ,.init_val_p(0)
  ) dma_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(counter_clear)
    ,.up_i(counter_up)
    ,.count_o(counter_r)
  );

  logic counter_fill_max;
  logic counter_evict_max;

  assign counter_fill_max = counter_r == (block_size_in_words_p-1);
  assign counter_evict_max = counter_r == block_size_in_words_p; 

  // in fifo
  //
  logic in_fifo_v_lo;
  logic [data_width_p-1:0] in_fifo_data_lo;
  logic in_fifo_yumi_li;
  
  bsg_fifo_1r1w_small #(
    .width_p(data_width_p)
    ,.els_p(block_size_in_words_p)
  ) in_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.data_i(dma_data_i)
    ,.v_i(dma_data_v_i)
    ,.ready_o(dma_data_ready_o)

    ,.data_o(in_fifo_data_lo)
    ,.v_o(in_fifo_v_lo)
    ,.yumi_i(in_fifo_yumi_li)
  );

  // out fifo
  //
  logic out_fifo_v_li;
  logic out_fifo_ready_lo;
  logic [data_width_p-1:0] out_fifo_data_li;
  
  bsg_two_fifo #(
    .width_p(data_width_p)
  ) out_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(out_fifo_v_li)
    ,.data_i(out_fifo_data_li)
    ,.ready_o(out_fifo_ready_lo)

    ,.v_o(dma_data_v_o)
    ,.data_o(dma_data_o)
    ,.yumi_i(dma_data_yumi_i)
  );


  // comb logic
  //
  assign out_fifo_data_li = data_mem_data_i;

  logic [addr_width_p-1:0] dma_pkt_refill_addr;
  logic [addr_width_p-1:0] dma_pkt_evict_addr;

  assign dma_pkt_refill_addr = {
    dma_cmd_r.refill_tag,
    dma_cmd_r.index,
    {block_offset_width_lp{1'b0}}
  };

  assign dma_pkt_evict_addr = {
    dma_cmd_r.evict_tag,
    dma_cmd_r.index,
    {block_offset_width_lp{1'b0}}
  };


  always_comb begin

    done_o = 1'b0;
    pending_o = 1'b0;

    dma_cmd_dff_en = 1'b0;

    counter_clear = 1'b0;
    counter_up = 1'b0;
    
    out_fifo_v_li = 1'b0;
    in_fifo_yumi_li = 1'b0;

    data_mem_pkt_v_o = 1'b0;
    data_mem_pkt.write_not_read = 1'b0;
    data_mem_pkt.way_id = dma_cmd_r.way_id;
    data_mem_pkt.addr = {
      dma_cmd_r.index,
      counter_r[0+:lg_block_size_in_words_lp]
    };
    // for load
    data_mem_pkt.sigext_op = 1'b0;
    data_mem_pkt.size_op = (2)'($clog2(data_width_p>>3));
    data_mem_pkt.byte_sel = (byte_sel_width_lp)'(0);
    // for store
    data_mem_pkt.mask_op = 1'b1;
    data_mem_pkt.mask = {data_mask_width_lp{1'b1}};
    data_mem_pkt.data = in_fifo_data_lo;
    
    dma_pkt_v_o = 1'b0;
    dma_pkt.write_not_read = 1'b0;
    dma_pkt.addr = dma_pkt_refill_addr;
    
  
    case (dma_state_r)

      // Wait for dma_cmd from MHU.
      DMA_IDLE: begin
        dma_cmd_dff_en = dma_cmd_v_i;

        dma_state_n = dma_cmd_v_i
          ? (dma_cmd_in.refill ? SEND_REFILL_ADDR : SEND_EVICT_ADDR)
          : DMA_IDLE;
      end

      // Send refill address by dma_req channel.
      SEND_REFILL_ADDR: begin
        dma_pkt_v_o = 1'b1;
        dma_pkt.write_not_read = 1'b0;
        dma_pkt.addr = dma_pkt_refill_addr;

        pending_o = 1'b1;

        dma_state_n = dma_pkt_yumi_i
          ? (dma_cmd_r.evict ? SEND_EVICT_ADDR : RECV_REFILL_DATA)
          : SEND_REFILL_ADDR;
      end
  
      // Send evict address by dma_req channel.
      SEND_EVICT_ADDR: begin
        data_mem_pkt_v_o = dma_pkt_yumi_i; // read the first word in block.

        counter_up = dma_pkt_yumi_i;
        counter_clear = dma_pkt_yumi_i;

        dma_pkt_v_o = 1'b1;
        dma_pkt.write_not_read = 1'b1;
        dma_pkt.addr = dma_pkt_evict_addr;

        pending_o = 1'b1;

        dma_state_n = dma_pkt_yumi_i
          ? SEND_EVICT_DATA
          : SEND_EVICT_ADDR;
      end

      // Read the cache block word by word, send it out by dma_data_o channel.
      SEND_EVICT_DATA: begin
        data_mem_pkt_v_o = out_fifo_ready_lo & ~counter_evict_max;
      
        out_fifo_v_li = 1'b1;

        counter_up = out_fifo_ready_lo & ~counter_evict_max;
        counter_clear = out_fifo_ready_lo & counter_evict_max;
          
        pending_o = 1'b1;
  
        dma_state_n = (out_fifo_ready_lo & counter_evict_max)
          ? (dma_cmd_r.refill ? RECV_REFILL_DATA : DMA_DONE) 
          : SEND_EVICT_DATA;
      end

      // Receive the cache block word by word from dma_data_i channel,
      // and write it to data_mem.
      RECV_REFILL_DATA: begin
        data_mem_pkt_v_o = in_fifo_v_lo;
        data_mem_pkt.write_not_read = 1'b1;
        in_fifo_yumi_li = in_fifo_v_lo;

        counter_up = in_fifo_v_lo & ~counter_fill_max;
        counter_clear = in_fifo_v_lo & counter_fill_max;

        pending_o = 1'b1;
      
        dma_state_n = in_fifo_v_lo & counter_fill_max
          ? DMA_DONE
          : RECV_REFILL_DATA;
      end

      // DMA transaction is over, and wait for MHU to acknowledge it.
      DMA_DONE: begin
        done_o = 1'b1;
        counter_clear = ack_i;
        dma_state_n = ack_i
          ? DMA_IDLE
          : DMA_DONE;
      end

      // this should never happen, but if it does, return to IDLE.
      default: begin
        dma_state_n = DMA_IDLE;
      end

    endcase 

  end

  assign curr_dma_v_o = (dma_state_r != DMA_IDLE);
  assign curr_dma_way_id_o = dma_cmd_r.way_id;
  assign curr_dma_index_o = dma_cmd_r.index;


  // synopsys sync_set_reset "reset_i"
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      dma_state_r <= DMA_IDLE;
    end
    else begin
      dma_state_r <= dma_state_n;
    end
  end



endmodule
