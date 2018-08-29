/**
 *  bsg_cache_miss.v
 */


module bsg_cache_miss
  #(parameter addr_width_p="inv"
    ,parameter tag_width_lp="inv"
    ,parameter lg_block_size_in_words_lp="inv"
    ,parameter lg_sets_lp="inv")
(
  input clock_i
  ,input reset_i

  ,input v_v_r_i
  ,input miss_v_i
  ,input ld_op_v_i
  ,input st_op_v_i
  ,input tagfl_op_v_i
  ,input afl_op_v_i
  ,input aflinv_op_v_i
  ,input ainv_op_v_i
  ,input [addr_width_p-1:0] addr_v_i

  ,input [tag_width_lp-1:0] tag0_v_i
  ,input [tag_width_lp-1:0] tag1_v_i
  ,input valid0_v_i
  ,input valid1_v_i
  ,input tag_hit1_v_i

  // from store_buffer
  ,input storebuf_empty_i

  // to dma_engine
  ,output logic mc_send_fill_req_o
  ,output logic mc_send_evict_req_o
  ,output logic mc_fill_line_o
  ,output logic mc_evict_line_o
  ,output logic [addr_width_p-1:0] mc_pass_addr_o
    
  // from dma_engine
  ,input dma_finished_i
  
  // to replacement
  ,output logic wipe_v_o
  
  // from replacement 
  ,input [1:0] dirty_i
  ,input mru_i

  // to replacement
  ,output logic status_mem_re_o

  ,output logic chosen_set_o
  ,output logic tag_we_force_o
  ,output logic final_recover_o
);

  typedef enum logic [2:0] {
    START
    ,FLUSH_INSTR
    ,FILL_SEND_ADDR
    ,EVICT_SEND_ADDR
    ,EVICT_SEND_DATA
    ,FILL_GET_DATA
    ,FINAL_RECOVER
  } miss_state_e;

  miss_state_e miss_state_r;
  miss_state_e miss_state_n;
  logic chosen_set_r;
  logic chosen_set_n;
  logic chosen_set_is_dirty_r;
  logic chosen_set_is_dirty_n;
  logic chosen_set_is_valid_r;
  logic chosen_set_is_valid_n;
  logic [addr_width_p-1:0] evict_address_r;
  logic [addr_width_p-1:0] evict_address_n;
  
  logic [lg_sets_lp-1:0] miss_index_v;
  logic tagfl_set_v;
  logic flush_instr;
  logic dirty_and_valid;

  assign miss_index_v = addr_v_i[2+lg_block_size_in_words_lp+:lg_sets_lp]; // 13:5
  assign tagfl_set_v = addr_v_i[lg_sets_lp+lg_block_size_in_words_lp+2];
  assign flush_instr = tagfl_op_v_i | ainv_op_v_i | afl_op_v_i | aflinv_op_v_i;
  assign dirty_and_valid = chosen_set_is_dirty_r & chosen_set_is_valid_r;

  assign evict_address_n = {
    (chosen_set_r ? tag1_v_i : tag0_v_i),
    miss_index_v,
    (2+lg_block_size_in_words_lp)'(0)
  };

  always_comb begin
    chosen_set_n = chosen_set_r;
    // to dma_engine
    mc_pass_addr_o = '0;
    mc_send_fill_req_o = 1'b0;
    mc_send_evict_req_o = 1'b0;
    mc_fill_line_o = 1'b0;
    mc_evict_line_o = 1'b0;
    // to tag_mem  
    tag_we_force_o = 1'b0;
    // to replacement
    wipe_v_o = 1'b0;
    status_mem_re_o = 1'b0;
    // to data_cache
    final_recover_o = 1'b0;
    chosen_set_o = chosen_set_r;


    case (miss_state_r) 
      
      //  When miss happens, read dirty bits and MRU.
      //  Depending on the instr_op, take either flush or fill path.
      START: begin
        status_mem_re_o = v_v_r_i & miss_v_i;
        miss_state_n = (v_v_r_i & miss_v_i & flush_instr)
          ? FLUSH_INSTR 
          : ((v_v_r_i & miss_v_i & (ld_op_v_i | st_op_v_i))
            ? FILL_SEND_ADDR
            : START);
      end
      
      // tell dma_engine to send fill request and addr.
      // calculate evict address.
      FILL_SEND_ADDR: begin
        chosen_set_n = (valid0_v_i ? (valid1_v_i ? ~mru_i : 1'b1) : 1'b0);
        chosen_set_is_dirty_n = chosen_set_n ? dirty_i[1] : dirty_i[0];
        chosen_set_is_valid_n = valid1_v_i & valid0_v_i;
        chosen_set_o = chosen_set_n;
        mc_send_fill_req_o = 1'b1;
        mc_pass_addr_o = addr_v_i;
        tag_we_force_o = dma_finished_i;
        wipe_v_o = dma_finished_i;
        
        miss_state_n = dma_finished_i
          ? ((chosen_set_is_dirty_n & chosen_set_is_valid_n) ? EVICT_SEND_ADDR : FILL_GET_DATA)
          : FILL_SEND_ADDR;
      end

      //  Calculate evict_address.
      //  If AINV or AFLINV, set valid bit to zero in tag_mem.
      //  We also set dirty bit of the chosen set to zero, and set MRU to the other set.
      FLUSH_INSTR: begin
        chosen_set_n = tagfl_op_v_i ? tagfl_set_v : tag_hit1_v_i;
        chosen_set_is_dirty_n = chosen_set_n ? dirty_i[1] : dirty_i[0];
        chosen_set_is_valid_n = chosen_set_n ? valid1_v_i : valid0_v_i;
        chosen_set_o = chosen_set_n;
        tag_we_force_o = ainv_op_v_i | aflinv_op_v_i;
        wipe_v_o = 1'b1;
        miss_state_n = (~ainv_op_v_i & (chosen_set_is_dirty_n & chosen_set_is_valid_n))
          ? EVICT_SEND_ADDR
          : FINAL_RECOVER;
      end

      // tell dma_engine to send evict request and addr.
      EVICT_SEND_ADDR: begin
        mc_send_evict_req_o = 1'b1;
        mc_pass_addr_o = evict_address_r;
        miss_state_n = dma_finished_i
          ? EVICT_SEND_DATA
          : EVICT_SEND_ADDR;
      end
      
      // tell dma_engine to send evict line, as soon as write_buffer is empty.
      EVICT_SEND_DATA: begin
        mc_evict_line_o = storebuf_empty_i;
        miss_state_n = dma_finished_i
          ? ((tagfl_op_v_i | aflinv_op_v_i | afl_op_v_i) ? FINAL_RECOVER : FILL_GET_DATA)
          : EVICT_SEND_DATA;
      end
  
      // tell dma_engine to start filling the cache, as soon as write_buffer is empty.
      FILL_GET_DATA: begin
        mc_fill_line_o = storebuf_empty_i;
        miss_state_n = dma_finished_i ? FINAL_RECOVER : FILL_GET_DATA;
      end

    
      FINAL_RECOVER: begin
        final_recover_o = 1'b1;
        miss_state_n = START;
      end

    endcase
  end

  always_ff @ (posedge clock_i) begin
    if (reset_i) begin
      miss_state_r <= START;
      chosen_set_r <= 1'b0;
      chosen_set_is_valid_r <= 1'b0;
      chosen_set_is_dirty_r <= 1'b0;
      evict_address_r <= '0;
    end 
    else begin
      miss_state_r <= miss_state_n;
      chosen_set_r <= chosen_set_n;
      chosen_set_is_valid_r <= chosen_set_is_valid_n;
      chosen_set_is_dirty_r <= chosen_set_is_dirty_n;
      evict_address_r <= evict_address_n;
    end
  end

endmodule
