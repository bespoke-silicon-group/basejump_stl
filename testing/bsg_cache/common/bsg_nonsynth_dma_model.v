/**
 *  bsg_nonsynth_dma_model.sv
 *
 */

`include "bsg_cache.svh"

module bsg_nonsynth_dma_model
  import bsg_cache_pkg::*;
  #(parameter `BSG_INV_PARAM(addr_width_p)
    ,parameter `BSG_INV_PARAM(data_width_p)
    ,parameter `BSG_INV_PARAM(mask_width_p)
    ,parameter `BSG_INV_PARAM(block_size_in_words_p)
    ,parameter `BSG_INV_PARAM(els_p)

    ,parameter read_delay_p=16
    ,parameter write_delay_p=16
    ,parameter dma_req_delay_p=16
    ,parameter dma_data_delay_p=16

    ,parameter data_mask_width_lp=(data_width_p>>3)
    ,parameter lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_mask_width_lp)
    ,parameter lg_els_lp=`BSG_SAFE_CLOG2(els_p)
    ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,parameter block_offset_width_lp=(block_size_in_words_p>1) ? lg_data_mask_width_lp+lg_block_size_in_words_lp : lg_data_mask_width_lp
    ,parameter upper_addr_width_lp=(block_size_in_words_p>1) ? lg_els_lp-lg_block_size_in_words_lp : lg_els_lp
    ,parameter dma_pkt_width_lp=`bsg_cache_dma_pkt_width(addr_width_p, mask_width_p)
    ,parameter word_width_lp=(block_size_in_words_p*data_width_p)/mask_width_p
    ,parameter dma_ratio_lp=(mask_width_p/block_size_in_words_p)
  )
  (
    input clk_i
    ,input reset_i

    ,input [dma_pkt_width_lp-1:0] dma_pkt_i
    ,input logic dma_pkt_v_i
    ,output logic dma_pkt_yumi_o

    ,output logic [data_width_p-1:0] dma_data_o
    ,output logic dma_data_v_o
    ,input dma_data_ready_i

    ,input [data_width_p-1:0] dma_data_i
    ,input dma_data_v_i
    ,output logic dma_data_yumi_o
  );

  logic [data_width_p-1:0] mem [els_p-1:0];
  
  
  `declare_bsg_cache_dma_pkt_s(addr_width_p, mask_width_p);
  bsg_cache_dma_pkt_s dma_pkt;
  assign dma_pkt = dma_pkt_i;

  typedef enum logic [1:0] {
    WAIT
    ,DELAY
    ,BUSY
  } state_e;

  wire start_read = ~dma_pkt.write_not_read & dma_pkt_v_i;
  wire start_write = dma_pkt.write_not_read & dma_pkt_v_i;


  // read channel
  //
  logic [addr_width_p-1:0] rd_addr_r, rd_addr_n;
  state_e rd_state_r, rd_state_n;
  logic [lg_block_size_in_words_lp-1:0] rd_counter_r, rd_counter_n;
  integer rd_delay_r, rd_delay_n;

  integer rd_data_delay_r, rd_data_delay_n;
  wire rd_data_delay_zero = (rd_data_delay_r == 0);

  integer rd_req_delay_r, rd_req_delay_n;
  wire rd_req_delay_zero = rd_req_delay_r == 0;
  logic rd_req_ready;

  logic [upper_addr_width_lp-1:0] rd_upper_addr;
  assign rd_upper_addr = rd_addr_r[block_offset_width_lp+:upper_addr_width_lp];
  assign dma_data_o = mem[{rd_upper_addr, {(block_size_in_words_p>1){rd_counter_r}}}];

  always_comb begin
    dma_data_v_o = 1'b0;
    rd_addr_n = rd_addr_r;
    rd_counter_n = rd_counter_r;
    rd_delay_n = rd_delay_r;
    rd_data_delay_n = rd_data_delay_r;
    rd_req_delay_n = rd_req_delay_r;
    rd_req_ready = 1'b0;

    case (rd_state_r)
      WAIT: begin
        rd_req_ready = start_read & rd_req_delay_zero;
        rd_req_delay_n = start_read
          ? (rd_req_delay_zero
            ? $urandom_range(dma_req_delay_p,0)
            : rd_req_delay_r - 1) 
          : rd_req_delay_r;
        rd_addr_n = start_read & rd_req_delay_zero
          ? dma_pkt.addr
          : rd_addr_r;
        rd_counter_n = start_read & rd_req_delay_zero
          ? '0
          : rd_counter_r;
        rd_state_n = start_read & rd_req_delay_zero
          ? DELAY
          : WAIT;
        rd_delay_n = start_read & rd_req_delay_zero
          ? $urandom_range(dma_data_delay_p, 0)
          : rd_delay_r;
      end

      DELAY: begin
        rd_delay_n = rd_delay_r - 1;
        rd_state_n = rd_delay_r == 0
          ? BUSY
          : DELAY;

        rd_data_delay_n = (rd_delay_r == 0)
          ? $urandom_range(dma_data_delay_p, 0)
          : rd_data_delay_r;
      end

      BUSY: begin
        rd_data_delay_n = rd_data_delay_zero
          ? (dma_data_ready_i ? $urandom_range(dma_data_delay_p, 0) : 0)
          : rd_data_delay_r - 1;
        dma_data_v_o = rd_data_delay_zero;
        rd_counter_n = rd_data_delay_zero & dma_data_ready_i
          ? rd_counter_r + 1
          : rd_counter_r;
        rd_state_n = rd_data_delay_zero & dma_data_ready_i & (rd_counter_r == block_size_in_words_p-1)
          ? WAIT
          : BUSY;
      end
    endcase
  end  

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      rd_state_r <= WAIT;
      rd_addr_r <= '0;
      rd_counter_r <= '0;
      rd_delay_r <= '0;
      rd_data_delay_r <= '0;
      rd_req_delay_r <= '0;
    end
    else begin
      rd_state_r <= rd_state_n;
      rd_addr_r <= rd_addr_n;
      rd_counter_r <= rd_counter_n;
      rd_delay_r <= rd_delay_n;
      rd_data_delay_r <= rd_data_delay_n;
      rd_req_delay_r <= rd_req_delay_n;
    end
  end

  // write channel
  //
  logic [addr_width_p-1:0] wr_addr_r, wr_addr_n;
  logic [mask_width_p-1:0] wr_mask_r, wr_mask_n;
  state_e wr_state_r, wr_state_n;
  logic [lg_block_size_in_words_lp-1:0] wr_counter_r, wr_counter_n;
  integer wr_delay_r, wr_delay_n;
  integer wr_data_delay_r, wr_data_delay_n;
  logic [dma_ratio_lp-1:0] dma_mask_li;
  
  wire wr_data_delay_zero = wr_data_delay_r == 0;

  integer wr_req_delay_r, wr_req_delay_n;
  wire wr_req_delay_zero = wr_req_delay_r == 0;
  logic wr_req_ready;

  logic [upper_addr_width_lp-1:0] wr_upper_addr;
  assign wr_upper_addr = wr_addr_r[block_offset_width_lp+:upper_addr_width_lp];

  bsg_mux #(
    .width_p(dma_ratio_lp)
    ,.els_p(block_size_in_words_p)
  ) mux (
    .data_i(wr_mask_r)
    ,.sel_i(wr_counter_r)
    ,.data_o(dma_mask_li)
  );

  always_comb begin
    wr_addr_n = wr_addr_r;
    wr_mask_n = wr_mask_r;
    wr_data_delay_n = wr_data_delay_r;
    wr_req_delay_n = wr_req_delay_r;
    wr_req_ready = 1'b0;
    dma_data_yumi_o = 1'b0;

    case (wr_state_r)
      WAIT: begin
        wr_req_ready = start_write & wr_req_delay_zero;
        wr_req_delay_n = start_write
          ? (wr_req_delay_zero
            ? $urandom_range(dma_req_delay_p,0)
            : wr_req_delay_r - 1)
          : wr_req_delay_r;
        wr_addr_n = start_write & wr_req_delay_zero
          ? dma_pkt.addr
          : wr_addr_r;
        wr_mask_n = start_write & wr_req_delay_zero
          ? dma_pkt.mask
          : wr_mask_r;
        wr_counter_n = start_write & wr_req_delay_zero
          ? '0
          : wr_counter_r;
        wr_state_n = start_write & wr_req_delay_zero
          ? DELAY
          : WAIT;
        wr_delay_n = start_write & wr_req_delay_zero
          ? $urandom_range(dma_data_delay_p,0)
          : wr_delay_r;
      end
      
      DELAY: begin
        wr_delay_n = wr_delay_r - 1;
        wr_state_n = wr_delay_r == 0
          ? BUSY
          : DELAY;
        wr_data_delay_n = (wr_delay_r == 0)
          ? $urandom_range(dma_data_delay_p, 0)
          : wr_data_delay_r;
      end

      BUSY: begin
        wr_data_delay_n = wr_data_delay_zero
          ? (dma_data_v_i ? $urandom_range(dma_data_delay_p, 0) : 0)
          : wr_data_delay_r - 1;

        dma_data_yumi_o = dma_data_v_i & wr_data_delay_zero;
        wr_counter_n = (dma_data_v_i & wr_data_delay_zero)
          ? wr_counter_r + 1
          : wr_counter_r;
        wr_state_n = (wr_counter_r == block_size_in_words_p-1) & dma_data_v_i & wr_data_delay_zero
          ? WAIT
          : BUSY;
      end

    endcase
  end

  assign dma_pkt_yumi_o = (start_read & rd_req_ready) | (start_write & wr_req_ready);

  // sequential
  //
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      wr_state_r <= WAIT;
      wr_addr_r <= '0;
      wr_counter_r <= '0;
      wr_delay_r <= '0;
      wr_data_delay_r <= '0;
      wr_req_delay_r <= '0;

      for (integer i = 0; i < els_p; i++) begin
        mem[i] <= '0;
      end

    end
    else begin
      wr_state_r <= wr_state_n;
      wr_addr_r <= wr_addr_n;
      wr_mask_r <= wr_mask_n;
      wr_counter_r <= wr_counter_n;
      wr_delay_r <= wr_delay_n;
      wr_data_delay_r <= wr_data_delay_n;
      wr_req_delay_r <= wr_req_delay_n;
    
      if ((wr_state_r == BUSY) & dma_data_v_i & dma_data_yumi_o) begin
        for (integer i = 0; i < dma_ratio_lp; i++) begin
          if (dma_mask_li[i]) begin
            mem[{wr_upper_addr, {(block_size_in_words_p>1){wr_counter_r}}}][i*word_width_lp+:word_width_lp] <= dma_data_i[i*word_width_lp+:word_width_lp];
          end
        end
      end

    end
  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_dma_model)
