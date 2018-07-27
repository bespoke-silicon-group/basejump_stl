module bsg_dma_engine (
  input clk_i
  ,input rst_i
  
  ,input mem_to_network_req_i
  ,input network_to_mem_req_i
  ,input pass_to_network_req_i
  
  ,input [8:0] start_addr_i
  ,input start_set_i
  ,input [2:0] snoop_word_i
  ,output logic [31:0] snoop_data_o
  
  ,input [31:0] pass_data_i
  
  ,input [31:0] cmni_data_i
  ,input cmni_valid_i
  ,output logic cmni_thanks_o
  
  ,output logic cmno_send_req_o
  ,input cmno_send_committed_i
  ,output logic [31:0] cmno_data_o

  ,output logic data_we_force_o
  ,output logic [7:0] data_mask_force_o
  ,output logic [11:0] data_addr_force_o
  ,output logic [63:0] data_in_force_o
  ,input [63:0] raw_data_i
  ,output logic finished_o
);

  localparam line_size_lp = 8'h8;

  logic sent_word;
  logic [4:0] word_num_n;
  logic [4:0] word_num_r;
  
  logic [2:0] word_offset;
  logic processed_word;
  
  always_ff @ (posedge clk_i) begin

    if (cmni_valid_i & (snoop_word_i == word_num_r) & network_to_mem_req_i) begin
      snoop_data_o <= cmni_data_i;
    end
    
    if (rst_i) begin
      word_num_r <= 0;
    end
    else begin
      word_num_r <= finished_o ? 0 : word_num_n;
    end
  end

  logic [31:0] raw_data_set;
  assign raw_data_set = start_set_i ? raw_data_i[63:32] : raw_data_i[31:0];
  
  assign cmno_data_o = pass_to_network_req_i 
    ? pass_data_i
    : raw_data_set; 

  always_comb begin
    cmno_send_req_o = (mem_to_network_req_i | pass_to_network_req_i) & ~rst_i;
    
    sent_word = (mem_to_network_req_i & cmno_send_committed_i) & ~rst_i;
    
    data_we_force_o = cmni_valid_i & network_to_mem_req_i;
    cmni_thanks_o = data_we_force_o;
    
    data_mask_force_o = start_set_i ? {4'b1111, 4'b0000} : {4'b0000, 4'b1111};

    word_offset = word_num_r[2:0] + sent_word;

    data_addr_force_o = {start_addr_i, word_offset[2:0]};
    data_in_force_o = {cmni_data_i, cmni_data_i};

    processed_word = data_we_force_o | sent_word;
    word_num_n = processed_word ? (word_num_r + 1) : word_num_r;
   
    if (rst_i) begin
      finished_o = 0;
    end
    else begin
      if (pass_to_network_req_i) begin
        finished_o = cmno_send_committed_i;
      end
      else begin
        finished_o = ((line_size_lp-1) == word_num_r) & processed_word;
      end
    end
  end


endmodule 
