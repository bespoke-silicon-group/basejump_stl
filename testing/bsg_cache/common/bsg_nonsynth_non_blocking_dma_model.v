/**
 *  bsg_nonsynth_non_blocking_dma_model.v
 *
 *  There is nothing non-blocking about the DMA model,
 *  Rather this is only to be used with bsg_cache_non_blocking.
 *
 */


module bsg_nonsynth_non_blocking_dma_model
  import bsg_cache_non_blocking_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter els_p="inv"

    ,parameter read_delay_p=16
    ,parameter write_delay_p=16

    ,parameter lg_read_delay_lp=`BSG_SAFE_CLOG2(read_delay_p)
    ,parameter lg_write_delay_lp=`BSG_SAFE_CLOG2(write_delay_p)

    ,parameter data_mask_width_lp=(data_width_p>>3)
    ,parameter lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_mask_width_lp)
    ,parameter lg_els_lp=`BSG_SAFE_CLOG2(els_p)
    ,parameter lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,parameter dma_pkt_width_lp=`bsg_cache_non_blocking_dma_pkt_width(addr_width_p)
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
  
  
  `declare_bsg_cache_non_blocking_dma_pkt_s(addr_width_p);
  bsg_cache_non_blocking_dma_pkt_s dma_pkt;
  assign dma_pkt = dma_pkt_i;

  typedef enum logic [1:0] {
    WAIT
    ,DELAY
    ,BUSY
  } state_e;

  logic start_read;
  logic start_write;
  assign start_read = ~dma_pkt.write_not_read & dma_pkt_v_i;
  assign start_write = dma_pkt.write_not_read & dma_pkt_v_i;


  // read channel
  //
  logic [addr_width_p-1:0] read_addr_r, read_addr_n;
  state_e read_state_r, read_state_n;
  logic [lg_block_size_in_words_lp-1:0] read_counter_r, read_counter_n;
  logic [lg_read_delay_lp-1:0] read_delay_r, read_delay_n;

  logic [lg_els_lp-lg_block_size_in_words_lp-1:0] read_upper_addr;
  assign read_upper_addr = read_addr_r[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_els_lp-lg_block_size_in_words_lp];
  assign dma_data_o = mem[{read_upper_addr, read_counter_r}];

  always_comb begin
    dma_data_v_o = 1'b0;
    read_addr_n = read_addr_r;
    read_counter_n = read_counter_r;
    read_delay_n = read_delay_r;

    case (read_state_r)
      WAIT: begin
        read_addr_n = start_read
          ? dma_pkt.addr
          : read_addr_r;
        read_counter_n = start_read
          ? '0
          : read_counter_r;
        read_state_n = start_read
          ? DELAY
          : WAIT;
        read_delay_n = '0;
      end

      DELAY: begin
        read_delay_n = read_delay_r + 1;
        read_state_n = read_delay_r == (read_delay_p-1)
          ? BUSY
          : DELAY;
      end

      BUSY: begin
        dma_data_v_o = 1'b1;
        read_counter_n = dma_data_ready_i
          ? read_counter_r + 1
          : read_counter_r;
        read_state_n = dma_data_ready_i & (read_counter_r == block_size_in_words_p-1)
          ? WAIT
          : BUSY;
      end
    endcase
  end  

  // write channel
  //
  logic [addr_width_p-1:0] write_addr_r, write_addr_n;
  state_e write_state_r, write_state_n;
  logic [lg_block_size_in_words_lp-1:0] write_counter_r, write_counter_n;
  logic [lg_write_delay_lp-1:0] write_delay_r, write_delay_n;

  logic [lg_els_lp-lg_block_size_in_words_lp-1:0] write_upper_addr;
  assign write_upper_addr = write_addr_r[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_els_lp-lg_block_size_in_words_lp];

  always_comb begin
    write_addr_n = write_addr_r;
    dma_data_yumi_o = 1'b0;

    case (write_state_r)
      WAIT: begin
        write_addr_n = start_write 
          ? dma_pkt.addr
          : write_addr_r;
        write_counter_n = start_write
          ? '0
          : write_counter_r;
        write_state_n = start_write
          ? DELAY
          : WAIT;
        write_delay_n = '0;
      end
      
      DELAY: begin
        write_delay_n = write_delay_r + 1;
        write_state_n = write_delay_r == (write_delay_p-1)
          ? BUSY
          : DELAY;
      end

      BUSY: begin
        dma_data_yumi_o = dma_data_v_i;
        write_counter_n = dma_data_v_i
          ? write_counter_r + 1
          : write_counter_r;
        write_state_n = (write_counter_r == block_size_in_words_p-1) & dma_data_v_i
          ? WAIT
          : BUSY;
      end

    endcase
  end

  assign dma_pkt_yumi_o = (start_read & (read_state_r == WAIT))
    | (start_write & (write_state_r == WAIT));

  // sequential
  //
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      read_state_r <= WAIT;
      read_addr_r <= '0;
      read_counter_r <= '0;
      read_delay_r <= '0;
      write_state_r <= WAIT;
      write_addr_r <= '0;
      write_counter_r <= '0;
      write_delay_r <= '0;
      for (integer i = 0; i < els_p; i++) begin
        mem[i] <= '0;
      end
    end
    else begin
      read_state_r <= read_state_n;
      read_addr_r <= read_addr_n;
      read_counter_r <= read_counter_n;
      read_delay_r <= read_delay_n;
      write_state_r <= write_state_n;
      write_addr_r <= write_addr_n;
      write_counter_r <= write_counter_n;
      write_delay_r <= write_delay_n;
    
      if (write_state_r == BUSY & dma_data_v_i) begin
        mem[{write_upper_addr, write_counter_r}] <= dma_data_i;
      end
    end
  end

endmodule
