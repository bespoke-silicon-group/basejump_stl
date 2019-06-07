/**
 *  bsg_cache_dma.v
 *
 *  @author tommy
 */

module bsg_cache_dma
  import bsg_cache_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="int"

    ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,parameter bsg_cache_dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
    ,parameter byte_offset_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    ,parameter counter_width_lp=`BSG_SAFE_CLOG2(block_size_in_words_p+1)
  
    ,parameter debug_p=0
  )
  (
    input clk_i
    ,input reset_i

    ,input dma_send_fill_addr_i
    ,input dma_send_evict_addr_i
    ,input dma_get_fill_data_i
    ,input dma_send_evict_data_i
    ,input dma_set_i
    ,input [addr_width_p-1:0] dma_addr_i
    ,output logic done_o

    ,output logic [data_width_p-1:0] snoop_word_o

    ,output logic [bsg_cache_dma_pkt_width_lp-1:0] dma_pkt_o
    ,output logic dma_pkt_v_o
    ,input dma_pkt_yumi_i

    ,input [data_width_p-1:0] dma_data_i
    ,input dma_data_v_i
    ,output logic dma_data_ready_o

    ,output logic [data_width_p-1:0] dma_data_o
    ,output logic dma_data_v_o
    ,input dma_data_yumi_i

    ,output logic data_mem_v_o
    ,output logic data_mem_w_o
    ,output logic [lg_sets_lp+lg_block_size_in_words_lp-1:0] data_mem_addr_o
    ,output logic [2*(data_width_p>>3)-1:0] data_mem_w_mask_o
    ,output logic [(2*data_width_p)-1:0] data_mem_data_o
    ,input [(2*data_width_p)-1:0] data_mem_data_i
  );

  // dma states
  //
  typedef enum logic [2:0] {
    IDLE
    ,SEND_FILL_ADDR
    ,SEND_EVICT_ADDR
    ,GET_FILL_DATA
    ,SEND_EVICT_DATA
  } dma_state_e;

  dma_state_e dma_state_n;
  dma_state_e dma_state_r;

  // counter
  //
  logic counter_en;
  logic counter_set;
  logic [counter_width_lp-1:0] counter_val;
  logic [counter_width_lp-1:0] counter_r;

  bsg_counter_set_en #(
    .max_val_p(block_size_in_words_p)
  ) dma_counter (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.en_i(counter_en)
    ,.set_i(counter_set)
    ,.val_i(counter_val)
    ,.count_o(counter_r)
  );


  // dma packet
  //
  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s dma_pkt;

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
    ,.v_o(in_fifo_v_lo)
    ,.data_o(in_fifo_data_lo)
    ,.yumi_i(in_fifo_yumi_li)
  );

  // out fifo
  //
  logic [data_width_p-1:0] out_fifo_data_li;
  logic out_fifo_v_li;
  logic out_fifo_ready_lo;

  bsg_two_fifo #(
    .width_p(data_width_p)
  ) out_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.data_i(out_fifo_data_li)
    ,.v_i(out_fifo_v_li)
    ,.ready_o(out_fifo_ready_lo)

    ,.v_o(dma_data_v_o)
    ,.data_o(dma_data_o)
    ,.yumi_i(dma_data_yumi_i)
  );

  assign dma_pkt_o = dma_pkt;
  assign dma_pkt.addr = {
    dma_addr_i[addr_width_p-1:byte_offset_width_lp+lg_block_size_in_words_lp],
    {(byte_offset_width_lp+lg_block_size_in_words_lp){1'b0}}
  };

  assign data_mem_w_mask_o = {
    {(data_width_p>>3){dma_set_i}},
    {(data_width_p>>3){~dma_set_i}}
  };

  assign data_mem_addr_o = {
    dma_addr_i[byte_offset_width_lp+lg_block_size_in_words_lp+:lg_sets_lp],
    counter_r[lg_block_size_in_words_lp-1:0]
  };
  
  assign data_mem_data_o = {2{in_fifo_data_lo}};

  assign out_fifo_data_li = dma_set_i
    ? data_mem_data_i[data_width_p+:data_width_p]
    : data_mem_data_i[0+:data_width_p];


  // snoop_word offset
  //
  logic [lg_block_size_in_words_lp-1:0] snoop_word_offset;
  assign snoop_word_offset = dma_addr_i[byte_offset_width_lp+:lg_block_size_in_words_lp];

  always_comb begin
    done_o = 1'b0;
    dma_pkt_v_o = 1'b0;
    dma_pkt.write_not_read = 1'b0;
    data_mem_v_o = 1'b0;
    data_mem_w_o = 1'b0;
    in_fifo_yumi_li = 1'b0;
    dma_state_n = IDLE;
    out_fifo_v_li = 1'b0;
    counter_en = 1'b0;
    counter_set = 1'b0;
    counter_val = '0;

    case (dma_state_r)
      IDLE: begin
        dma_state_n = dma_send_fill_addr_i ? SEND_FILL_ADDR
          : (dma_send_evict_addr_i ? SEND_EVICT_ADDR
          : (dma_get_fill_data_i ? GET_FILL_DATA
          : (dma_send_evict_data_i ? SEND_EVICT_DATA
          : IDLE)));

        counter_en = 1'b0;
        counter_set = dma_get_fill_data_i | dma_send_evict_data_i;
        counter_val = dma_get_fill_data_i
          ? {counter_width_lp{1'b0}}
          : (counter_width_lp)'(1);
        data_mem_v_o = dma_send_evict_data_i;
      end

      SEND_FILL_ADDR: begin
        dma_state_n = dma_pkt_yumi_i
          ? IDLE
          : SEND_FILL_ADDR;
        dma_pkt_v_o = 1'b1;
        dma_pkt.write_not_read = 1'b0;
        done_o = dma_pkt_yumi_i;
      end

      SEND_EVICT_ADDR: begin
        dma_state_n = dma_pkt_yumi_i
          ? IDLE
          : SEND_EVICT_ADDR;
        dma_pkt_v_o = 1'b1;
        dma_pkt.write_not_read = 1'b1;
        done_o = dma_pkt_yumi_i;
      end

      GET_FILL_DATA: begin
        dma_state_n = (counter_r == (block_size_in_words_p -1)) & in_fifo_v_lo
          ? IDLE
          : GET_FILL_DATA;
        data_mem_v_o = in_fifo_v_lo;
        data_mem_w_o = in_fifo_v_lo;
        in_fifo_yumi_li = in_fifo_v_lo;

        counter_en = in_fifo_v_lo & (counter_r != (block_size_in_words_p-1));
        counter_set = in_fifo_v_lo & (counter_r == (block_size_in_words_p-1));
        counter_val = '0;

        done_o = (counter_r == (block_size_in_words_p - 1)) & in_fifo_v_lo;
      end

      SEND_EVICT_DATA: begin
        dma_state_n = (counter_r == block_size_in_words_p) & out_fifo_ready_lo
          ? IDLE
          : SEND_EVICT_DATA;

        counter_en = out_fifo_ready_lo & (counter_r != block_size_in_words_p);
        counter_set = out_fifo_ready_lo & (counter_r == block_size_in_words_p);
        counter_val = '0;

        out_fifo_v_li = 1'b1;

        data_mem_v_o = out_fifo_ready_lo & (counter_r != block_size_in_words_p);
        done_o = (counter_r == block_size_in_words_p) & out_fifo_ready_lo;
      end
    endcase
  end

  // sequential
  //
  logic snoop_word_we;
  assign snoop_word_we = (dma_state_r == GET_FILL_DATA)
    & (snoop_word_offset == counter_r[lg_block_size_in_words_lp-1:0])
    & in_fifo_v_lo;
  
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      dma_state_r <= IDLE;
    end
    else begin
      dma_state_r <= dma_state_n;

      if (snoop_word_we) begin
        snoop_word_o <= in_fifo_data_lo;
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
