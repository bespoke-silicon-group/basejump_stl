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
  ,input  core_link_reset_i
  // io_reset signals must be synchronous to input clock of each IO channel
  ,input [num_channels_p-1:0] io_link_reset_i
  // Core side
  ,output [width_p-1:0] core_data_o
  ,output               core_valid_o
  ,input                core_yumi_i
  // Physical IO side
  // The clock io_clk_i is being remotely sent from another chip's bsg_link_ddr_upstream
  // in parallel with the source-synchronous data. The receive logic runs off of this clock,
  // so the clock will not start until the upstream link has come out of reset.
  ,input [num_channels_p-1:0]                      io_clk_i
  ,input [num_channels_p-1:0][channel_width_p-1:0] io_data_i
  ,input [num_channels_p-1:0]                      io_valid_i
  ,output logic [num_channels_p-1:0]               core_token_r_o
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
    
    logic io_iddr_v_0, io_iddr_v_1;
    logic [channel_width_p-1:0] io_iddr_data_0, io_iddr_data_1;
    
    // valid and data signals are received together
    
    bsg_link_iddr_phy
   #(.width_p(channel_width_p+1)
    ) iddr_data
    (.clk_i   (io_clk_i[i])
    ,.data_i  ({io_valid_i[i], io_data_i[i]})
    ,.data_r_o({{io_iddr_v_1, io_iddr_data_1},
                {io_iddr_v_0, io_iddr_data_0}})
    );
    
    // Theoretically v0 and v1 should have same value
    // It can go wrong when physical IO channel is unstable or there is a bug
                              
    //synopsys translate_off
    always_ff @ (negedge io_clk_i[i]) 
      begin
      // Do not assert when either one evaluates to X, Z, or both evaluate to 0
      // Also do not assert when reset signal evaluates to X or Z
      if ((io_iddr_v_1 | io_iddr_v_0) & (io_link_reset_i[i] | ~io_link_reset_i[i]))
        assert ((io_iddr_v_1==io_iddr_v_0) | io_link_reset_i[i])
        else
          begin
            $error("BaseJump STL ERROR %m: Received v0=%d and v1=%d do not match.", 
                    io_iddr_v_0, io_iddr_v_1);
          end
      end
    //synopsys translate_on

    bsg_link_source_sync_downstream
   #(.channel_width_p(ddr_width_lp)
    ,.lg_fifo_depth_p(lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ) downstream
    (.core_clk_i       (core_clk_i)
    ,.core_link_reset_i(core_link_reset_i)
    ,.io_link_reset_i  (io_link_reset_i[i])

    // source synchronous input channel; coming from chip edge
    ,.io_clk_i         (io_clk_i[i])
    ,.io_data_i        ({io_iddr_data_1, io_iddr_data_0})
    ,.io_valid_i       (io_iddr_v_1 & io_iddr_v_0) // valid when both v0 and v1 high
    ,.core_token_r_o   (core_token_r_o[i])

    // going into core; uses core clock
    ,.core_data_o      (core_sipo_data_li[i])
    ,.core_valid_o     (core_sipo_valid_li[i])
    ,.core_yumi_i      (core_sipo_yumi_lo)
    );
  
  end

  // This sipof ensures no bubble cycle on receiving packets.
  bsg_serial_in_parallel_out_full
 #(.width_p(ddr_width_lp*num_channels_p)
  ,.els_p  (sipo_ratio_lp)
  ) in_sipof
  (.clk_i  (core_clk_i)
  ,.reset_i(core_link_reset_i)
  ,.v_i    (& core_sipo_valid_li)
  ,.ready_o(core_sipo_ready_lo)
  ,.data_i (core_sipo_data_li)
  ,.data_o (core_data_o)
  ,.v_o    (core_valid_o)
  ,.yumi_i (core_yumi_i)
  );
  
  // synopsys translate_off
  initial 
  begin
    assert (sipo_ratio_lp > 0)
    else 
      begin 
        $error("BaseJump STL ERROR %m: width_p should be larger than or equal to (2*channel_width_p*num_channels_p)");
        $finish;
      end
      
    assert (sipo_ratio_lp*(ddr_width_lp*num_channels_p) == width_p)
    else 
      begin 
        $error("BaseJump STL ERROR %m: width_p should be multiple of (2*channel_width_p*num_channels_p)");
        $finish;
      end
  end
  // synopsys translate_on

endmodule