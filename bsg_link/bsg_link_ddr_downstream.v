//
// Paul Gao 03/2019
//
// This is a DDR receiver
// All data received by DDR PHY are routed to SSI flow control unit
// Then go through serial-in-parallel-out to assemble the output packet
// 
// Refer to bsg_link_source_sync_downstream for more information on flow control
//
//

module bsg_link_ddr_downstream

 #(parameter width_p = "inv"
  ,parameter channel_width_p = 8
  ,parameter num_channel_p = 1
  ,parameter lg_fifo_depth_p = 6
  ,parameter lg_credit_to_token_decimation_p = 3
  ,localparam ddr_width_lp = channel_width_p*2
  ,localparam piso_ratio_lp = width_p/(ddr_width_lp*num_channel_p))

  (input clk_i
  ,input link_reset_i
  ,input chip_reset_i
  ,output link_enable_o
  
  ,output [width_p-1:0] data_o
  ,output valid_o
  ,input yumi_i
  
  ,input [num_channel_p-1:0] io_clk_i
  ,input [num_channel_p-1:0][channel_width_p-1:0] io_data_i
  ,input [num_channel_p-1:0] io_valid_i
  ,output logic [num_channel_p-1:0] io_token_r_o);
  
  
  logic in_ps_ready_lo, in_ps_yumi_lo;
  logic [num_channel_p-1:0][ddr_width_lp-1:0] in_ps_data_li;
  
  // From different channels
  logic [num_channel_p-1:0] in_ps_valid_li;
  assign in_ps_yumi_lo = (& in_ps_valid_li) & in_ps_ready_lo;
  
  
  // When piso is not needed
  
  if (ddr_width_lp*num_channel_p >= width_p) begin: fifo
  
    bsg_two_fifo
   #(.width_p(width_p))
    in_fifo
    (.clk_i(clk_i)
    ,.reset_i(chip_reset_i)
    ,.ready_o(in_ps_ready_lo)
    ,.data_i(in_ps_data_li)
    ,.v_i(& in_ps_valid_li)
    ,.v_o(valid_o)
    ,.data_o(data_o)
    ,.yumi_i(yumi_i));
    
  end else begin: sipof
  
    bsg_serial_in_parallel_out_full_buffered
   #(.width_p(ddr_width_lp*num_channel_p)
    ,.els_p(piso_ratio_lp))
    in_sipof
    (.clk_i(clk_i)
    ,.reset_i(chip_reset_i)
    ,.v_i(& in_ps_valid_li)
    ,.ready_o(in_ps_ready_lo)
    ,.data_i(in_ps_data_li)
    ,.data_o(data_o)
    ,.v_o(valid_o)
    ,.yumi_i(yumi_i));  
  
  end
  
  
  // Support multiple channels
  
  genvar i;
  
  for (i = 0; i < num_channel_p; i++) begin:ch
  
    logic [1:0] in_ddr_valid_i;
    logic [ddr_width_lp-1:0] in_ddr_data_i;

    bsg_link_source_sync_downstream
   #(.channel_width_p(ddr_width_lp)
    ,.lg_fifo_depth_p(lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p))
    downstream
    (.core_clk_i(clk_i)
    ,.core_reset_i(link_reset_i)
    ,.link_enable_o(link_enable_o)

    // source synchronous input channel; coming from chip edge
    ,.io_clk_i(io_clk_i[i])
    ,.io_data_i(in_ddr_data_i)
    ,.io_valid_i(in_ddr_valid_i[0])
    ,.io_token_r_o(io_token_r_o[i])

    // going into core; uses core clock
    ,.core_data_o(in_ps_data_li[i])
    ,.core_valid_o(in_ps_valid_li[i])
    ,.core_yumi_i(in_ps_yumi_lo));


    bsg_link_iddr_phy
   #(.width_p(channel_width_p))
    iddr_data
    (.clk_i(io_clk_i[i])
    ,.data_i(io_data_i[i])
    ,.data_o(in_ddr_data_i));


    bsg_link_iddr_phy
   #(.width_p(1))
    iddr_valid
    (.clk_i(io_clk_i[i])
    ,.data_i(io_valid_i[i])
    ,.data_o(in_ddr_valid_i));
  
  end
  

endmodule