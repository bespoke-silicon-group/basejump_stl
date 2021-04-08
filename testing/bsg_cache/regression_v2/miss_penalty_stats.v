  
  /* This model aimed at recording the number of miss and the miss cycle penalty 
     due to store miss and cache line allocate miss 
  */

module miss_penalty_stats
  import bsg_cache_pkg::*;
  (
    input clk_i
    ,input reset_i

    ,input miss_v_i
    ,input bsg_cache_decode_s decode_v_i

    ,input logic done_o

  );

  localparam ctr_width_lp = 17;
  localparam max_ctr_lp = 2**ctr_width_lp; // Max amounts of traces used in python scripts

  logic store_miss;
  assign store_miss = miss_v_i & (decode_v_i.st_op || decode_v_i.aalloc_op || decode_v_i.aallocz_op);


  integer store_miss_count, miss_cycle_counter, penalty_cycle_per_miss;
  always_ff @(posedge clk_i) 
    begin
      if (reset_i)
        begin
            store_miss_count   <= 0;
            miss_cycle_counter <= 0;
        end
      else 
        begin
          if (store_miss)
            begin
              store_miss_count   <= store_miss_count + done_o;
              miss_cycle_counter <= miss_cycle_counter + 1;
            end
        end
    end

  assign penalty_cycle_per_miss = miss_cycle_counter/store_miss_count;

  final 
    begin
      // display statistic
      $display("######## Miss Penalty Statistic: ########");
      $display("Store Miss Count %d ", store_miss_count);
      $display("Miss Cycle Count: %d ", miss_cycle_counter);
      $display("Ave Miss Cycle: %d ", penalty_cycle_per_miss);

    end

endmodule