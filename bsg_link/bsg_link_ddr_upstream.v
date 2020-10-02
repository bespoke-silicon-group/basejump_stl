//
// Paul Gao 03/2019
//
// This is the sender part of bsg_link_ddr, a complete DDR communication 
// endpoint over multiple source-synchronous channels.
//
// * This module MUST be mirrored with bsg_link_ddr_downstream, which is
//   instantiated on the destination chip or FPGA. It is not a must to
//   use upstream and downstream in pair on same chip or FPGA.
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
// Reset procedures:
// Step 1: Assert io_link_reset_i and core_link_reset_i.
// Step 2: async_token_reset_i must be posedge/negedge toggled (0->1->0) 
//         at least once. token_clk_i cannot toggle during this step.
// Step 3: io_clk_i posedge toggled at least four times after that.
// Step 4: Deassert io_link_reset_i. 
// Step 5: Deassert core_link_reset_i. 
//

`include "bsg_defines.v"

module bsg_link_ddr_upstream

 #(// Core data width
  // MUST be multiple of (2*channel_width_p*num_channels_p) 
  // When use_extra_data_bit_p=1, must be multiple of ((2*channel_width_p+1)*num_channels_p) 
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
  // There are (channel_width_p+1) physical wires available (1 wire for valid bit)
  // With DDR clock, we can handle 2*channel_width_p+2 bits each cycle
  // By default the link has 2*channel_width_p data bits and 1 valid bit, 1 bit is unused
  // Set use_extra_data_bit_p=1 to utilize this extra bit
  // MUST MATCH paired bsg_link_ddr_downstream setting
  ,parameter use_extra_data_bit_p = 0
  ,localparam ddr_width_lp  = channel_width_p*2 + use_extra_data_bit_p
  ,localparam piso_ratio_lp = width_p/(ddr_width_lp*num_channels_p)
  )

  (// Core side
   input core_clk_i
  ,input core_link_reset_i

  ,input [width_p-1:0] core_data_i
  ,input               core_valid_i
  ,output              core_ready_o  
  
  // Physical IO side
  ,input io_clk_i
  ,input io_link_reset_i
  ,input async_token_reset_i
  
  ,output logic [num_channels_p-1:0]                      io_clk_r_o
  ,output logic [num_channels_p-1:0][channel_width_p-1:0] io_data_r_o
  ,output logic [num_channels_p-1:0]                      io_valid_r_o
  ,input        [num_channels_p-1:0]                      token_clk_i
  );
  
  
  logic core_piso_valid_lo, core_piso_yumi_li;
  logic [num_channels_p-1:0][ddr_width_lp-1:0] core_piso_data_lo;

  bsg_parallel_in_serial_out 
 #(.width_p(ddr_width_lp*num_channels_p)
  ,.els_p  (piso_ratio_lp)
  ) out_piso
  (.clk_i  (core_clk_i)
  ,.reset_i(core_link_reset_i)
  ,.valid_i(core_valid_i)
  ,.data_i (core_data_i)
  ,.ready_and_o(core_ready_o)
  ,.valid_o(core_piso_valid_lo)
  ,.data_o (core_piso_data_lo)
  ,.yumi_i (core_piso_yumi_li)
  );
  
  // Dequeue from PISO when all channels are ready
  logic [num_channels_p-1:0] core_piso_ready_li;
  assign core_piso_yumi_li = (& core_piso_ready_li) & core_piso_valid_lo;
  
  genvar i;
  
  // multiple channels
  for (i = 0; i < num_channels_p; i++) 
  begin: ch
    
    logic io_oddr_valid_li, io_oddr_ready_lo;
    // data_bottom width is fixed
    logic [channel_width_p-1:0] io_oddr_data_bottom;
    // data_top width is determined by use_extra_data_bit_p setting
    logic [ddr_width_lp-1:channel_width_p] io_oddr_data_top;

    bsg_link_source_sync_upstream
   #(.channel_width_p(ddr_width_lp)
    ,.lg_fifo_depth_p(lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ) sso
    (// control signals  
     .core_clk_i            (core_clk_i)
    ,.core_link_reset_i     (core_link_reset_i)    
    ,.io_clk_i              (io_clk_i)
    ,.io_link_reset_i       (io_link_reset_i)
    ,.async_token_reset_i   (async_token_reset_i)

    // Input from chip core
    ,.core_data_i           (core_piso_data_lo[i])
    ,.core_valid_i          (core_piso_yumi_li)
    ,.core_ready_o          (core_piso_ready_li[i])

    // source synchronous output channel; going to chip edge
    ,.io_data_o             ({io_oddr_data_top, io_oddr_data_bottom})
    ,.io_valid_o            (io_oddr_valid_li)
    ,.io_ready_i            (io_oddr_ready_lo)
    ,.token_clk_i           (token_clk_i[i])
    );
    
    // valid and data signals are sent together
    bsg_link_oddr_phy
   #(.width_p(channel_width_p+1)
    ) oddr_phy
    (.reset_i (io_link_reset_i)
    ,.clk_i   (io_clk_i)
    ,.data_i  ({{(channel_width_p+1)'(io_oddr_data_top)},
                {io_oddr_valid_li, io_oddr_data_bottom}}) // valid sent out in first cycle
    ,.ready_o (io_oddr_ready_lo)
    ,.data_r_o({io_valid_r_o[i], io_data_r_o[i]})
    ,.clk_r_o (io_clk_r_o[i])
    );
  
  end
  
  // synopsys translate_off
  initial 
  begin
    assert (piso_ratio_lp > 0)
    else 
      begin 
        $error("BaseJump STL ERROR %m: width_p should be larger than or equal to (ddr_width_lp*num_channels_p)");
        $finish;
      end
      
    assert (piso_ratio_lp*(ddr_width_lp*num_channels_p) == width_p)
    else 
      begin 
        $error("BaseJump STL ERROR %m: width_p should be multiple of (ddr_width_lp*num_channels_p)");
        $finish;
      end
  end
  // synopsys translate_on

endmodule