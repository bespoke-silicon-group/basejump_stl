

module bsg_link_ddr

 #(parameter width_p = "inv"
  ,parameter channel_width_p = 8
  ,parameter num_channel_p = 1
  ,parameter lg_fifo_depth_p = 6
  ,parameter lg_credit_to_token_decimation_p = 3)

  (// chip logic clock
   input clk_i
   
   // IO clocks
  ,input clk_1x_i
  ,input clk_2x_i
  
  // all control signals synchronous to clk_i
  ,input reset_i
  ,input chip_reset_i
  ,input link_enable_i
  ,output link_enable_o
    
  // core side
  ,input [width_p-1:0] data_i
  ,input valid_i
  ,output ready_o

  ,output [width_p-1:0] data_o
  ,output valid_o
  ,input yumi_i

  // io side
  ,output logic [num_channel_p-1:0] io_clk_r_o
  ,output logic [num_channel_p-1:0][channel_width_p-1:0] io_data_r_o
  ,output logic [num_channel_p-1:0] io_valid_r_o
  ,input [num_channel_p-1:0] io_token_i
    
  ,input [num_channel_p-1:0] io_clk_i
  ,input [num_channel_p-1:0][channel_width_p-1:0] io_data_i
  ,input [num_channel_p-1:0] io_valid_i
  ,output logic [num_channel_p-1:0] io_token_r_o);
  
  
  bsg_link_ddr_upstream
 #(.width_p(width_p)
  ,.channel_width_p(channel_width_p)
  ,.num_channel_p(num_channel_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p))
  upstream
  (.clk_i
  ,.clk_1x_i
  ,.clk_2x_i
  ,.reset_i
  ,.chip_reset_i
  ,.link_enable_i
  
  ,.data_i
  ,.valid_i
  ,.ready_o
  
  ,.io_clk_r_o
  ,.io_data_r_o
  ,.io_valid_r_o
  ,.io_token_i);
  
  
  bsg_link_ddr_downstream
 #(.width_p(width_p)
  ,.channel_width_p(channel_width_p)
  ,.num_channel_p(num_channel_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p))
  downstream
  (.clk_i
  ,.reset_i
  ,.chip_reset_i
  ,.link_enable_o
  
  ,.data_o
  ,.valid_o
  ,.yumi_i
  
  ,.io_clk_i
  ,.io_data_i
  ,.io_valid_i
  ,.io_token_r_o);
  

endmodule