/**
 *  bsg_cache_miss.v
 *
 *  @author tommy
 */

module bsg_cache_miss
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter block_size_in_words_p="inv"
    ,parameter sets_p="inv"

    ,localparam lg_block_size_in_words_lp=`BSG_SAFE_CLOG2(block_size_in_words_p)
    ,localparam lg_sets_lp=`BSG_SAFE_CLOG2(sets_p)
    ,localparam lg_data_mask_width_lp=`BSG_SAFE_CLOG2(data_width_p>>3)
    ,localparam tag_width_lp=(addr_width_p-lg_data_mask_width_lp-lg_sets_lp-lg_block_size_in_words_lp)
  )
  (
    input clk_i
    ,input reset_i

    ,input miss_v_i
    ,input st_op_v_i
    ,input tagfl_op_v_i
    ,input afl_op_v_i
    ,input aflinv_op_v_i
    ,input ainv_op_v_i
    ,input [addr_width_p-1:0] addr_v_i
   
    ,input [1:0][tag_width_lp-1:0] tag_v_i 
    ,input [1:0] valid_v_i
    ,input [1:0] lock_v_i
    ,input [1:0] tag_hit_v_i

    ,input sbuf_empty_i

    ,output logic dma_send_fill_addr_o
    ,output logic dma_send_evict_addr_o
    ,output logic dma_get_fill_data_o
    ,output logic dma_send_evict_data_o
    ,output logic dma_set_o
    ,output logic [addr_width_p-1:0] dma_addr_o 
    ,input dma_done_i 
   
    ,input [1:0] dirty_i
    ,input mru_i
  
    ,output logic stat_mem_v_o
    ,output logic stat_mem_w_o
    ,output logic [lg_sets_lp-1:0] stat_mem_addr_o
    ,output logic [2:0] stat_mem_data_o
    ,output logic [2:0] stat_mem_w_mask_o

    ,output logic tag_mem_v_o
    ,output logic tag_mem_w_o
    ,output logic [lg_sets_lp-1:0] tag_mem_addr_o
    ,output logic [1:0][(tag_width_lp+2)-1:0] tag_mem_data_o
    ,output logic [1:0][(tag_width_lp+2)-1:0] tag_mem_w_mask_o
 
    ,output logic recover_o
    ,output logic done_o
  
    ,output logic chosen_set_o

    ,input ack_i
  );

  typedef enum logic [2:0] {
    START
    ,FLUSH_OP
    ,SEND_EVICT_ADDR
    ,SEND_FILL_ADDR
    ,SEND_EVICT_DATA
    ,GET_FILL_DATA
    ,RECOVER
    ,DONE
  } miss_state_e;

  miss_state_e miss_state_r;
  miss_state_e miss_state_n;
  logic chosen_set_r;
  logic chosen_set_n;

  logic flush_op;
  logic invalidate_op;
  logic [tag_width_lp-1:0] addr_tag_v;
  logic [lg_sets_lp-1:0] addr_index_v;
  logic addr_set_v;
  logic [lg_block_size_in_words_lp-1:0] addr_block_offset_v;

  assign invalidate_op = ainv_op_v_i | aflinv_op_v_i;
  assign flush_op = tagfl_op_v_i | ainv_op_v_i | afl_op_v_i | aflinv_op_v_i;
  assign addr_index_v
    = addr_v_i[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  assign addr_tag_v
    = addr_v_i[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp+:tag_width_lp];
  assign addr_set_v = addr_v_i[lg_sets_lp+lg_block_size_in_words_lp+lg_data_mask_width_lp];
  assign addr_block_offset_v = addr_v_i[lg_data_mask_width_lp+:lg_block_size_in_words_lp];

  assign chosen_set_o = chosen_set_r;

  logic stat_flopped_r, stat_flopped_n;
  logic [1:0] dirty_r, dirty_n;
  logic mru_r, mru_n;

  always_comb begin
    dma_send_fill_addr_o = 1'b0;
    dma_send_evict_addr_o = 1'b0;
    dma_get_fill_data_o = 1'b0;
    dma_send_evict_data_o = 1'b0;
    dma_set_o = 1'b0;
    stat_mem_v_o = 1'b0;
    stat_mem_w_o = 1'b0;
    stat_mem_addr_o = '0;
    stat_mem_data_o = '0;
    stat_mem_w_mask_o = '0;
    tag_mem_v_o = 1'b0;
    tag_mem_w_o = 1'b0;
    tag_mem_addr_o = '0;
    tag_mem_data_o = '0;
    tag_mem_w_mask_o = '0;
    chosen_set_n = chosen_set_r;
    recover_o = '0;
    done_o = '0;
    dma_addr_o = '0;
    stat_flopped_n = stat_flopped_r;
    dirty_n = dirty_r;
    mru_n = mru_r;

    case (miss_state_r)

      START: begin
        stat_mem_v_o = miss_v_i;
        stat_flopped_n = 1'b0;
        miss_state_n = miss_v_i
          ? (flush_op ? FLUSH_OP : SEND_FILL_ADDR)
          : START;
      end
    
      SEND_FILL_ADDR: begin
        stat_flopped_n = 1'b1;
        mru_n = stat_flopped_r
          ? mru_r
          : mru_i;
        dirty_n = stat_flopped_r
          ? dirty_r
          : dirty_i;
        dma_send_fill_addr_o = 1'b1;
       
        // ----------------------------------------------------------- 
        // lock[0]  lock[1] valid[1]  valid[0]  mru_n  |  chosen_set_n
        // -----------------------------------------------------------
        // 1        X       X         X         X      |  1
        // 0        1       X         X         X      |  0
        // 0        0       0         X         X      |  0
        // 0        0       1         0         X      |  1
        // 0        0       1         1         0      |  1
        // 0        0       1         1         1      |  0
        // -----------------------------------------------------------
        chosen_set_n = lock_v_i[0]
          | (~lock_v_i[1] & valid_v_i[0] & (~valid_v_i[1] | ~mru_n));
       
        dma_addr_o = {
          addr_tag_v, addr_index_v,
          {(lg_data_mask_width_lp+lg_block_size_in_words_lp){1'b0}}
        };

        stat_mem_v_o = dma_done_i;
        stat_mem_w_o = dma_done_i;
        stat_mem_addr_o = addr_index_v;
        stat_mem_data_o = {{2{st_op_v_i}}, chosen_set_n};
        stat_mem_w_mask_o = {chosen_set_n, ~chosen_set_n, 1'b1}; // dirty[1], dirty[0], mru

        tag_mem_v_o = dma_done_i;
        tag_mem_w_o = dma_done_i;
        tag_mem_addr_o = addr_index_v;
        tag_mem_data_o = {2{1'b1, 1'b0, addr_tag_v}};
        tag_mem_w_mask_o[1] = {chosen_set_n, 1'b0, {tag_width_lp{chosen_set_n}}};
        tag_mem_w_mask_o[0] = {~chosen_set_n, 1'b0, {tag_width_lp{~chosen_set_n}}};

        miss_state_n = dma_done_i
          ? ((dirty_n[chosen_set_n] & valid_v_i[chosen_set_n]) ? SEND_EVICT_ADDR : GET_FILL_DATA)
          : SEND_FILL_ADDR;
      end

      FLUSH_OP: begin
        stat_flopped_n = 1'b1;
        dirty_n = stat_flopped_r
          ? dirty_r
          : dirty_i;

        chosen_set_n = tagfl_op_v_i ? addr_set_v : tag_hit_v_i[1];
        
        stat_mem_v_o = 1'b1;
        stat_mem_w_o = 1'b1;
        stat_mem_addr_o = addr_index_v;
        stat_mem_data_o = {2'b0, ~chosen_set_n};
        stat_mem_w_mask_o = {chosen_set_n, ~chosen_set_n, 1'b1};
      
        tag_mem_v_o = 1'b1;
        tag_mem_w_o = 1'b1;
        tag_mem_addr_o = addr_index_v;
        tag_mem_data_o = {2{1'b0, 1'b0, {tag_width_lp{1'b0}}}};
        tag_mem_w_mask_o[1] = {chosen_set_n & invalidate_op, 1'b0, {tag_width_lp{1'b0}}};
        tag_mem_w_mask_o[0] = {~chosen_set_n & invalidate_op, 1'b0, {tag_width_lp{1'b0}}};
       
        miss_state_n = (~ainv_op_v_i & dirty_n[chosen_set_n] & valid_v_i[chosen_set_n])
          ? SEND_EVICT_ADDR
          : RECOVER;
      end
      
      SEND_EVICT_ADDR: begin
        dma_send_evict_addr_o = 1'b1;
        dma_addr_o = {
          tag_v_i[chosen_set_r],
          addr_index_v,
          {(lg_data_mask_width_lp+lg_block_size_in_words_lp){1'b0}}
        };

        miss_state_n = dma_done_i
          ? SEND_EVICT_DATA
          : SEND_EVICT_ADDR;

      end

      SEND_EVICT_DATA: begin
        dma_send_evict_data_o = sbuf_empty_i;
        dma_set_o = chosen_set_r;
        dma_addr_o = {
          tag_v_i[chosen_set_r],
          addr_index_v,
          {(lg_data_mask_width_lp+lg_block_size_in_words_lp){1'b0}}
        };
        
        miss_state_n = dma_done_i
          ? ((tagfl_op_v_i | aflinv_op_v_i | afl_op_v_i) ? RECOVER : GET_FILL_DATA)
          : SEND_EVICT_DATA;

      end
      
      GET_FILL_DATA: begin
        dma_get_fill_data_o = sbuf_empty_i;
        dma_set_o = chosen_set_r;
        dma_addr_o = {
          addr_tag_v,
          addr_index_v,
          addr_block_offset_v,
          {(lg_data_mask_width_lp){1'b0}}
        };

        miss_state_n = dma_done_i
          ? RECOVER
          : GET_FILL_DATA;
      end
    
      RECOVER: begin
        recover_o = 1'b1;
        miss_state_n = DONE;
      end

      DONE: begin
        done_o = 1'b1;
        miss_state_n = ack_i ? START : DONE;
      end

    endcase
  end

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      miss_state_r <= START;
      chosen_set_r <= 1'b0;
      stat_flopped_r <= 1'b0;
    end
    else begin
      miss_state_r <= miss_state_n;
      chosen_set_r <= chosen_set_n;
      stat_flopped_r <= stat_flopped_n;
      dirty_r <= dirty_n;
      mru_r <= mru_n;
    end
  end

endmodule
