module cov_bsg_cache_non_blocking_tl_stage
  (

    input clk_i
    , input reset_i

    , input ld_st_miss
    , input mhu_miss_match
    , input dma_miss_match
  );

  covergroup MissMatchCG @ (negedge clk_i iff ld_st_miss);

    mhu_match: coverpoint mhu_miss_match;
    dma_match: coverpoint dma_miss_match;

    cross mhu_match, dma_match {
      ignore_bins both_match = binsof(mhu_match) intersect {1'b1} && binsof(dma_match) intersect {1'b1};
    }

  endgroup

  initial begin
    MissMatchCG mm = new;
  end

endmodule
