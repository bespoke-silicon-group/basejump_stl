module bsg_incrementer (
  input clk_i
  ,input rst_i
  ,input en_i

  ,input v_i
  ,input [79:0] data_i
  ,output logic ready_o

  ,output logic v_o
  ,output logic [79:0] data_o
  ,input yumi_i  
);

  typedef enum logic {
    WAIT = 1'b0
    ,DONE = 1'b1
  } incr_state_e;

  logic state_r;
  logic state_n;
  logic [31:0] num_r;
  logic [31:0] num_n;
  logic [31:0] num_plus_one;
  assign num_plus_one = num_r + 1'b1;
  assign data_o = {48'b0, num_plus_one};

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      state_r <= 0;
      num_r <= 0;
    end
    else begin
      if (en_i) begin
        state_r <= state_n;
        num_r <= num_n;
      end
    end
  end

  always_comb begin
    case (state_r)
      WAIT: begin
        ready_o = 1'b1;
        state_n = v_i ? DONE : WAIT;
        num_n = v_i ? data_i[31:0] : num_r;
        v_o = 1'b0;
      end
      DONE: begin
        ready_o = 1'b0;
        v_o = 1'b1;
        num_n = num_r;
        state_n = yumi_i ? WAIT : DONE;
      end
    endcase
  end

endmodule
