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
  ,parameter msb_then_lsb_p = 0
  ,localparam lg_els_lp=`BSG_SAFE_CLOG2(els_p))
  
  (input clk_i
  ,input reset_i
    
  ,input v_i
  ,output logic ready_o
  ,input [width_p-1:0] data_i

  ,output logic [els_p-1:0][width_p-1:0] data_o
  ,output logic v_o
  ,input yumi_i);
  
  localparam terminate_cnt_lp = (msb_then_lsb_p == 0)? els_p-1 : 0;
  localparam init_cnt_lp = (msb_then_lsb_p == 0)? 0 : els_p-1;
  
  genvar i;
  
  logic [lg_els_lp-1:0] counter_r, counter_n;
  logic [els_p-1:0] fifo_valid_i, fifo_ready_o;
  logic [els_p-1:0] fifo_valid_o, fifo_yumi_i;
  
  assign ready_o = fifo_ready_o[counter_r];
  assign v_o = & fifo_valid_o;
  
  for (i = 0; i < els_p; i++) begin: fifos
    
    assign fifo_valid_i[i] = (i == counter_r) & v_i;
    assign fifo_yumi_i[i] = yumi_i;
  
    bsg_two_fifo
    #(.width_p(width_p))
    fifo
    (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(fifo_ready_o[i])
    ,.data_i(data_i)
    ,.v_i(fifo_valid_i[i])

    ,.v_o(fifo_valid_o[i])
    ,.data_o(data_o[i])
    ,.yumi_i(fifo_yumi_i[i]));
    
  end
  
  always @(posedge clk_i) begin
    counter_r <= (reset_i)? init_cnt_lp : counter_n;
  end
  
  always_comb begin
    counter_n = counter_r;
    if (v_i & ready_o) begin
        if (counter_r == terminate_cnt_lp) begin
            counter_n = init_cnt_lp;
        end else begin
            counter_n = (msb_then_lsb_p == 0)? counter_r+1 : counter_r-1;
        end
    end
  end

endmodule
