/**
 *  bsg_cache_dma.v
 *
 *  @author tommy
 */

`include "bsg_cache_pkt.vh"
`include "bsg_cache_dma_pkt.vh"

module bsg_cache_dma
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter lg_block_size_in_words_lp="inv"
    ,parameter lg_sets_lp="inv"
    ,parameter bsg_cache_dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
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

  logic [lg_block_size_in_words_lp:0] counter_r;
  logic [lg_block_size_in_words_lp:0] counter_n; 


  // dma packet
  //
  `declare_bsg_cache_dma_pkt_s(addr_width_p);
  bsg_cache_dma_pkt_s dma_pkt;

  // in fifo
  //
  logic in_fifo_v_lo;
  logic [data_width_p-1:0] in_fifo_data_lo;
  logic in_fifo_yumi_li;

  bsg_fifo_1r1w_large #(
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

  assign dma_pkt_o = dma_pkt;
  assign dma_pkt.addr = {
    dma_addr_i[addr_width_p-1:`BSG_SAFE_CLOG2(data_width_p>>3)+lg_block_size_in_words_lp],
    {(`BSG_SAFE_CLOG2(data_width_p>>3)+lg_block_size_in_words_lp){1'b0}}
  };

  assign data_mem_w_mask_o = {
    {(data_width_p>>3){dma_set_i}},
    {(data_width_p>>3){~dma_set_i}}
  };

  assign data_mem_addr_o = {
    dma_addr_i[`BSG_SAFE_CLOG2(data_width_p>>3)+lg_block_size_in_words_lp+:lg_sets_lp],
    counter_r[lg_block_size_in_words_lp-1:0]
  };
  
  assign data_mem_data_o = {2{in_fifo_data_lo}};

  assign dma_data_o = dma_set_i
    ? data_mem_data_i[data_width_p+:data_width_p]
    : data_mem_data_i[0+:data_width_p];


  // snoop_word offset
  //
  logic [lg_block_size_in_words_lp-1:0] snoop_word_offset;
  assign snoop_word_offset = dma_addr_i[`BSG_SAFE_CLOG2(data_width_p>>3)+:lg_block_size_in_words_lp];

  always_comb begin
    done_o = 1'b0;
    dma_pkt_v_o = 1'b0;
    counter_n = counter_r;
    dma_pkt.write_not_read = 1'b0;
    data_mem_v_o = 1'b0;
    data_mem_w_o = 1'b0;
    dma_data_v_o = 1'b0;
    in_fifo_yumi_li = 1'b0;
    dma_state_n = IDLE;

    case (dma_state_r)
      IDLE: begin
        dma_state_n = dma_send_fill_addr_i ? SEND_FILL_ADDR
          : (dma_send_evict_addr_i ? SEND_EVICT_ADDR
          : (dma_get_fill_data_i ? GET_FILL_DATA
          : (dma_send_evict_data_i ? SEND_EVICT_DATA
          : IDLE)));
        counter_n = dma_get_fill_data_i ? {(lg_block_size_in_words_lp+1){1'b0}}
          : (dma_send_evict_data_i ? (lg_block_size_in_words_lp+1)'(1)
          : counter_r);
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
        counter_n = in_fifo_v_lo
          ? counter_r + 1
          : counter_r;
        done_o = (counter_r == (block_size_in_words_p - 1)) & in_fifo_v_lo;
      end

      SEND_EVICT_DATA: begin
        dma_state_n = (counter_r == block_size_in_words_p) & dma_data_yumi_i
          ? IDLE
          : SEND_EVICT_DATA;
        counter_n = dma_data_yumi_i
          ? counter_r + 1
          : counter_r;
        dma_data_v_o = 1'b1;
        data_mem_v_o = dma_data_yumi_i & (counter_r != block_size_in_words_p);
        done_o = (counter_r == block_size_in_words_p) & dma_data_yumi_i;
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
      counter_r <= '0;
    end
    else begin
      dma_state_r <= dma_state_n;
      counter_r <= counter_n;

      if (snoop_word_we) begin
        snoop_word_o <= in_fifo_data_lo;
      end 
    end
  end

endmodule
