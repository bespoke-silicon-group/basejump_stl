//
// Paul Gao 03/2019
//
// This is a DDR transmitter
// All data received go through parallel-in-serial-out to deassemble, 
// then routed to source-sync-output module for flow control.
// ODDR PHY sends out packets with center-aligned DDR clock
// 
// Refer to bsg_link_source_sync_upstream for more information on flow control
//
//

module bsg_link_ddr_upstream

 #(parameter width_p = "inv"
  ,parameter channel_width_p = 8
  ,parameter num_channel_p = 1
  ,parameter lg_fifo_depth_p = 6
  ,parameter lg_credit_to_token_decimation_p = 3
  ,localparam ddr_width_lp = channel_width_p*2
  ,localparam posi_ratio_lp = width_p/(ddr_width_lp*num_channel_p))

  (input clk_i
  ,input clk_1x_i
  ,input clk_2x_i
  ,input link_reset_i
  ,input chip_reset_i
  ,input link_enable_i
    
  ,input [width_p-1:0] data_i
  ,input valid_i
  ,output ready_o  

  ,output logic [num_channel_p-1:0] io_clk_r_o
  ,output logic [num_channel_p-1:0][channel_width_p-1:0] io_data_r_o
  ,output logic [num_channel_p-1:0] io_valid_r_o
  ,input [num_channel_p-1:0] io_token_i);
  
  
  logic out_ps_valid_lo, out_ps_yumi_li;
  logic [num_channel_p-1:0][ddr_width_lp-1:0] out_ps_data_lo;
  
  // returned from different channels
  logic [num_channel_p-1:0] out_ps_ready_li;
  assign out_ps_yumi_li = (& out_ps_ready_li) & out_ps_valid_lo;
  
  
  // When piso is not needed
  
  if (ddr_width_lp*num_channel_p >= width_p) begin: fifo
  
    bsg_two_fifo
   #(.width_p(width_p))
    out_fifo
    (.clk_i(clk_i)
    ,.reset_i(chip_reset_i)
    ,.ready_o(ready_o)
    ,.data_i(data_i)
    ,.v_i(valid_i)
    ,.v_o(out_ps_valid_lo)
    ,.data_o(out_ps_data_lo)
    ,.yumi_i(out_ps_yumi_li));
  
  end else begin: piso
  
    bsg_parallel_in_serial_out 
   #(.width_p(ddr_width_lp*num_channel_p)
    ,.els_p(posi_ratio_lp))
    out_piso
    (.clk_i(clk_i)
    ,.reset_i(chip_reset_i)
    ,.valid_i(valid_i)
    ,.data_i(data_i)
    ,.ready_o(ready_o)
    ,.valid_o(out_ps_valid_lo)
    ,.data_o(out_ps_data_lo)
    ,.yumi_i(out_ps_yumi_li));
  
  end
  
  
  // Support multiple channels
  
  genvar i;
  
  for (i = 0; i < num_channel_p; i++) begin: ch
  
    logic io_reset_lo;
    logic out_ddr_valid_o;
    logic [ddr_width_lp-1:0] out_ddr_data_o;

    bsg_link_source_sync_upstream
   #(.channel_width_p(ddr_width_lp)
    ,.lg_fifo_depth_p(lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p))
    sso
    (// control signals  
     .core_clk_i(clk_i)
    ,.core_reset_i(link_reset_i)
    ,.io_master_clk_i(clk_1x_i)
    ,.link_enable_i(link_enable_i)
    ,.io_reset_o(io_reset_lo)

    // Input from chip core
    ,.core_data_i(out_ps_data_lo[i])
    ,.core_valid_i(out_ps_yumi_li)
    ,.core_ready_o(out_ps_ready_li[i])

    // source synchronous output channel; going to chip edge
    ,.io_data_r_o(out_ddr_data_o)
    ,.io_valid_r_o(out_ddr_valid_o)
    ,.token_clk_i(io_token_i[i]));


    bsg_link_oddr_phy
   #(.width_p(channel_width_p))
    oddr_data
    (.reset_i(io_reset_lo)
    ,.clk_2x_i(clk_2x_i)
    ,.data_i(out_ddr_data_o)
    ,.data_r_o(io_data_r_o[i])
    ,.clk_r_o());


    bsg_link_oddr_phy
   #(.width_p(1))
    oddr_valid_clk
    (.reset_i(io_reset_lo)
    ,.clk_2x_i(clk_2x_i)
    ,.data_i({2{out_ddr_valid_o}})
    ,.data_r_o(io_valid_r_o[i])
    ,.clk_r_o(io_clk_r_o[i]));
  
  end
  

endmodule