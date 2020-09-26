/**
 *  bsg_cache_dma.v
 *
 *  DMA engine.
 *
 *  @author tommy
 *
 */

`include "bsg_defines.v"

module bsg_cache_dma
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="inv"
    ,parameter ways_p="inv"
    ,parameter dma_data_width_p=data_width_p

    ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    ,parameter data_mask_width_lp=(data_width_p>>3)
    ,parameter dma_data_mask_width_lp=(dma_data_width_p>>3)
    ,parameter burst_len_lp=(block_size_in_words_p*data_width_p/dma_data_width_p)
    ,parameter lg_burst_len_lp=`BSG_SAFE_CLOG2(burst_len_lp)
    ,parameter burst_size_in_words_lp=(dma_data_width_p/data_width_p)
    ,parameter lg_burst_size_in_words_lp=`BSG_SAFE_CLOG2(burst_size_in_words_lp)

    ,parameter data_mem_els_lp=(sets_p*burst_len_lp)
    ,parameter lg_data_mem_els_lp=`BSG_SAFE_CLOG2(data_mem_els_lp)

    ,parameter bsg_cache_dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
  
    ,parameter debug_p=0
  )
  (
    input clk_i
    ,input reset_i

    ,input bsg_cache_dma_cmd_e dma_cmd_i
    ,input [lg_ways_lp-1:0] dma_way_i
    ,input [addr_width_p-1:0] dma_addr_i
    ,output logic done_o

    ,output logic [data_width_p-1:0] snoop_word_o

    ,output logic [bsg_cache_dma_pkt_width_lp-1:0] dma_pkt_o
    ,output logic dma_pkt_v_o
    ,input dma_pkt_yumi_i

    ,input [dma_data_width_p-1:0] dma_data_i
    ,input dma_data_v_i
    ,output logic dma_data_ready_o

    ,output logic [dma_data_width_p-1:0] dma_data_o
    ,output logic dma_data_v_o
    ,input dma_data_yumi_i

    ,output logic data_mem_v_o
    ,output logic data_mem_w_o
    ,output logic [lg_data_mem_els_lp-1:0] data_mem_addr_o
    ,output logic [ways_p-1:0][dma_data_mask_width_lp-1:0] data_mem_w_mask_o
    ,output logic [ways_p-1:0][dma_data_width_p-1:0] data_mem_data_o
    ,input [ways_p-1:0][dma_data_width_p-1:0] data_mem_data_i

    ,output logic dma_evict_o // data eviction in progress
  );

  // localparam
  //
  localparam counter_width_lp=`BSG_SAFE_CLOG2(burst_len_lp+1);
  localparam byte_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3);

  // dma states
  //
  typedef enum logic [1:0] {
    IDLE
    ,GET_FILL_DATA
    ,SEND_EVICT_DATA
  } dma_state_e;

  dma_state_e dma_state_n;
  dma_state_e dma_state_r;


  // dma counter
  //
  logic counter_clear;
  logic counter_up;
  logic [counter_width_lp-1:0] counter_r;

  bsg_counter_clear_up #(
    .max_val_p(burst_len_lp)
  ) dma_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(counter_clear)
    ,.up_i(counter_up)
    ,.count_o(counter_r)
  );

  wire counter_fill_max = counter_r == (burst_len_lp-1);
  wire counter_evict_max = counter_r == burst_len_lp;


  // dma packet
  //
  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s dma_pkt;

  // in fifo
  //
  logic in_fifo_v_lo;
  logic [dma_data_width_p-1:0] in_fifo_data_lo;
  logic in_fifo_yumi_li;

  bsg_fifo_1r1w_small #(
    .width_p(dma_data_width_p)
    ,.els_p((burst_len_lp<2) ? 2 : burst_len_lp)
  ) in_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(dma_data_i)
    ,.v_i(dma_data_v_i)
    ,.ready_o(dma_data_ready_o)
    ,.v_o(in_fifo_v_lo)
    ,.data_o(in_fifo_data_lo)
    ,.yumi_i(in_fifo_yumi_li)
  );

  // out fifo
  //
  logic out_fifo_v_li;
  logic out_fifo_ready_lo;
  logic [dma_data_width_p-1:0] out_fifo_data_li;

  bsg_two_fifo #(
    .width_p(dma_data_width_p)
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

  assign dma_pkt_o = dma_pkt;

  logic [ways_p-1:0] dma_way_mask;

  bsg_decode #(
    .num_out_p(ways_p)
  ) dma_way_demux (
    .i(dma_way_i)
    ,.o(dma_way_mask)
  );

  bsg_expand_bitmask #(
    .in_width_p(ways_p)
    ,.expand_p(dma_data_mask_width_lp)
  ) expand0 (
    .i(dma_way_mask)
    ,.o(data_mem_w_mask_o)
  );

  if (burst_len_lp == 1) begin
    assign data_mem_addr_o = dma_addr_i[byte_offset_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  end
  //else if (burst_len_lp == block_size_in_words_p) begin
  //  assign data_mem_addr_o = {
  //    dma_addr_i[byte_offset_width_lp+lg_block_size_in_words_lp+:lg_sets_lp],
  //    counter_r[0+:lg_burst_len_lp]
  //  };
  //end
  else begin
    assign data_mem_addr_o = {
      dma_addr_i[byte_offset_width_lp+lg_block_size_in_words_lp+:lg_sets_lp],
      counter_r[0+:lg_burst_len_lp]
    };
  end
  
  assign data_mem_data_o = {ways_p{in_fifo_data_lo}};

  bsg_mux #(
    .width_p(dma_data_width_p)
    ,.els_p(ways_p)
  ) write_data_mux (
    .data_i(data_mem_data_i)
    ,.sel_i(dma_way_i)
    ,.data_o(out_fifo_data_li)
  );

  always_comb begin
    done_o = 1'b0;

    dma_pkt_v_o = 1'b0;
    dma_pkt.write_not_read = 1'b0;
    dma_pkt.addr = {
      dma_addr_i[addr_width_p-1:byte_offset_width_lp+lg_block_size_in_words_lp],
      {(byte_offset_width_lp+lg_block_size_in_words_lp){1'b0}}
    };

    data_mem_v_o = 1'b0;
    data_mem_w_o = 1'b0;

    in_fifo_yumi_li = 1'b0;
    dma_state_n = IDLE;
    out_fifo_v_li = 1'b0;
    counter_clear = 1'b0;
    counter_up = 1'b0;

    dma_evict_o = 1'b0;

    case (dma_state_r)

      // wait for dma_cmd from bsg_cache_miss.
      // when transitioning from GET_FILL_DATA or SEND_EVICT_DATA state,
      // make sure that counter is cleared to zero.
      IDLE: begin
        counter_clear = 1'b0;
        counter_up = 1'b0;
        data_mem_v_o = 1'b0;
        dma_pkt_v_o = 1'b0;
        dma_pkt.write_not_read = 1'b0;
        done_o = 1'b0;
        dma_state_n = IDLE;

        case (dma_cmd_i)
          e_dma_send_fill_addr: begin
            dma_pkt_v_o = 1'b1;
            dma_pkt.write_not_read = 1'b0;
            done_o = dma_pkt_yumi_i;
            dma_state_n = IDLE;
          end

          e_dma_send_evict_addr: begin
            dma_pkt_v_o = 1'b1;
            dma_pkt.write_not_read = 1'b1;
            done_o = dma_pkt_yumi_i;
            dma_state_n = IDLE;
          end

          e_dma_get_fill_data: begin
            counter_clear = 1'b1;
            dma_state_n = GET_FILL_DATA;
          end
      
          e_dma_send_evict_data: begin
            // we are reading the first word, as we are transitioning out.
            // so the counter is incremented to 1.
            counter_clear = 1'b1;
            counter_up = 1'b1;
            data_mem_v_o = 1'b1;
            dma_state_n = SEND_EVICT_DATA;
          end

          e_dma_nop: begin
            // nothing happens.
          end

          default: begin
            // this should never happen.
          end
        endcase
      end

      // receive the block data from dma_data_i 
      // and write into data_mem word by word.
      GET_FILL_DATA: begin
        dma_state_n = counter_fill_max & in_fifo_v_lo
          ? IDLE
          : GET_FILL_DATA;
        data_mem_v_o = in_fifo_v_lo;
        data_mem_w_o = in_fifo_v_lo;
        in_fifo_yumi_li = in_fifo_v_lo;

        counter_up = in_fifo_v_lo & ~counter_fill_max;
        counter_clear = in_fifo_v_lo & counter_fill_max;
        done_o = counter_fill_max & in_fifo_v_lo;
      end

      // read the requested block from data_mem and send it out over
      // dma_data_o word by word.
      SEND_EVICT_DATA: begin
        // counter_r in this context means the number of words read from
        // data_mem so far.
        dma_state_n = counter_evict_max & out_fifo_ready_lo
          ? IDLE
          : SEND_EVICT_DATA;
        
        counter_up = out_fifo_ready_lo & ~counter_evict_max;
        counter_clear = out_fifo_ready_lo & counter_evict_max;

        out_fifo_v_li = 1'b1;

        data_mem_v_o = out_fifo_ready_lo & ~counter_evict_max;

        done_o = counter_evict_max & out_fifo_ready_lo;

        dma_evict_o = 1'b1;
      end

      default: begin
        // this should never happen, but if it does, then go back to IDLE.
        dma_state_n = IDLE;
      end
    endcase
  end

  
  // snoop_word register
  // As the fill data is coming in, grab the word that matches the block
  // offset, so that we don't have to read the data_mem again to return the
  // load data.
  logic [lg_burst_size_in_words_lp-1:0] snoop_word_offset;
  logic snoop_word_we;
  logic [data_width_p-1:0] snoop_word_n;

  assign snoop_word_offset = dma_addr_i[byte_offset_width_lp+:lg_burst_size_in_words_lp];

  if (burst_len_lp == 1) begin
    assign snoop_word_we = (dma_state_r == GET_FILL_DATA) & in_fifo_v_lo;
  end
  else if (burst_len_lp == block_size_in_words_p) begin
    assign snoop_word_we = (dma_state_r == GET_FILL_DATA) & in_fifo_v_lo
      & (counter_r[0+:lg_burst_len_lp] == dma_addr_i[byte_offset_width_lp+:lg_burst_len_lp]);
  end
  else begin
    assign snoop_word_we = (dma_state_r == GET_FILL_DATA) & in_fifo_v_lo
      & (counter_r[0+:lg_burst_len_lp] == dma_addr_i[byte_offset_width_lp+lg_burst_size_in_words_lp+:lg_burst_len_lp]);
  end


  bsg_mux #(
    .width_p(data_width_p)
    ,.els_p(burst_size_in_words_lp)
  ) snoop_mux0 (
    .data_i(in_fifo_data_lo)
    ,.sel_i(snoop_word_offset)
    ,.data_o(snoop_word_n)
  );

   // synopsys sync_set_reset "reset_i"
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      dma_state_r <= IDLE;
    end
    else begin
      dma_state_r <= dma_state_n;

      if (snoop_word_we) begin
        snoop_word_o <= snoop_word_n;
      end 

    end
  end

  // synopsys translate_off
  
  always_ff @ (posedge clk_i) begin
    if (debug_p) begin
      if (dma_pkt_v_o & dma_pkt_yumi_i) begin
        $display("<VCACHE> DMA_PKT we:%0d addr:%8h // %8t",
          dma_pkt.write_not_read, dma_pkt.addr, $time);
      end
    end
  end
  // synopsys translate_on

endmodule
