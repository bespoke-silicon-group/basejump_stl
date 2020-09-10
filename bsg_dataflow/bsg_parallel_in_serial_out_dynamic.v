/**
 *  bsg_parallel_in_serial_out_dynamic.v
 *
 *  Paul Gao        06/2019
 *
 */

`include "bsg_defines.v"

module bsg_parallel_in_serial_out_dynamic
                               
 #(parameter width_p          = "inv"
  ,parameter max_els_p        = "inv"
  ,parameter lg_max_els_lp    = `BSG_SAFE_CLOG2(max_els_p)
  )
  
  (input clk_i
  ,input reset_i
  
  // Input side
  ,input                               v_i
  ,input  [lg_max_els_lp-1:0]          len_i
  ,input  [max_els_p-1:0][width_p-1:0] data_i
  ,output                              ready_o
  
  // Output side
  ,output                              v_o
  ,output                              len_v_o
  ,output [width_p-1:0]                data_o
  ,input                               yumi_i
  );

  logic                              go_fifo_yumi_li;
  logic [lg_max_els_lp-1:0]          len_lo;
  logic [max_els_p-1:0][width_p-1:0] fifo_data_lo;
  
  // Go fifo and data fifo share the same control logic
  // They always contain same number of elements in memory
  
  // Go fifo
  bsg_two_fifo
 #(.width_p(lg_max_els_lp  )
  ) go_fifo
  (.clk_i  (clk_i          )
  ,.reset_i(reset_i        )
  
  ,.ready_o(ready_o        )
  ,.data_i (len_i          )
  ,.v_i    (v_i            )
  
  ,.v_o    (v_o            )
  ,.data_o (len_lo         )
  ,.yumi_i (go_fifo_yumi_li)
  );

  // Data fifo
  bsg_two_fifo
 #(.width_p(max_els_p*width_p)
  ) data_fifo
  (.clk_i  (clk_i            )
  ,.reset_i(reset_i          )
                             
  ,.ready_o(                 )
  ,.data_i (data_i           )
  ,.v_i    (v_i              )
                             
  ,.v_o    (                 )
  ,.data_o (fifo_data_lo     )
  ,.yumi_i (go_fifo_yumi_li  )
  );
  
  logic [lg_max_els_lp-1:0] count_r, count_lo;
  logic clear_li, up_li;
  logic count_r_is_zero, count_r_is_last;
  
  // fix evaluate to Z problem in simulation
  assign count_lo = count_r;
  
  assign count_r_is_zero = (count_lo == lg_max_els_lp'(0));
  assign count_r_is_last = (count_lo == len_lo           );
  
  // Indicate if output word is first word of packet
  assign len_v_o = count_r_is_zero;
  
  // Count up if current word is not last word of packet.
  assign up_li = yumi_i & ~count_r_is_last;
  
  // Clear counter when whole packet finish sending
  assign clear_li = yumi_i & count_r_is_last;
  assign go_fifo_yumi_li = clear_li;
  
  // Length counter
  bsg_counter_clear_up
 #(.max_val_p (max_els_p-1)
  ,.init_val_p(0)
  ) ctr
  (.clk_i     (clk_i   )
  ,.reset_i   (reset_i )
  ,.clear_i   (clear_li)
  ,.up_i      (up_li   )
  ,.count_o   (count_r )
  );
  
  // Output mux
  bsg_mux
 #(.width_p(width_p     )
  ,.els_p  (max_els_p   )
  ) data_mux
  (.data_i (fifo_data_lo)
  ,.sel_i  (count_lo    )
  ,.data_o (data_o      )
  );

endmodule