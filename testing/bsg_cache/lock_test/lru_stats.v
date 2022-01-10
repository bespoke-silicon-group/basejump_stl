module lru_stats
  import bsg_cache_pkg::*;
  #(parameter `BSG_INV_PARAM(ways_p)
    ,localparam lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    )
  (
    input clk_i
    ,input reset_i

    ,input stat_mem_v_i
    ,input stat_mem_w_i
    ,input [lg_ways_lp-1:0] chosen_way_i
  );

  localparam ctr_width_lp = 17;
  localparam max_ctr_lp = 2**ctr_width_lp; // Max amounts of traces used in python scripts
  // Statistic of lru_way picked
  integer hit_counter [ways_p-1:0];
  logic [ways_p-1:0] counter_en_li;
  bsg_decode_with_v
   #(.num_out_p(ways_p)) 
   bdwv
    (.i(chosen_way_i)
    ,.v_i(stat_mem_v_i & stat_mem_w_i)
    ,.o(counter_en_li)
    );
  
  for (genvar i = 0; i < ways_p; i++)
    begin
      always_ff @(posedge clk_i) 
        begin
          if (reset_i)
              hit_counter[i] <= 0;
          else 
            begin
              if (counter_en_li[i])
                  hit_counter[i] <= hit_counter[i] + 1;
            end
        end
    end

  final 
    begin
      // display statistic
      $display("######## Hit Statistic: ########");
      for (integer counter_index = 0; counter_index < ways_p; counter_index++)
        begin
          $display("Hit counter[%d]: %d ", counter_index, hit_counter[counter_index]);
        end
    end

endmodule
`BSG_ABSTRACT_MODULE(lru_stats)
