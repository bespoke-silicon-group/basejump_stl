/**
 *  mock_memory.v
 */

module mock_memory (
  input clock_i
  ,input reset_i
  
  // request channel
  ,input dma_req_ch_write_not_read_i
  ,input [31:0] dma_req_ch_addr_i
  ,input dma_req_ch_v_i
  ,output logic dma_req_ch_yumi_o

  // read channel
  ,output logic [31:0] dma_read_ch_data_o
  ,output logic dma_read_ch_v_o
  ,input dma_read_ch_ready_i

  // write channel
  ,input [31:0] dma_write_ch_data_i
  ,input dma_write_ch_v_i
  ,output logic dma_write_ch_yumi_o
);

  localparam mem_size_lp = 2**14;
  logic [mem_size_lp-1:0][31:0] mem;


  typedef enum logic {
    WAIT = 1'b0,
    BUSY = 1'b1
  } ch_state_e;

  logic recv_state_r, recv_state_n;
  logic [10:0] recv_block_addr_r, recv_block_addr_n;
  logic [2:0] recv_counter_r, recv_counter_n;

  logic send_state_r, send_state_n;
  logic [10:0] send_block_addr_r, send_block_addr_n;
  logic [2:0] send_counter_r, send_counter_n;

  always_ff @ (posedge clock_i) begin
    if (reset_i) begin
      recv_state_r <= WAIT;
      recv_block_addr_r <= 0;
      recv_counter_r <= 0;
      send_state_r <= WAIT;
      send_block_addr_r <= 0;
      send_counter_r <= 0;
      for (int i = 0; i < mem_size_lp; i++) begin
        mem[i] <= 0;
      end
    end
    else begin
      recv_state_r <= recv_state_n;
      recv_block_addr_r <= recv_block_addr_n;
      recv_counter_r <= recv_counter_n;
      send_state_r <= send_state_n;
      send_block_addr_r <= send_block_addr_n;
      send_counter_r <= send_counter_n;

      if ((recv_state_r == BUSY) & dma_write_ch_v_i) begin
        mem[{recv_block_addr_r, recv_counter_r}] <= dma_write_ch_data_i;
      end
    end
  end

  assign dma_req_ch_yumi_o = dma_req_ch_v_i
    & (((send_state_r == WAIT) & ~dma_req_ch_write_not_read_i)
        | ((recv_state_r == WAIT) & dma_req_ch_write_not_read_i));
  
  assign dma_read_ch_data_o = mem[{send_block_addr_r, send_counter_r}];

  always_comb begin
    recv_block_addr_n = recv_block_addr_r;
    send_block_addr_n = send_block_addr_r;
    dma_write_ch_yumi_o = 1'b0;
    dma_read_ch_v_o = 1'b0;

    case (recv_state_r)
      WAIT: begin
        recv_state_n = dma_req_ch_v_i & dma_req_ch_write_not_read_i;
        recv_block_addr_n = recv_state_n
          ? dma_req_ch_addr_i[15:5]
          : recv_block_addr_r;
        recv_counter_n = recv_state_n
          ? 0
          : recv_counter_r;
      end
      
      BUSY: begin
        recv_state_n = (recv_counter_r == 3'b111) & dma_write_ch_v_i
          ? WAIT
          : BUSY;
        recv_counter_n = dma_write_ch_v_i
          ? recv_counter_r + 1
          : recv_counter_r;
        dma_write_ch_yumi_o = dma_write_ch_v_i;
      end
    endcase

    case (send_state_r)
      WAIT: begin
        send_state_n = dma_req_ch_v_i & (~dma_req_ch_write_not_read_i);
        send_block_addr_n = send_state_n
          ? dma_req_ch_addr_i[15:5]
          : send_block_addr_r;
        send_counter_n = send_state_n
          ? 0
          : send_counter_r;
      end
      
      BUSY: begin
        send_state_n = (send_counter_r == 3'b111) & dma_read_ch_ready_i
          ? WAIT
          : BUSY;
        send_counter_n = dma_read_ch_ready_i
          ? send_counter_r + 1
          : send_counter_r;
        dma_read_ch_v_o = 1'b1;
      end
    endcase
  end

endmodule
