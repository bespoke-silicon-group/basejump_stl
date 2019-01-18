/**
 *  bsg_test_node_master.v
 */

`include "bsg_cache_pkt.vh"

module bsg_test_node_master
  import bsg_cache_pkg::*;
  #(parameter id_p="inv"
    ,parameter sets_p="inv"
    ,parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter lo_addr_width_p="inv"

    ,parameter bsg_cache_pkt_width_lp=`bsg_cache_pkt_width(addr_width_p,data_width_p)
    ,parameter data_mask_width_lp=(data_width_p>>3)
    ,parameter lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_mask_width_lp)
    ,parameter lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,parameter num_req_lp=(2**(lo_addr_width_p-lg_data_mask_width_lp))
  )
  (
    input clk_i
    ,input reset_i

    ,output logic [bsg_cache_pkt_width_lp-1:0] cache_pkt_o
    ,output logic v_o
    ,input ready_i   

    ,input [data_width_p-1:0] data_i
    ,input v_i
    ,output logic yumi_o
    
    ,output logic done_o
  );

  // casting packet struct
  //
  `declare_bsg_cache_pkt_s(addr_width_p, data_width_p);
  bsg_cache_pkt_s cache_pkt;
  assign cache_pkt_o = cache_pkt;

  typedef enum logic [2:0] {
    SEND_TAGST
    ,RECV_TAGST
    ,SEND_STORE
    ,RECV_STORE
    ,SEND_LOAD
    ,RECV_LOAD
    ,DONE
  } state_e;

  state_e state_r, state_n;
  logic [`BSG_SAFE_CLOG2(sets_p*2)-1:0] tagst_count_r, tagst_count_n;
  logic [lo_addr_width_p-lg_data_mask_width_lp-1:0] word_count_r, word_count_n;

  // fifo
  //
  logic fifo_ready_lo;
  logic fifo_v_lo;
  logic [data_width_p-1:0] fifo_data_lo;
  logic fifo_yumi_li;

  assign yumi_o = v_i & fifo_ready_lo;

  bsg_fifo_1r1w_large #(
    .width_p(data_width_p)
    ,.els_p(1024)
  ) output_fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.data_i(data_i)
    ,.v_i(v_i)
    ,.ready_o(fifo_ready_lo)
  
    ,.v_o(fifo_v_lo)
    ,.data_o(fifo_data_lo)
    ,.yumi_i(fifo_yumi_li)
  );

  always_comb begin
    v_o = 1'b0;
    fifo_yumi_li = 1'b0;
    cache_pkt.sigext = 1'b0;
    cache_pkt.mask = '0;
    cache_pkt.opcode = TAGST;
    cache_pkt.addr = '0;
    cache_pkt.data = '0;
    tagst_count_n = tagst_count_r;
    word_count_n = word_count_r;
    state_n = state_r;
    done_o = 1'b0;
      
    case (state_r)

      SEND_TAGST: begin
        v_o = 1;
        cache_pkt.opcode = TAGST;
        cache_pkt.addr = {
          {(addr_width_p-lg_sets_lp*2-1-lg_data_mask_width_lp){1'b0}},
          tagst_count_r,
          {(lg_data_mask_width_lp+lg_sets_lp){1'b0}}
        };
        cache_pkt.data = '0;
        tagst_count_n = ready_i
          ? tagst_count_r + 1
          : tagst_count_r;
        state_n = (tagst_count_r == (sets_p*2-1)) & ready_i
          ? RECV_TAGST
          : SEND_TAGST;
      end

      RECV_TAGST: begin
        if (fifo_v_lo) begin
          $display("[%d] tagst received: %d", id_p, tagst_count_r);
        end
        fifo_yumi_li = fifo_v_lo;
        tagst_count_n = fifo_v_lo
          ? tagst_count_r + 1
          : tagst_count_r;
        state_n = (tagst_count_r == (sets_p*2-1)) & fifo_v_lo
          ? SEND_STORE
          : RECV_TAGST;
      end

      SEND_STORE: begin
        v_o = 1;
        cache_pkt.opcode = SW;
        cache_pkt.addr = {
          {(addr_width_p-lo_addr_width_p){1'b0}},
          word_count_r,
          2'b00
        };
        cache_pkt.data = {
          (data_width_p+lg_data_mask_width_lp-lo_addr_width_p)'(id_p),
          word_count_r
        };
        word_count_n = ready_i
          ? word_count_r + 1
          : word_count_r;
        state_n = ready_i & (word_count_r == num_req_lp-1)
          ? RECV_STORE
          : SEND_STORE;
      end

      RECV_STORE: begin
        if (fifo_v_lo) begin
          $display("[%d] store received: %d", id_p, word_count_r);
        end
        fifo_yumi_li = fifo_v_lo;
        word_count_n = fifo_v_lo
          ? word_count_r + 1
          : word_count_r;
        state_n = (word_count_r == num_req_lp-1)
          ? SEND_LOAD
          : RECV_STORE;
      end

      SEND_LOAD: begin
        v_o = 1;
        cache_pkt.opcode = LW;
        cache_pkt.addr = {
          {(addr_width_p-lo_addr_width_p){1'b0}},
          word_count_r,
          2'b00
        };
        word_count_n = ready_i
          ? word_count_r + 1
          : word_count_r;
        state_n = ready_i & (word_count_r == num_req_lp-1)
          ? RECV_LOAD
          : SEND_LOAD;
      end

      RECV_LOAD: begin
        if (fifo_v_lo) begin
          $display("[%d] load received: %d", id_p, fifo_data_lo);
        end
        fifo_yumi_li = fifo_v_lo;
        word_count_n = fifo_v_lo
          ? word_count_r + 1
          : word_count_r;
        state_n = (word_count_r == num_req_lp-1)
          ? DONE
          : RECV_LOAD;
      end

      DONE: begin
        state_n = DONE;
        done_o = 1'b1;
      end

    endcase
  end
  
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      state_r <= SEND_TAGST;
      tagst_count_r <= '0;
      word_count_r <= '0;
    end
    else begin
      state_r <= state_n;
      tagst_count_r <= tagst_count_n;
      word_count_r <= word_count_n;
    end
  end

endmodule
