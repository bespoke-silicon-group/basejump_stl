module cov_top
  (
    input clk_i
    , input reset_i

    , input dma_data_mem_pkt_v_lo
    , input mhu_data_mem_pkt_v_lo
    , input v_i
    , input v_o
    , input ready_o
    , input yumi_i
   
  );

  covergroup cg_data_mem @ (posedge clk_i iff ~reset_i);

    coverpoint dma_data_mem_pkt_v_lo;
    coverpoint mhu_data_mem_pkt_v_lo;
    cross dma_data_mem_pkt_v_lo, mhu_data_mem_pkt_v_lo;

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

  initial begin
    cg_data_mem dmem = new;
  end


endmodule
