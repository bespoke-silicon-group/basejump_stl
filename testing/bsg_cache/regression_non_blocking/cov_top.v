module cov_top
  (
    input clk_i
    , input reset_i

    , input dma_data_mem_pkt_v_lo
    , input mhu_data_mem_pkt_v_lo
   
  );

  covergroup DataMemCG @ (posedge clk_i iff ~reset_i);

    dma_v: coverpoint dma_data_mem_pkt_v_lo;
    mhu_v: coverpoint mhu_data_mem_pkt_v_lo;
    cross dma_v, mhu_v;

  endgroup


  initial begin
    DataMemCG dmem = new;
  end


endmodule
