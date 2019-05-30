/**
 *  bsg_serial_in_parallel_out_full_buffered.v
 *
 *  This is a simpler version of bsg_serial_in_parallel_out.
 *  Output is only valid, when the output vector is fully assembled.
 *  This version has zero bubble.
 *
 */

module bsg_serial_in_parallel_out_full_buffered

 #(parameter width_p="inv"
  ,parameter els_p="inv"
  ,parameter msb_first_p = 0
  ,localparam lg_els_lp=`BSG_SAFE_CLOG2(els_p)
  ,localparam end_count_lp = (msb_first_p == 0)? els_p-1 : 0
  ,localparam init_count_lp = (msb_first_p == 0)? 0 : els_p-1)
  
  (input clk_i
  ,input reset_i
    
  ,input v_i
  ,output logic ready_o
  ,input [width_p-1:0] data_i

  ,output logic [els_p-1:0][width_p-1:0] data_o
  ,output logic v_o
  ,input yumi_i);
  
  
  genvar i;
  
  logic [lg_els_lp-1:0] counter_r;
  logic [els_p-1:0] fifo_valid_li, fifo_ready_lo;
  logic [els_p-1:0] fifo_valid_lo, fifo_yumi_li;
  
  assign ready_o = fifo_ready_lo[counter_r];
  assign v_o = & fifo_valid_lo;
  
  for (i = 0; i < els_p; i++) begin: fifos
    
    assign fifo_valid_li[i] = (i == counter_r) & v_i;
    assign fifo_yumi_li[i] = yumi_i;
  
    bsg_two_fifo
    #(.width_p(width_p))
    fifo
    (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(fifo_ready_lo[i])
    ,.data_i(data_i)
    ,.v_i(fifo_valid_li[i])

    ,.v_o(fifo_valid_lo[i])
    ,.data_o(data_o[i])
    ,.yumi_i(fifo_yumi_li[i]));
    
  end
  
  logic end_count_lo, count_up_lo, count_down_lo;
  
  always_comb begin
    end_count_lo = 0;
    count_up_lo = 0;
    count_down_lo = 0;
    if (v_i & ready_o)
        if (counter_r == end_count_lp)
            end_count_lo = 1;
        else
            if (msb_first_p == 0) count_up_lo = 1;
            else count_down_lo = 1;
  end
  
  bsg_counter_up_down 
 #(.max_val_p(els_p-1)
  ,.init_val_p(init_count_lp)
  ,.max_step_p(1))
  counter
  (.clk_i(clk_i)
  ,.reset_i(reset_i | end_count_lo)
  ,.up_i(count_up_lo)
  ,.down_i(count_down_lo)
  ,.count_o(counter_r));

endmodule