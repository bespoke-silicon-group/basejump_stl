//
// Paul Gao 03/2019
//
// This is the sender part of bsg_link_ddr, a complete DDR communication 
// endpoint over multiple source-synchronous channels.
// ALWAYS use in pair with bsg_link_ddr_downstream
// 
// The purpose of bsg_link_ddr_upstream is to receive data packets from ready-valid
// interface in core clock domain, serialize them to fit in IO channels (optional),
// then send out through physical IO pins.
// Token-credit based flow control ensures efficiency and correctness.
// ODDR PHY sends out packets with center-aligned DDR clock.
//
// Typical usage: ASIC <-> ASIC communication and ASIC <-> FPGA communication.
// Instantiate one bsg_link_ddr_upstream on sender side, one bsg_link_ddr_downstream on
// receiver side to establish communication.
// 
// Refer to bsg_link_source_sync_upstream for more information on flow control
//
//

module bsg_link_ddr_upstream

 #(// Core data width
  // MUST be multiple of (2*channel_width_p*num_channels_p) 
   parameter width_p         = "inv"
  // Number of IO pins per physical IO channels
  ,parameter channel_width_p = 8
  // Number of physical IO channels
  ,parameter num_channels_p  = 1
  // Receive fifo depth 
  // MUST MATCH paired bsg_link_ddr_downstream setting
  // Default value comes from child module
  // Refer to bsg_link_source_sync_downstream for more detail on this parameter
  ,parameter lg_fifo_depth_p = 6
  // Token credit decimation
  // MUST MATCH paired bsg_link_ddr_downstream setting
  // Default value comes from child module
  // Refer to bsg_link_source_sync_downstream for more detail on this parameter
  ,parameter lg_credit_to_token_decimation_p = 3
  ,localparam ddr_width_lp = channel_width_p*2
  ,localparam piso_ratio_lp = width_p/(ddr_width_lp*num_channels_p)
  )

  (// Core side
   input core_clk_i
  // Reset procedure:
  // (1) assert core_reset, link_reset, deassert link_enable
  // (2) deassert link_reset
  // (3) assert link_enable
  // (4) deassert core_reset
  // (5) deassert reset on other part of the chip
  // All reset / control signals are synchronous to core_clk
  ,input core_reset_i
  ,input core_link_reset_i
  ,input core_link_enable_i

  ,input [width_p-1:0] core_data_i
  ,input               core_valid_i
  ,output              core_ready_o  
  
  // Physical IO side
  ,input io_master_clk_i
  
  ,output logic [num_channels_p-1:0]                      io_clk_r_o
  ,output logic [num_channels_p-1:0][channel_width_p-1:0] io_data_r_o
  ,output logic [num_channels_p-1:0]                      io_valid_r_o
  ,input        [num_channels_p-1:0]                      token_clk_i
  );
  
  
  logic core_piso_valid_lo, core_piso_yumi_li;
  logic [num_channels_p-1:0][ddr_width_lp-1:0] core_piso_data_lo;
  
  // Dequeue from PISO when all channels are ready
  logic [num_channels_p-1:0] core_piso_ready_li;
  assign core_piso_yumi_li = (& core_piso_ready_li) & core_piso_valid_lo;
  
  
  // When parallel in serial out ratio equal to 1, use fifo.
  if (piso_ratio_lp == 1) 
  begin: fifo
  
    bsg_two_fifo
   #(.width_p(width_p)
    ) out_fifo
    (.clk_i  (core_clk_i)
    ,.reset_i(core_reset_i)
    ,.ready_o(core_ready_o)
    ,.data_i (core_data_i)
    ,.v_i    (core_valid_i)
    ,.v_o    (core_piso_valid_lo)
    ,.data_o (core_piso_data_lo)
    ,.yumi_i (core_piso_yumi_li)
    );
  
  end 
  // When parallel in serial out ratio larger than 1, serialize it.
  else 
  begin: piso
  
    bsg_parallel_in_serial_out 
   #(.width_p(ddr_width_lp*num_channels_p)
    ,.els_p  (piso_ratio_lp)
    ) out_piso
    (.clk_i  (core_clk_i)
    ,.reset_i(core_reset_i)
    ,.valid_i(core_valid_i)
    ,.data_i (core_data_i)
    ,.ready_o(core_ready_o)
    ,.valid_o(core_piso_valid_lo)
    ,.data_o (core_piso_data_lo)
    ,.yumi_i (core_piso_yumi_li)
    );
  
  end
  
  genvar i;
  
  // multiple channels
  for (i = 0; i < num_channels_p; i++) 
  begin: ch
  
    logic io_ssup_valid_lo, io_ssup_ready_li;
    logic [1:0][channel_width_p-1:0] io_ssup_data_lo;
    
    // reset signal for ODDR PHY
    logic io_link_reset_lo;

    bsg_link_source_sync_upstream
   #(.channel_width_p(ddr_width_lp)
    ,.lg_fifo_depth_p(lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ) sso
    (// control signals  
     .core_clk_i        (core_clk_i)
    ,.core_link_reset_i (core_link_reset_i)
    ,.core_link_enable_i(core_link_enable_i)
    
    ,.io_master_clk_i   (io_master_clk_i)
    ,.io_reset_o        (io_link_reset_lo)

    // Input from chip core
    ,.core_data_i       (core_piso_data_lo[i])
    ,.core_valid_i      (core_piso_yumi_li)
    ,.core_ready_o      (core_piso_ready_li[i])

    // source synchronous output channel; going to chip edge
    ,.io_data_o         (io_ssup_data_lo)
    ,.io_valid_o        (io_ssup_valid_lo)
    ,.io_ready_i        (io_ssup_ready_li)
    ,.token_clk_i       (token_clk_i[i])
    );
    
    
    logic [1:0][channel_width_p+1-1:0] io_oddr_data_li;
    logic [channel_width_p+1-1:0]      io_oddr_data_lo;
    
    // Output data packet should be in packed format: {{v1, data1}, {v0, data0}}
    // Need to assemble DDR data packet
    assign io_oddr_data_li[0][channel_width_p-1:0] = io_ssup_data_lo[0];
    assign io_oddr_data_li[1][channel_width_p-1:0] = io_ssup_data_lo[1];
    
    // Copy same valid bit to both v0 and v1
    assign io_oddr_data_li[0][channel_width_p] = io_ssup_valid_lo;
    assign io_oddr_data_li[1][channel_width_p] = io_ssup_valid_lo;
    
    bsg_link_oddr_phy
   #(.width_p(channel_width_p+1)
    ) oddr_phy
    (.reset_i (io_link_reset_lo)
    ,.clk_i   (io_master_clk_i)
    ,.data_i  (io_oddr_data_li)
    ,.ready_o (io_ssup_ready_li)
    ,.data_r_o(io_oddr_data_lo)
    ,.clk_r_o (io_clk_r_o[i])
    );
    
    // valid and data signals are sent together
    assign io_data_r_o[i]  = io_oddr_data_lo[channel_width_p-1:0];
    assign io_valid_r_o[i] = io_oddr_data_lo[channel_width_p];
  
  end
  
  
  // synopsys translate_off
  initial 
  begin
    assert (piso_ratio_lp > 0)
    else 
      begin 
        $error("width_p should be larger than or equal to (2*channel_width_p*num_channels_p)");
        $finish;
      end
      
    assert (piso_ratio_lp*(ddr_width_lp*num_channels_p) == width_p)
    else 
      begin 
        $error("width_p should be multiple of (2*channel_width_p*num_channels_p)");
        $finish;
      end
  end
  // synopsys translate_on

endmodule