module mock_memory (
  input clk_i
  ,input rst_i
  
  ,output logic [31:0] cmni_data_o
  ,output logic cmni_valid_o
  ,input cmni_thanks_i

  ,input cmno_send_req_i
  ,output logic cmno_committed_o
  ,input [31:0] cmno_data_i
);

  localparam mem_size_lp = 2**14;

  typedef enum logic [1:0] {
    WAIT_HDR = 2'd0,
    WAIT_ADDR = 2'd1,
    RECV_DATA = 2'd2
  } recv_state_t;

  typedef enum logic {
    WAIT = 1'd0,
    SEND_DATA = 1'd1
  } send_state_t;

  logic [mem_size_lp-1:0][31:0] mem;

  logic [1:0] recv_state_r, recv_state_n;
  logic [1:0] send_state_r, send_state_n;
  logic [31:0] header_r, header_n;
  logic [8:0] recv_index_r, recv_index_n;
  logic [8:0] send_index_r, send_index_n;
  logic [2:0] recv_counter_r, recv_counter_n;
  logic [2:0] send_counter_r, send_counter_n;
  logic start_send;

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      recv_state_r <= WAIT_HDR;
      send_state_r <= WAIT;
      header_r <= 0;
      recv_index_r <= 0;
      send_index_r <= 0;
      recv_counter_r <= 0;
      send_counter_r <= 0;
      for (int i = 0; i < mem_size_lp; i++) begin
        mem[i] <= 0;
      end
    end
    else begin
      recv_state_r <= recv_state_n;
      send_state_r <= send_state_n;
      header_r <= header_n;
      recv_index_r <= recv_index_n;
      send_index_r <= send_index_n;
      recv_counter_r <= recv_counter_n;
      send_counter_r <= send_counter_n;
      if ((recv_state_r == RECV_DATA) & cmno_send_req_i & cmno_committed_o) begin
        mem[{recv_index_r, recv_counter_r}] <= cmno_data_i;
      end
    end
  end


  always_comb begin
  
    recv_index_n = recv_index_r;
    send_index_n = send_index_r;
    recv_counter_n = recv_counter_r;
    header_n = header_r;
    start_send = 0;
    cmno_committed_o = 0;

    case (recv_state_r)
      WAIT_HDR: begin
        recv_state_n = cmno_send_req_i ? WAIT_ADDR : WAIT_HDR;
        header_n = cmno_send_req_i ? cmno_data_i : header_r;
        cmno_committed_o = cmno_send_req_i;
      end
      WAIT_ADDR: begin
        recv_state_n = cmno_send_req_i
          ? (header_r[6] ? RECV_DATA : WAIT_HDR)
          : WAIT_ADDR;
        recv_index_n = header_r[6] ? cmno_data_i[14:6] : recv_index_r;
        send_index_n = header_r[6] ? send_index_r : cmno_data_i[14:6]; 
        start_send = cmno_send_req_i & ~header_r[6];
        recv_counter_n = (cmno_send_req_i & header_r[6]) ? 0 : recv_counter_r;
        cmno_committed_o = cmno_send_req_i;
      end
      RECV_DATA: begin
        recv_state_n = cmno_send_req_i & (recv_counter_r == 3'b111)
          ? WAIT_HDR
          : RECV_DATA;
        recv_counter_n = cmno_send_req_i
          ? recv_counter_r + 1
          : recv_counter_r;
        
        cmno_committed_o = cmno_send_req_i;

      end
    endcase
    
    case (send_state_r)
      WAIT: begin
        send_state_n = start_send ? SEND_DATA : WAIT;
        send_counter_n = start_send ? 0 : send_counter_r;
        cmni_valid_o = 0;
        cmni_data_o = 0;
      end
    
      SEND_DATA: begin
        send_state_n = (cmni_thanks_i & (send_counter_r == 3'b111))
          ? WAIT
          : SEND_DATA;
        send_counter_n = cmni_thanks_i ? (send_counter_r + 1) : send_counter_r;
        cmni_valid_o = 1;
        cmni_data_o = mem[{send_index_r, send_counter_r}];
      end
    endcase

    
  end


endmodule
