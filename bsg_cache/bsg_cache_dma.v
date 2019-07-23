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
    ,parameter sets_p="int"

    ,localparam lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,localparam lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,localparam bsg_cache_dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p)
  
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
  logic out_fifo_v_li;
  logic [data_width_p-1:0] out_fifo_data_li;
  logic out_fifo_ready_lo;
  logic data_flopped_r, data_flopped_n;
  logic data_mem_v_r, data_mem_v_n;
  logic [data_width_p-1:0] data_buf_r, data_buf_n;

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

  logic [data_width_p-1:0] data_way_selected;
  assign data_way_selected = dma_set_i
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
    in_fifo_yumi_li = 1'b0;
    out_fifo_v_li = 1'b0;
    data_flopped_n = data_flopped_r;
    data_mem_v_n = data_mem_v_r;
    data_buf_n = data_buf_r;
    dma_state_n = IDLE;
    out_fifo_data_li = data_way_selected;

    case (dma_state_r)
      IDLE: begin
        dma_state_n = dma_send_fill_addr_i ? SEND_FILL_ADDR
          : (dma_send_evict_addr_i ? SEND_EVICT_ADDR
          : (dma_get_fill_data_i ? GET_FILL_DATA
          : (dma_send_evict_data_i ? SEND_EVICT_DATA
          : IDLE)));
        counter_n = dma_get_fill_data_i
          ? {(lg_block_size_in_words_lp+1){1'b0}}
          : (dma_send_evict_data_i
            ? (lg_block_size_in_words_lp+1)'(1)
            : counter_r);
        data_mem_v_o = dma_send_evict_data_i;
        data_mem_v_n = dma_send_evict_data_i;
        data_flopped_n = 1'b0;
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
        // counter_r in this context means the number of words read from
        // data_mem so far.
        out_fifo_v_li = 1'b1;
       
        data_mem_v_o = out_fifo_ready_lo & (counter_r != block_size_in_words_p);
        data_mem_v_n = data_mem_v_o;

        data_flopped_n = data_mem_v_r
          ? ~out_fifo_ready_lo
          : data_flopped_r;

        data_buf_n = (data_mem_v_r & ~out_fifo_ready_lo)
          ? data_way_selected
          : data_buf_r;

        out_fifo_data_li = data_flopped_r
          ? data_buf_r
          : data_way_selected;
 
        counter_n = out_fifo_ready_lo
          ? counter_r + 1
          : counter_r;
        dma_state_n = (counter_r == block_size_in_words_p) & out_fifo_ready_lo
          ? IDLE
          : SEND_EVICT_DATA;
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

   // synopsys sync_set_reset "reset_i"
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      dma_state_r    <= IDLE;
      counter_r      <= '0;
      data_flopped_r <= 1'b0;
      data_mem_v_r   <= 1'b0;
       data_buf_r    <= '0;  // MBT being conservative
    end
    else begin
      dma_state_r    <= dma_state_n;
      counter_r      <= counter_n;
      data_flopped_r <= data_flopped_n;
      data_mem_v_r   <= data_mem_v_n;
      data_buf_r     <= data_buf_n;

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
