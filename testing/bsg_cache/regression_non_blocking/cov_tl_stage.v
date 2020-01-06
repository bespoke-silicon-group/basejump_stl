module cov_tl_stage
  import bsg_cache_non_blocking_pkg::*;
  (

    input clk_i
    , input reset_i

    , input ld_st_miss
    , input mhu_miss_match
    , input dma_miss_match

    , input ld_st_hit
    , input data_mem_pkt_ready_i
    , input stat_mem_pkt_ready_i
    , input v_i
    , input bsg_cache_non_blocking_decode_s decode_i
    , input miss_fifo_ready_i
    , input recover_i
    , input v_tl_r
    , input mhu_tag_mem_pkt_v_i
    , input mhu_idle_i
  );

  wire decode_mgmt_op = decode_i.mgmt_op;

  covergroup cg_miss_match @ (negedge clk_i iff ld_st_miss);

    coverpoint mhu_miss_match;
    coverpoint dma_miss_match;

    cross mhu_miss_match, dma_miss_match {
      ignore_bins both_match = binsof(mhu_miss_match) intersect {1'b1} 
                            && binsof(dma_miss_match) intersect {1'b1};
    }

  endgroup

  
  covergroup cg_ld_st_hit @ (negedge clk_i iff ld_st_hit);
  
    coverpoint v_i;
    coverpoint data_mem_pkt_ready_i;
    coverpoint stat_mem_pkt_ready_i;
    coverpoint decode_mgmt_op;

    cross v_i, data_mem_pkt_ready_i, stat_mem_pkt_ready_i, decode_mgmt_op {
      ignore_bins invalid_mgmt_op = binsof(v_i) intersect {1'b0}
                                 && binsof(decode_mgmt_op) intersect {1'b1};
    }

  endgroup


  covergroup cg_ld_st_miss @ (negedge clk_i iff ld_st_miss);

    coverpoint miss_fifo_ready_i;
    coverpoint v_i;
    coverpoint decode_mgmt_op;
    
    cross v_i, miss_fifo_ready_i, decode_mgmt_op {
      ignore_bins invalid_mgmt_op = binsof(v_i) intersect {1'b0}
                                 && binsof(decode_mgmt_op) intersect {1'b1};
    }
    

  endgroup


  covergroup cg_tl_empty @ (negedge clk_i iff ~v_tl_r);
    
    coverpoint recover_i;
    coverpoint mhu_tag_mem_pkt_v_i;
    coverpoint decode_mgmt_op;
    coverpoint v_i;
    coverpoint mhu_idle_i;

    cross v_i, recover_i, mhu_tag_mem_pkt_v_i, decode_mgmt_op, mhu_idle_i {
      ignore_bins invalid_mgmt_op = binsof(v_i) intersect {1'b0}
                                 && binsof(decode_mgmt_op) intersect {1'b1};
      ignore_bins recover_mhu_pkt = binsof(recover_i) intersect {1'b1}
                                 && binsof(mhu_tag_mem_pkt_v_i) intersect {1'b1};
      ignore_bins mhu_idle = (binsof(recover_i) intersect {1'b1} || binsof(mhu_tag_mem_pkt_v_i) intersect {1'b1})
                           && binsof(mhu_idle_i) intersect {1'b1};
    }


  endgroup


  initial begin
    cg_miss_match mm = new;
    cg_ld_st_hit ls = new;
    cg_ld_st_miss lsm = new;
    cg_tl_empty te = new;
  end

endmodule
