/**
 *  mock_memory.v
 */

module mock_memory (
  input clk_i
  ,input rst_i
  
  ,input dma_rd_wr_i
  ,input [31:0] dma_addr_i
  ,input dma_req_v_i
  ,output logic dma_req_yumi_o

  ,output logic [31:0] dma_rdata_o
  ,output logic dma_rvalid_o
  ,input dma_rready_i

  ,input [31:0] dma_wdata_i
  ,input dma_wvalid_i
  ,output logic dma_wready_o
);

  localparam mem_size_lp = 2**14;
  logic [mem_size_lp-1:0][31:0] mem;


  typedef enum logic {
    WAIT = 1'b0,
    BUSY = 1'b1
  } chan_state_e;

  logic recv_state_r, recv_state_n;
  logic [10:0] recv_block_addr_r, recv_block_addr_n;
  logic [2:0] recv_counter_r, recv_counter_n;

  logic send_state_r, send_state_n;
  logic [10:0] send_block_addr_r, send_block_addr_n;
  logic [2:0] send_counter_r, send_counter_n;

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
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

      if ((recv_state_r == BUSY) & dma_wvalid_i) begin
        mem[{recv_block_addr_r, recv_counter_r}] <= dma_wdata_i;
      end
    end
  end

  assign dma_req_yumi_o = dma_req_v_i
    & (((recv_state_r == WAIT) & ~dma_rd_wr_i) | ((send_state_r == WAIT) & dma_rd_wr_i));
  
  assign dma_rdata_o = mem[{send_block_addr_r, send_counter_r}];

  always_comb begin
    recv_block_addr_n = recv_block_addr_r;
    send_block_addr_n = send_block_addr_r;
    dma_wready_o = 1'b0;
    dma_rvalid_o = 1'b0;

    case (recv_state_r)
      WAIT: begin
        recv_state_n = dma_req_v_i & dma_rd_wr_i;
        recv_block_addr_n = recv_state_n
          ? dma_addr_i[15:5]
          : recv_block_addr_r;
        recv_counter_n = recv_state_n
          ? 0
          : recv_counter_r;
      end
      
      BUSY: begin
        recv_state_n = (recv_counter_r == 3'b111) & dma_wvalid_i
          ? WAIT
          : BUSY;
        recv_counter_n = dma_wvalid_i
          ? recv_counter_r + 1
          : recv_counter_r;
        dma_wready_o = dma_wvalid_i;
      end
    endcase

    case (send_state_r)
      WAIT: begin
        send_state_n = dma_req_v_i & (~dma_rd_wr_i);
        send_block_addr_n = send_state_n
          ? dma_addr_i[15:5]
          : send_block_addr_n;
        send_counter_n = send_state_n
          ? 0
          : send_counter_r;
      end
      
      BUSY: begin
        send_state_n = (send_counter_r == 3'b111) & dma_rready_i
          ? WAIT
          : BUSY;
        send_counter_n = dma_rready_i
          ? send_counter_r + 1
          : send_counter_r;
        dma_rvalid_o = 1'b1;
      end
    endcase
  end

endmodule
