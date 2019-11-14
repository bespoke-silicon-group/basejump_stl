module cov_miss_fifo
  import bsg_cache_non_blocking_pkg::*;
  (
    input clk_i
    , input reset_i
    
    , input v_i
    , input ready_o
    , input v_o
    , input yumi_i
    , input bsg_cache_non_blocking_miss_fifo_op_e yumi_op_i
    , input scan_not_dq_i
    , input read_write_same_addr
    , input mem_read_en_r
    , input v_r
    , input empty
    , input rptr_valid
    , input enque
    
//    , input rollback_i 
  );


  covergroup cg_output_taken @ (negedge clk_i iff v_r & yumi_i);

    coverpoint yumi_op_i;
    coverpoint mem_read_en_r;
    coverpoint read_write_same_addr;

    cross yumi_op_i, mem_read_en_r, read_write_same_addr;

  endgroup


  covergroup cg_input_output @ (negedge clk_i);

    coverpoint v_i;
    coverpoint ready_o;
    coverpoint v_o;
    coverpoint yumi_i;

    cross v_i, ready_o, v_o, yumi_i {
      ignore_bins n_v_o = 
        binsof(v_o) intersect {1'b0} &&
        binsof(yumi_i) intersect {1'b1};
    }

  endgroup 


  covergroup cg_output_not_valid @ (negedge clk_i);

    coverpoint empty;
    coverpoint scan_not_dq_i;
    coverpoint rptr_valid;
    coverpoint mem_read_en_r;
    coverpoint enque;

    cross empty, scan_not_dq_i, rptr_valid, mem_read_en_r, enque;

  endgroup


  initial begin
    cg_output_taken ot = new;
    cg_input_output io = new;
    cg_output_not_valid onv = new;
  end


endmodule
