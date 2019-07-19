//
// bsg_parallel_in_serial_out_dynamic.v
//
// Paul Gao        06/2019
//
// This is a 0-cycle delay parallel in serial out adapter 
// It supports adjusting conversion ratio dynamically with len_i
// 
// Note that the input side has valid-yumi interface, which means yumi_o
// will be asserted after v_i is asserted.
//
//

module bsg_parallel_in_serial_out_dynamic
                               
 #(parameter width_p                 = "inv"
  ,parameter max_els_p               = "inv"
  // By default, len_i should be set to (array_lenth-1)
  // When length_not_last_index_p=1, len_i should be set to array_lenth
  ,parameter length_not_last_index_p = 0
  ,parameter lg_max_els_lp = `BSG_SAFE_CLOG2(max_els_p)
  ,parameter len_width_p   = `BSG_SAFE_CLOG2(max_els_p+length_not_last_index_p)
  )
  
  (input clk_i
  ,input reset_i
  
  // Input side (valid->yumi)
  ,input                               v_i
  // len_i must be asserted as long as v_i and data_i are asserted
  ,input  [len_width_p-1:0]            len_i
  ,input  [max_els_p-1:0][width_p-1:0] data_i
  ,output                              yumi_o // late
  
  // Output side (valid->yumi)
  ,output                              v_o
  ,output [width_p-1:0]                data_o
  ,input                               yumi_i // late
  );

  logic [lg_max_els_lp-1:0] count_r, count_lo;
  logic clear_li, up_li;
  logic count_r_is_last;
  
  // fix evaluate to Z problem in simulation
  assign count_lo = count_r;
  
  // Counter always count from 0 to length-1
  // When length_not_last_index_p=1, len_i represents the array_length, in this case
  // len_i compares with (count_lo+1).
  assign count_r_is_last = ((len_width_p)'(count_lo+length_not_last_index_p) == len_i);
  
  // Count up if current word is not last word of packet.
  assign up_li = yumi_i & ~count_r_is_last;
  
  // Clear counter when whole packet finish sending
  assign clear_li = yumi_i & count_r_is_last;
  assign yumi_o = clear_li;
  
  // Output is valid as long as v_i is asserted
  assign v_o = v_i;
  
  // Length counter
  bsg_counter_clear_up
 #(.max_val_p (max_els_p-1)
  ,.init_val_p(0          )
  ) ctr
  (.clk_i     (clk_i      )
  ,.reset_i   (reset_i    )
  ,.clear_i   (clear_li   )
  ,.up_i      (up_li      )
  ,.count_o   (count_r    )
  );
  
  // Output mux
  bsg_mux
 #(.width_p(width_p  )
  ,.els_p  (max_els_p)
  ) data_mux
  (.data_i (data_i   )
  ,.sel_i  (count_lo )
  ,.data_o (data_o   )
  );

endmodule