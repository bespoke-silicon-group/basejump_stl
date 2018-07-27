/**
 *  bsg_miss_case.v
 */


module bsg_miss_case (
  input clk_i
  ,input rst_i

  ,input v_v_r_i
  ,input miss_v_i
  ,input ld_op_v_i
  ,input st_op_v_i
  ,input flush_op_v_i
  ,input afl_op_v_i
  ,input aflinv_op_v_i
  ,input ainv_op_v_i

  ,input [31:0] miss_addr_v_i
  ,input [18:0] tag_data0_v_i
  ,input [18:0] tag_data1_v_i
  ,input tag_hit1_v_i
  ,input writebuf_empty_i

  ,input [31:0] mdn_fill_header_v_i
  ,input [31:0] mdn_evict_header_v_i
  
  ,output logic mem_to_network_req_o
  ,output logic network_to_mem_req_o
  ,output logic pass_to_network_req_o

  ,output logic [31:0] pass_data_o
    
  ,input dma_finished_i
  
  ,output logic wipe_v_o
  
  ,input query_dirty0_i
  ,input query_dirty1_i
  ,input query_mru_i

  ,output logic final_recover_o
  ,output logic tag_we_force_o

  ,output logic chosen_set_o // the set we have decied to replace or flush
  
  //,output [31:0] evict_address_o
  
  ,output logic mc_reading_dmem_o
  
  ,output logic status_mem_re_o   // status_mem read enable
);

  typedef enum logic [3:0] {
    START = 4'b0000
    ,FLUSH_INSTR = 4'b0001
    ,FLUSH_INSTR_2 = 4'b0011  
    ,FILL_REQUEST_SEND_HDR = 4'b1000
    ,FILL_REQUEST_SEND_ADDR = 4'b1010
    ,EVICT_REQUEST_SEND_HDR = 4'b0010
    ,EVICT_REQUEST_SEND_ADDR = 4'b0110
    ,EVICT_REQUEST_SEND_DATA = 4'b0100
    ,FILL_REQUEST_GET_DATA = 4'b0101
    ,FINAL_RECOVER = 4'b1101
  } miss_state_e;

  logic [3:0] miss_state_r;
  logic chosen_set_n;
  logic chosen_set_r;
  logic chosen_set_is_dirty_r;
  logic chosen_set_is_valid_r;
  
  logic [8:0] miss_index_v;
  logic miss_set_bit_v;
  logic valid0_v, valid1_v;
  
  assign miss_index_v = miss_addr_v_i[13:5];
  assign miss_set_bit_v = miss_addr_v_i[14];
  assign valid0_v = tag_data0_v_i[18];
  assign valid1_v = tag_data1_v_i[18];
  
  assign chosen_set_o = chosen_set_r;

  logic [31:0] evict_address_r;
  //assign evict_address_o = evict_address_r;

  always_comb begin
    pass_data_o = 32'b0;
    tag_we_force_o = 1'b0;
    final_recover_o = 1'b0;
    pass_to_network_req_o = 1'b0;
    mem_to_network_req_o = 1'b0;
    network_to_mem_req_o = 1'b0;
    wipe_v_o = 1'b0;
    mc_reading_dmem_o = 1'b0;
    status_mem_re_o = 1'b0;

    case (miss_state_r) 

      START: begin
        status_mem_re_o = v_v_r_i & miss_v_i;
      end

      FILL_REQUEST_SEND_HDR: begin
        pass_data_o = mdn_fill_header_v_i;
        pass_to_network_req_o = 1'b1;
      end

      FILL_REQUEST_SEND_ADDR: begin
        pass_data_o = miss_addr_v_i;
        tag_we_force_o = dma_finished_i;
        wipe_v_o = 1'b1;
        pass_to_network_req_o = 1'b1;
      end

      FLUSH_INSTR_2: begin
        tag_we_force_o = ainv_op_v_i | aflinv_op_v_i;
        wipe_v_o = 1'b1;
      end

      EVICT_REQUEST_SEND_HDR: begin
        pass_data_o = mdn_evict_header_v_i;
        pass_to_network_req_o = 1'b1;
      end

      EVICT_REQUEST_SEND_ADDR: begin
        pass_data_o = evict_address_r;
        pass_to_network_req_o = 1'b1;
        mc_reading_dmem_o = 1'b1;
      end

      EVICT_REQUEST_SEND_DATA: begin
        mem_to_network_req_o = writebuf_empty_i;
        mc_reading_dmem_o = 1'b1;
      end

      FILL_REQUEST_GET_DATA: begin
        network_to_mem_req_o = writebuf_empty_i;
      end

      FINAL_RECOVER: begin
        final_recover_o = 1'b1;
      end

    endcase
  end

  always_ff @ (posedge clk_i) begin
    chosen_set_n = 0;
    chosen_set_r <= chosen_set_r;
    chosen_set_is_dirty_r <= chosen_set_is_dirty_r;
    chosen_set_is_valid_r <= chosen_set_is_valid_r;
    evict_address_r <= evict_address_r;

    case (miss_state_r)

      START: begin
        chosen_set_is_dirty_r <= 1'b0;
        chosen_set_is_valid_r <= 1'b0;
        chosen_set_r <= 1'b0;
        evict_address_r <= 32'b0;
        miss_state_r <= (v_v_r_i & miss_v_i & (flush_op_v_i | ainv_op_v_i | afl_op_v_i | aflinv_op_v_i))
          ? FLUSH_INSTR 
          : ((v_v_r_i & miss_v_i & (ld_op_v_i | st_op_v_i))
            ? FILL_REQUEST_SEND_HDR
            : START);
      end

      FLUSH_INSTR: begin
        chosen_set_n = (afl_op_v_i | aflinv_op_v_i | ainv_op_v_i) ? tag_hit1_v_i : miss_set_bit_v;
        chosen_set_r <= chosen_set_n;

        chosen_set_is_dirty_r <= chosen_set_n ? query_dirty1_i : query_dirty0_i;
        chosen_set_is_valid_r <= chosen_set_n ? valid1_v : valid0_v;
        miss_state_r <= FLUSH_INSTR_2;
      end      

      FLUSH_INSTR_2: begin
        evict_address_r <= {
          (chosen_set_r ? tag_data1_v_i[17:0] : tag_data0_v_i[17:0]),
          miss_index_v,
          5'b0
        };
        miss_state_r <= (~ainv_op_v_i & chosen_set_is_dirty_r & chosen_set_is_valid_r)
          ? EVICT_REQUEST_SEND_HDR
          : FINAL_RECOVER;
      end

      FILL_REQUEST_SEND_HDR: begin
        chosen_set_n = (valid0_v ? (valid1_v ? ~query_mru_i : 1'b1) : 1'b0);
        chosen_set_r <= chosen_set_n;
        chosen_set_is_dirty_r <= chosen_set_n ? query_dirty1_i : query_dirty0_i;
        chosen_set_is_valid_r <= valid1_v & valid0_v;

        miss_state_r <= dma_finished_i ? FILL_REQUEST_SEND_ADDR : FILL_REQUEST_SEND_HDR;
      end

      FILL_REQUEST_SEND_ADDR: begin
        evict_address_r <= {
          (chosen_set_r ? tag_data1_v_i[17:0] : tag_data0_v_i[17:0]),
          miss_index_v,
          5'b0
        };
        
        miss_state_r <= dma_finished_i
          ? ((chosen_set_is_dirty_r & chosen_set_is_valid_r) ? EVICT_REQUEST_SEND_HDR : FILL_REQUEST_GET_DATA)
          : FILL_REQUEST_SEND_ADDR;
        
      end

      EVICT_REQUEST_SEND_HDR: begin
        miss_state_r <= dma_finished_i ? EVICT_REQUEST_SEND_ADDR : EVICT_REQUEST_SEND_HDR;
      end

      EVICT_REQUEST_SEND_ADDR: begin
        miss_state_r <= dma_finished_i ? EVICT_REQUEST_SEND_DATA : EVICT_REQUEST_SEND_ADDR;
      end
    
      EVICT_REQUEST_SEND_DATA: begin
        miss_state_r <= dma_finished_i
          ? ((flush_op_v_i | aflinv_op_v_i | afl_op_v_i) ? FINAL_RECOVER : FILL_REQUEST_GET_DATA)
          : EVICT_REQUEST_SEND_DATA;
      end
  
      FILL_REQUEST_GET_DATA: begin
        miss_state_r <= dma_finished_i ? FINAL_RECOVER : FILL_REQUEST_GET_DATA;
      end

      FINAL_RECOVER: begin
        miss_state_r <= START;
      end

      default: begin
        miss_state_r <= START;
      end
    endcase

    if (rst_i) begin
      miss_state_r <= START;
    end
  end


endmodule
