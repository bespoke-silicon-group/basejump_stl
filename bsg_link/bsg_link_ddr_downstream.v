//
// Paul Gao 03/2019
//
// This is the receiver part of bsg_link_ddr, a complete DDR communication 
// endpoint over multiple source-synchronous channels.
// ALWAYS use in pair with bsg_link_ddr_upstream
// 
// The purpose of bsg_link_ddr_downstream is to receive DDR data bits from 
// physical IO pins, then reassemble to ready-valid interface in core clock domain.
// Token-credit based flow control ensures efficiency and correctness.
// IDDR_PHY assumes incoming clock is center-alighed to data bits.
//
// Typical usage: ASIC <-> ASIC communication and ASIC <-> FPGA communication.
// Instantiate one bsg_link_ddr_upstream on sender side, one bsg_link_ddr_downstream on
// receiver side to establish communication.
//
// Refer to bsg_link_source_sync_downstream for more information on flow control
//
//

module bsg_link_ddr_downstream

 #(// Core data width
  // MUST be multiple of (2*channel_width_p*num_channels_p) 
   parameter width_p         = "inv"
  // Number of IO pins per physical IO channels
  ,parameter channel_width_p = 8
  // Number of physical IO channels
  ,parameter num_channels_p  = 1
  // Receive fifo depth 
  // MUST MATCH paired bsg_link_ddr_upstream setting
  // Default value comes from child module
  // Refer to bsg_link_source_sync_downstream for more detail on this parameter
  ,parameter lg_fifo_depth_p = 6
  // Token credit decimation
  // MUST MATCH paired bsg_link_ddr_upstream setting
  // Default value comes from child module
  // Refer to bsg_link_source_sync_downstream for more detail on this parameter
  ,parameter lg_credit_to_token_decimation_p = 3
  ,localparam ddr_width_lp = channel_width_p*2
  ,localparam sipo_ratio_lp = width_p/(ddr_width_lp*num_channels_p)
  )

  (// All reset / control signals are synchronous to core_clk
   input  core_clk_i
  ,input  core_reset_i
  ,input  core_link_reset_i
  // Core side
  ,output [width_p-1:0] core_data_o
  ,output               core_valid_o
  ,input                core_yumi_i
  // Physical IO side
  ,input [num_channels_p-1:0]                      io_clk_i
  ,input [num_channels_p-1:0][channel_width_p-1:0] io_data_i
  ,input [num_channels_p-1:0]                      io_valid_i
  ,output logic [num_channels_p-1:0]               io_token_r_o
  );
  
  
  logic core_sipo_ready_lo, core_sipo_yumi_lo;
  logic [num_channels_p-1:0][ddr_width_lp-1:0] core_sipo_data_li;
  
  // Dequeue when all channels have valid data coming in
  logic [num_channels_p-1:0] core_sipo_valid_li;
  assign core_sipo_yumi_lo = (& core_sipo_valid_li) & core_sipo_ready_lo;
  
  genvar i;
  
  // Multiple channels
  for (i = 0; i < num_channels_p; i++) 
  begin:ch
    
    logic [channel_width_p+1-1:0]      io_iddr_data_li;
    logic [1:0][channel_width_p+1-1:0] io_iddr_data_lo;
    
    // valid and data signals are received together
    assign io_iddr_data_li = {io_valid_i[i], io_data_i[i]};

    bsg_link_iddr_phy
   #(.width_p(channel_width_p+1)
    ) iddr_data
    (.clk_i (io_clk_i[i])
    ,.data_i(io_iddr_data_li)
    ,.data_o(io_iddr_data_lo)
    );
    
    logic                            io_ssdown_valid_li;
    logic [1:0][channel_width_p-1:0] io_ssdown_data_li;
    
    // Received data packet is in packed format: {{v1, data1}, {v0, data0}}
    // Need to reassemble DDR data packet
    assign io_ssdown_data_li[0] = io_iddr_data_lo[0][channel_width_p-1:0];
    assign io_ssdown_data_li[1] = io_iddr_data_lo[1][channel_width_p-1:0];
    
    // Valid when both v0 and v1 are 1'b1
    // Theoretically this is always true, but can go wrong when IO channel is unstable
    assign io_ssdown_valid_li = io_iddr_data_lo[0][channel_width_p] 
                              & io_iddr_data_lo[1][channel_width_p];

    bsg_link_source_sync_downstream
   #(.channel_width_p(ddr_width_lp)
    ,.lg_fifo_depth_p(lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ) downstream
    (.core_clk_i       (core_clk_i)
    ,.core_link_reset_i(core_link_reset_i)

    // source synchronous input channel; coming from chip edge
    ,.io_clk_i         (io_clk_i[i])
    ,.io_data_i        (io_ssdown_data_li)
    ,.io_valid_i       (io_ssdown_valid_li)
    ,.io_token_r_o     (io_token_r_o[i])

    // going into core; uses core clock
    ,.core_data_o      (core_sipo_data_li[i])
    ,.core_valid_o     (core_sipo_valid_li[i])
    ,.core_yumi_i      (core_sipo_yumi_lo)
    );
  
  end
  
  
  // When serial in parallel out ratio equals to 1, no conversion needed, use fifo.
  if (sipo_ratio_lp == 1) 
  begin: fifo
  
    bsg_two_fifo
   #(.width_p(width_p)
    ) in_fifo
    (.clk_i  (core_clk_i)
    ,.reset_i(core_reset_i)
    ,.ready_o(core_sipo_ready_lo)
    ,.data_i (core_sipo_data_li)
    ,.v_i    (& core_sipo_valid_li)
    ,.v_o    (core_valid_o)
    ,.data_o (core_data_o)
    ,.yumi_i (core_yumi_i)
    );
    
  end 
  // When serial in parallel out ratio larger than 1, deserialize it.
  // This sipof ensures no bubble cycle on receiving packets.
  else 
  begin: sipof
  
    bsg_serial_in_parallel_out_full
   #(.width_p(ddr_width_lp*num_channels_p)
    ,.els_p  (sipo_ratio_lp)
    ) in_sipof
    (.clk_i  (core_clk_i)
    ,.reset_i(core_reset_i)
    ,.v_i    (& core_sipo_valid_li)
    ,.ready_o(core_sipo_ready_lo)
    ,.data_i (core_sipo_data_li)
    ,.data_o (core_data_o)
    ,.v_o    (core_valid_o)
    ,.yumi_i (core_yumi_i)
    );  
  
  end
  

  // synopsys translate_off
  initial 
  begin
    assert (sipo_ratio_lp > 0)
    else 
      begin 
        $error("width_p should be larger than or equal to (2*channel_width_p*num_channels_p)");
        $finish;
      end
      
    assert (sipo_ratio_lp*(ddr_width_lp*num_channels_p) == width_p)
    else 
      begin 
        $error("width_p should be multiple of (2*channel_width_p*num_channels_p)");
        $finish;
      end
  end
  // synopsys translate_on

endmodule