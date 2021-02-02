module hit_stats
  import bsg_cache_pkg::*;
  #(parameter ways_p="inv"
    ,localparam lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
    )
  (
    input clk_i
    ,input reset_i

    ,input miss_v_i
    ,input stat_mem_v_i
    ,input stat_mem_w_i
    ,input [lg_ways_lp-1:0] chosen_way_i
    
    ,input done_i
  );

  localparam ctr_width_lp = 17;
  localparam max_ctr_lp = 2**ctr_width_lp; // Max amounts of traces used in python scripts
  // Statistic of lru_way picked
  logic [ways_p-1:0][ctr_width_lp:0] hit_counter;
  logic [ways_p-1:0] counter_en_li;
  bsg_decode_with_v
   #(.num_out_p(ways_p)) 
   bdwv
    (.i(chosen_way_i)
    ,.v_i(stat_mem_v_i & stat_mem_w_i)
    ,.o(counter_en_li)
    );
  
  for (genvar i = 0; i < ways_p; i++)
    begin:rof
      bsg_counter_clear_up
       #(.max_val_p (max_ctr_lp)
       ,.init_val_p(0)) 
        ctr
        (.clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.clear_i(1'b0)
        ,.up_i(counter_en_li[i])
        ,.count_o (hit_counter[i])
        );      
    end

  always_comb 
    begin
       // display statistic
        integer counter_index;
        if (done_i) 
          begin
            $display("###### Hit Statistic:                  ######");
            for (counter_index = 0; counter_index < ways_p; counter_index++)
              begin
                $display("Hit counter[%d]: %d ", counter_index, hit_counter[counter_index]);
              end
        end
    
    end

endmodule