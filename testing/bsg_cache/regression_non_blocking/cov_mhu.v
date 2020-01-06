module cov_mhu
  import bsg_cache_non_blocking_pkg::*;
  (
    input clk_i
    , input reset_i
    
    , input mhu_state_e mhu_state_r

    , input data_mem_pkt_yumi_i
    , input is_secondary
    , input miss_fifo_v_i
    , input tl_block_loading_i
    
  );

  covergroup cg_dequeue_mode @ (negedge clk_i iff mhu_state_r == DEQUEUE_MODE);

    coverpoint data_mem_pkt_yumi_i;
    coverpoint is_secondary;
    coverpoint miss_fifo_v_i;
    coverpoint tl_block_loading_i;

    cross data_mem_pkt_yumi_i, is_secondary, miss_fifo_v_i, tl_block_loading_i {
      ignore_bins non_secondary =
        binsof(data_mem_pkt_yumi_i) intersect {1'b1} &&
        binsof(is_secondary) intersect {1'b0};

      ignore_bins tl_block_load = 
        binsof(tl_block_loading_i) intersect {1'b1} && 
        binsof(data_mem_pkt_yumi_i) intersect {1'b1};

      ignore_bins miss_fifo_not_v = 
        binsof(miss_fifo_v_i) intersect {1'b0} && 
        (binsof(data_mem_pkt_yumi_i) intersect {1'b1} || binsof(is_secondary) intersect {1'b0});
        
    }

  endgroup


  covergroup cg_scan_mode @ (negedge clk_i iff mhu_state_r == SCAN_MODE);
  
    coverpoint miss_fifo_v_i;
    coverpoint is_secondary;
    coverpoint data_mem_pkt_yumi_i;
    coverpoint tl_block_loading_i;

    cross data_mem_pkt_yumi_i, is_secondary, miss_fifo_v_i, tl_block_loading_i {
      ignore_bins miss_fifo_not_v = 
        binsof(miss_fifo_v_i) intersect {1'b0} && 
        (binsof(data_mem_pkt_yumi_i) intersect {1'b1} || binsof(is_secondary) intersect {1'b0});

      ignore_bins non_secondary =
        binsof(data_mem_pkt_yumi_i) intersect {1'b1} &&
        binsof(is_secondary) intersect {1'b0};

      ignore_bins tl_block_load = 
        binsof(tl_block_loading_i) intersect {1'b1} && 
        binsof(data_mem_pkt_yumi_i) intersect {1'b1};
    }

  endgroup

  initial begin
    cg_dequeue_mode dq = new;
    cg_scan_mode sc = new;
  end

endmodule
