/**
 *  bsg_cache_miss.v
 *
 *  @author tommy
 */

module bsg_cache_miss
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter ways_p="inv"
    ,parameter tag_width_lp="inv"
    ,parameter stat_mem_width_lp=(2*ways_p-1)
    ,parameter lg_block_size_in_words_lp="inv"
    ,parameter lg_sets_lp="inv"
    ,parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    ,parameter lg_data_mask_width_lp="inv"
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
   
    ,input [ways_p-1:0][tag_width_lp-1:0] tag_v_i 
    ,input [ways_p-1:0]                   valid_v_i
    ,input [lg_ways_lp-1:0]               tag_hit_way_v_i
    ,input                                cache_line_not_full_v_i
    ,input [lg_ways_lp-1:0]               empty_way_v_i

    ,input sbuf_empty_i

    ,output logic dma_send_fill_addr_o
    ,output logic dma_send_evict_addr_o
    ,output logic dma_get_fill_data_o
    ,output logic dma_send_evict_data_o
    ,output logic dma_set_o
    ,output logic [addr_width_p-1:0] dma_addr_o 
    ,input dma_done_i 
   
    ,input [ways_p-1:0]     dirty_i
    ,input [lg_ways_lp-1:0] lru_way_i
  
    ,output logic                         stat_mem_v_o
    ,output logic                         stat_mem_w_o
    ,output logic [lg_sets_lp-1:0]        stat_mem_addr_o
    ,output logic [stat_mem_width_lp-1:0] stat_mem_data_o
    ,output logic [stat_mem_width_lp-1:0] stat_mem_w_mask_o

    ,output logic [(ways_p/2)-1:0]         tag_mem_v_o
    ,output logic                          tag_mem_w_o
    ,output logic [lg_sets_lp-1:0]         tag_mem_addr_o
    ,output logic [2*(tag_width_lp+1)-1:0] tag_mem_data_o
    ,output logic [2*(tag_width_lp+1)-1:0] tag_mem_w_mask_o
    ,output logic recover_o
    ,output logic done_o
  
    ,output logic [lg_ways_lp-1:0] chosen_way_o

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

  miss_state_e           miss_state_r;
  miss_state_e           miss_state_n;
  logic [lg_ways_lp-1:0] chosen_way_r;
  logic [lg_ways_lp-1:0] chosen_way_n;

  logic                                 flush_op;
  logic [tag_width_lp-1:0]              addr_tag_v;
  logic [lg_sets_lp-1:0]                addr_index_v;
  logic [lg_ways_lp-1:0]                addr_way_v;
  logic [lg_block_size_in_words_lp-1:0] addr_block_offset_v;
  logic [ways_p-2:0]                    lru_decode;
  logic [ways_p-2:0]                    lru_mask;

  assign flush_op = tagfl_op_v_i | ainv_op_v_i | afl_op_v_i | aflinv_op_v_i;
  assign addr_index_v
    = addr_v_i[lg_data_mask_width_lp+lg_block_size_in_words_lp+:lg_sets_lp];
  assign addr_tag_v
    = addr_v_i[lg_data_mask_width_lp+lg_block_size_in_words_lp+lg_sets_lp+:tag_width_lp];
  assign addr_way_v 
    = addr_v_i[lg_sets_lp+lg_block_size_in_words_lp+lg_data_mask_width_lp+:lg_ways_lp];
  assign addr_block_offset_v = addr_v_i[lg_data_mask_width_lp+:lg_block_size_in_words_lp];

  assign chosen_way_o = chosen_way_r;

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
    tag_mem_v_o = '0;
    tag_mem_w_o = 1'b0;
    tag_mem_addr_o = '0;
    tag_mem_data_o = '0;
    tag_mem_w_mask_o = '0;
    chosen_way_n = chosen_way_r;
    recover_o = '0;
    done_o = '0;
    dma_addr_o = '0;

    case (miss_state_r)

      START: begin
        stat_mem_v_o = 1'b1;
        miss_state_n = miss_v_i
          ? (flush_op ? FLUSH_OP : SEND_FILL_ADDR)
          : START;
      end
    
      SEND_FILL_ADDR: begin
        dma_send_fill_addr_o = 1'b1;
        chosen_way_n = cache_line_not_full_v_i ? empty_way_v_i : lru_way_i;
 
        dma_addr_o = {
          addr_tag_v, addr_index_v,
          {(lg_data_mask_width_lp+lg_block_size_in_words_lp){1'b0}}
        };

        stat_mem_v_o = dma_done_i;
        stat_mem_w_o = dma_done_i;
        stat_mem_addr_o = addr_index_v;
        stat_mem_data_o = {{ways_p{st_op_v_i}}, lru_decode};
        stat_mem_w_mask_o = {(ways_p'(1) << chosen_way_n), lru_mask};
 
        // Assert valid of chosen tag_mem instance. Each tag_mem instance 
        // contains two ways. Hence chosen_way_n/2 gives the index of memory 
        // instance to be updated. Valids of rest of the tag_mem instances
        // are assigned 0 by default.
        tag_mem_v_o[chosen_way_n>>1] = dma_done_i;

        tag_mem_w_o = dma_done_i;
        tag_mem_addr_o = addr_index_v;
        tag_mem_data_o = {2{1'b1, addr_tag_v}};
        tag_mem_w_mask_o = {
          {(1+tag_width_lp){chosen_way_n[0]}},
          {(1+tag_width_lp){~chosen_way_n[0]}}
        };

        miss_state_n = dma_done_i
          ? ((dirty_i[chosen_way_n] & valid_v_i[chosen_way_n]) ? SEND_EVICT_ADDR : GET_FILL_DATA)
          : SEND_FILL_ADDR;
      end

      FLUSH_OP: begin
        chosen_way_n = tagfl_op_v_i 
                         ? addr_way_v 
                         : tag_hit_way_v_i;
        
        stat_mem_v_o = 1'b1;
        stat_mem_w_o = 1'b1;
        stat_mem_addr_o = addr_index_v;
        stat_mem_data_o = {{ways_p{1'b0}}, lru_decode};
        stat_mem_w_mask_o = {(ways_p'(1) << chosen_way_n), lru_mask};
      
        tag_mem_v_o[chosen_way_n>>1] = 1'b1;
        tag_mem_w_o = 1'b1;
        tag_mem_addr_o = addr_index_v;
        tag_mem_data_o = {2{~(ainv_op_v_i | aflinv_op_v_i), {tag_width_lp{1'b0}}}};
        tag_mem_w_mask_o = {
          chosen_way_n[0], {tag_width_lp{1'b0}},
          ~chosen_way_n[0], {tag_width_lp{1'b0}}
        };
       
        miss_state_n = (~ainv_op_v_i & dirty_i[chosen_way_n] & valid_v_i[chosen_way_n])
          ? SEND_EVICT_ADDR
          : RECOVER;
      end
      
      SEND_EVICT_ADDR: begin
        dma_send_evict_addr_o = 1'b1;
        dma_addr_o = {
          tag_v_i[chosen_way_r],
          addr_index_v,
          {(lg_data_mask_width_lp+lg_block_size_in_words_lp){1'b0}}
        };

        miss_state_n = dma_done_i
          ? SEND_EVICT_DATA
          : SEND_EVICT_ADDR;

      end

      SEND_EVICT_DATA: begin
        dma_send_evict_data_o = sbuf_empty_i;
        dma_set_o = chosen_way_r[0];
        dma_addr_o = {
          tag_v_i[chosen_way_r],
          addr_index_v,
          {(lg_data_mask_width_lp+lg_block_size_in_words_lp){1'b0}}
        };
        
        miss_state_n = dma_done_i
          ? ((tagfl_op_v_i | aflinv_op_v_i | afl_op_v_i) ? RECOVER : GET_FILL_DATA)
          : SEND_EVICT_DATA;

      end
      
      GET_FILL_DATA: begin
        dma_get_fill_data_o = sbuf_empty_i;
        dma_set_o = chosen_way_r[0];
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

   // synopsys sync_set_reset "reset_i"
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      miss_state_r <= START;
      chosen_way_r <= '0;
    end
    else begin
      miss_state_r <= miss_state_n;
      chosen_way_r <= chosen_way_n;
    end
  end

  bsg_lru_pseudo_tree_decode #(
    .ways_p(ways_p)
  ) lru_decoder (
    .way_id_i(chosen_way_n)
    ,.data_o(lru_decode)
    ,.mask_o(lru_mask)
  );

endmodule
