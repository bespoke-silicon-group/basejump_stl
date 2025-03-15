/**
 *  bsg_fifo_store_forward.v
 *
 *  Paul Gao        04/2020
 *
 *  This module is designed for wormhole-like (multi-flits) traffic
 *  It first stores (len_li + 1) number of data flits inside data fifo,
 *  then bursts all flits out in one batch.
 *
 *  For each wormhole-like packet, len_li is extracted from first-flit 
 *  of packet (data_i[len_offset_p+:len_width_p]), which is equal to 
 *  (total_num_of_flits - 1).
 *
 */

module bsg_fifo_store_forward

 #(parameter width_p      = "inv"
  ,parameter len_offset_p = "inv"
  ,parameter len_width_p  = "inv"
  ,parameter max_els_p    = 2**len_width_p
  )

  (input clk_i
  ,input reset_i

  // Input side
  ,input                      v_i
  ,input  [width_p-1:0]       data_i
  ,output                     ready_o

  // Output side
  ,output                     v_o
  ,output [width_p-1:0]       data_o
  ,input                      yumi_i
  );

  /**************** data fifo and flow counter ****************/

  // data fifo
  // fifo depth is max_els_p + 1 to avoid bubble
  localparam fifo_depth_lp = max_els_p + 1;
  localparam ctr_width_lp = `BSG_WIDTH(fifo_depth_lp);
  
  logic fifo_v_lo;
  logic [ctr_width_lp-1:0] flow_count;

  bsg_fifo_1r1w_small
 #(.width_p(width_p      )
  ,.els_p  (fifo_depth_lp)
  ) data_fifo
  (.clk_i  (clk_i        )
  ,.reset_i(reset_i      )
  ,.ready_o(ready_o      )
  ,.data_i (data_i       )
  ,.v_i    (v_i          )
  ,.v_o    (fifo_v_lo    )
  ,.data_o (data_o       )
  ,.yumi_i (yumi_i       )
  );
  
  bsg_flow_counter 
 #(.els_p  (fifo_depth_lp)
  ) flow_ctr
  (.clk_i  (clk_i        )
  ,.reset_i(reset_i      )
  ,.v_i    (v_i          )
  ,.ready_i(ready_o      )
  ,.yumi_i (yumi_i       )
  ,.count_o(flow_count   )
  );
  
  /**************** output side control ****************/
  
  // count from '0 to maximum of '1
  localparam max_val_lp = 2**len_width_p - 1;

  logic [len_width_p-1:0] out_count_r, len_r, len_n, len_li;
  logic out_clear, out_up, out_count_zero, out_count_last, dff_en;
  
  assign out_count_zero = (out_count_r == '0   );
  assign out_count_last = (out_count_r == len_n);
  
  // when new packet coming, use new len, otherwise use registered len
  assign len_li = data_o[len_offset_p+:len_width_p];
  assign len_n  = (out_count_zero)? len_li : len_r;
  
  // send data out after all flits are received
  // len_n represents (total_num_flits-1)
  wire all_flits_received = (flow_count > (ctr_width_lp)'(len_n));
  assign v_o = fifo_v_lo & (all_flits_received | ~out_count_zero);
  
  // update length register only for first flit
  assign dff_en = yumi_i & out_count_zero;
  
  // count up if data word is not last word of current packet.
  assign out_up = yumi_i & ~out_count_last;
  
  // clear counter when it reaches target length
  assign out_clear = yumi_i & out_count_last;
  
  // Length register
  bsg_dff_reset_en
 #(.width_p    (len_width_p)
  ,.reset_val_p(0          )
  ) dff_len
  (.clk_i      (clk_i      )
  ,.reset_i    (reset_i    )
  ,.en_i       (dff_en     )
  ,.data_i     (len_li     )
  ,.data_o     (len_r      )
  );
  
  // output counter
  bsg_counter_clear_up
 #(.max_val_p (max_val_lp )
  ,.init_val_p(0          )
  ) out_ctr
  (.clk_i     (clk_i      )
  ,.reset_i   (reset_i    )
  ,.clear_i   (out_clear  )
  ,.up_i      (out_up     )
  ,.count_o   (out_count_r)
  );

endmodule