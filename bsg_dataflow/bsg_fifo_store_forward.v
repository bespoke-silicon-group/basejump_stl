/**
 *  bsg_fifo_store_forward.v
 *
 *  Paul Gao        04/2020
 *
 *  This module is designed for wormhole-like (multi-flits) traffic
 *  It first stores (len_i + 1) number of data flits inside data fifo,
 *  then bursts all flits out in one batch.
 *
 */

module bsg_fifo_store_forward

 #(parameter width_p     = "inv"
  ,parameter len_width_p = "inv"
  ,parameter max_els_p   = 2**len_width_p
  )

  (input clk_i
  ,input reset_i

  // Input side
  ,input                      v_i
  //
  // len_i is logically associated with first-flit of data_i, and that the 
  // value must be held constant until first-flit is removed from data_i.
  //
  // len_i should be equal to (total_num_of_flits - 1)
  ,input  [len_width_p-1:0]   len_i
  ,input  [width_p-1:0]       data_i
  ,output                     ready_o

  // Output side
  ,output                     v_o
  ,output [width_p-1:0]       data_o
  ,input                      yumi_i
  );

  /**************** data and control fifos ****************/

  // data fifo
  // fifo depth is max_els_p + 1 to avoid bubble
  localparam fifo_depth_lp = max_els_p + 1;
  logic fifo_v_lo;

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
  
  // ctrl fifo
  // notify output side that packet(s) are ready to be sent
  // depth should match data_fifo to prevent overflow (ready_o not used)
  logic ctrl_fifo_v_li, ctrl_fifo_v_lo, ctrl_fifo_yumi_li;
  logic [len_width_p-1:0] ctrl_fifo_data_li, ctrl_fifo_data_lo;
  
  bsg_fifo_1r1w_small
 #(.width_p(len_width_p      )
  ,.els_p  (fifo_depth_lp    )
  ) ctrl_fifo
  (.clk_i  (clk_i            )
  ,.reset_i(reset_i          )
  ,.ready_o(/* not used */   )
  ,.data_i (ctrl_fifo_data_li)
  ,.v_i    (ctrl_fifo_v_li   )
  ,.v_o    (ctrl_fifo_v_lo   )
  ,.data_o (ctrl_fifo_data_lo)
  ,.yumi_i (ctrl_fifo_yumi_li)
  );
  
  /**************** input side control ****************/
  
  // count from '0 to maximum of '1
  localparam max_val_lp = 2**len_width_p - 1;

  logic [len_width_p-1:0] in_count_r, len_r, len_n;
  logic in_clear, in_up, in_count_zero, in_count_last, dff_en;
  
  assign in_count_zero = (in_count_r == '0   );
  assign in_count_last = (in_count_r == len_n);
  
  // when new packet coming, use new len, otherwise use registered len
  assign len_n = (in_count_zero)? len_i : len_r;
  
  // update length register only for first flit
  assign dff_en = v_i & ready_o & in_count_zero;
  
  // count up if data word is not last word of current packet.
  assign in_up = v_i & ready_o & ~in_count_last;
  
  // clear counter when it reaches target length
  // push registered length into ctrl_fifo at same time
  assign in_clear = v_i & ready_o & in_count_last;
  assign ctrl_fifo_v_li = in_clear;
  assign ctrl_fifo_data_li = len_r;
  
  // input counter
  bsg_counter_clear_up
 #(.max_val_p (max_val_lp)
  ,.init_val_p(0         )
  ) in_ctr
  (.clk_i     (clk_i     )
  ,.reset_i   (reset_i   )
  ,.clear_i   (in_clear  )
  ,.up_i      (in_up     )
  ,.count_o   (in_count_r)
  );
  
  // Length register
  bsg_dff_reset_en
 #(.width_p    (len_width_p)
  ,.reset_val_p(0          )
  ) dff_len
  (.clk_i      (clk_i      )
  ,.reset_i    (reset_i    )
  ,.en_i       (dff_en     )
  ,.data_i     (len_i      )
  ,.data_o     (len_r      )
  );
  
  /**************** output side control ****************/

  logic [len_width_p-1:0] out_count_r;
  logic out_clear, out_up, out_count_last;
  
  assign out_count_last = (out_count_r == ctrl_fifo_data_lo);
  
  // send data out after all flits are received
  assign v_o = ctrl_fifo_v_lo & fifo_v_lo;
  
  // count up if data word is not last word of current packet.
  assign out_up = yumi_i & ~out_count_last;
  
  // clear counter when it reaches target length
  // pop length out of ctrl_fifo at same time
  assign out_clear = yumi_i & out_count_last;
  assign ctrl_fifo_yumi_li = out_clear;
  
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