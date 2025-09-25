//
// Paul Gao 03/2019
//
// This is the receiver part of bsg_link_ddr, a complete DDR communication 
// endpoint over multiple source-synchronous channels.
//
// * This module MUST be mirrored with bsg_link_ddr_upstream, which is
//   instantiated on the source chip or FPGA. It is not a must to
//   use upstream and downstream in pair on same chip or FPGA.
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
// When channel_width_p is large, it might be hard to properly align source synchronous
// clock to all data wires. One option is to cut the channel in half and align to
// different clocks. Ecoding method below helps represent valid bit for bottom half data
// without adding an extra wire.
// +-------------+---------------+---------------------+
// |    v_top    |     bottom    |        Value        |
// | 0_0???_???? |   0000_0000   | no data (""comma"") |
// | 1_XXXX_XXXX |  YYYY_YYYY!=0 | XXXX_XXXX_YYYY_YYYY |
// | 0_1XXX_XXXX |   X000_0001   | XXXX_XXXX_0000_0000 |
// +-------------+---------------+---------------------+
// Physical bonding suggestion: Regard v bit and top bits of the channel as a group
// Regard bottom bits of the channel as another group
//
// THIS MODULE MUST MATCH paired bsg_link_ddr_upstream with use_encode_p=1

`include "bsg_defines.sv"

module bsg_link_ddr_downstream_encode

 #(// Core data width
  // MUST be multiple of (2*channel_width_p*num_channels_p)
  // When use_extra_data_bit_p=1, must be multiple of ((2*channel_width_p+1)*num_channels_p) 
   parameter `BSG_INV_PARAM(width_p         )
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
  // There are (channel_width_p+1) physical wires available (1 wire for valid bit)
  // With DDR clock, we can handle 2*channel_width_p+2 bits each cycle
  // By default the link has 2*channel_width_p data bits and 1 valid bit, 1 bit is unused
  // Set use_extra_data_bit_p=1 to utilize this extra bit
  // MUST MATCH paired bsg_link_ddr_upstream setting
  ,parameter use_extra_data_bit_p = 0
  ,localparam ddr_width_lp  = channel_width_p*2 + use_extra_data_bit_p
  ,localparam sipo_ratio_lp = width_p/(ddr_width_lp*num_channels_p)
  ,localparam phy_width_lp  = channel_width_p+1
  )

  (// All reset / control signals are synchronous to core_clk
   input  core_clk_i
  ,input  core_link_reset_i
  // io_reset signals must be synchronous to input clock of each IO channel
  // Dual reset ports for dual input clocks
  ,input [num_channels_p-1:0][1:0] io_link_reset_i
  // Core side
  ,output [width_p-1:0] core_data_o
  ,output               core_valid_o
  ,input                core_yumi_i
  // Physical IO side
  // The clock io_clk_i is being remotely sent from another chip's bsg_link_ddr_upstream
  // in parallel with the source-synchronous data. The receive logic runs off of this clock,
  // so the clock will not start until the upstream link has come out of reset.
  // Dual input clocks for each channel
  ,input [num_channels_p-1:0][1:0]                 io_clk_i
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
    
    // io side signals
    logic [1:0] io_iddr_valid_lo;
    logic [1:0][channel_width_p/2+1-1:0] io_iddr_data_hi; // v + high bits
    logic [1:0][channel_width_p/2+0-1:0] io_iddr_data_lo; // low bits
    
    // core side signals
    logic [1:0] core_ss_valid_lo;
    logic core_ss_yumi_li, core_ss_data_nonzero;
    logic [1:0][channel_width_p/2+1-1:0] core_ss_data_hi;
    logic [1:0][channel_width_p/2+0-1:0] core_ss_data_lo;
    
    // connect to sipo
    assign core_ss_yumi_li = core_sipo_yumi_lo;
    assign core_sipo_valid_li[i] = & core_ss_valid_lo;
    assign core_sipo_data_li[i][ddr_width_lp-1:channel_width_p] = {core_ss_data_hi[1], core_ss_data_lo[1]};
    
    // channel decode
    // non-synthesizable X-pessimism prevention logic, for testbench only
    assign core_ss_data_nonzero = core_ss_data_hi[0][channel_width_p/2];
    assign core_sipo_data_li[i][channel_width_p-1:channel_width_p/2] = 
        (core_ss_data_nonzero === 1'b1)?
          {core_ss_data_hi[0]}
        : (core_ss_data_nonzero === 1'b0)?
          {core_ss_data_lo[0][channel_width_p/2-1], core_ss_data_hi[0][channel_width_p/2-1-1:0]}
          : {'X};
    assign core_sipo_data_li[i][channel_width_p/2-1:0] = 
        (core_ss_data_nonzero === 1'b1)?
          {core_ss_data_lo[0]}
        : (core_ss_data_nonzero === 1'b0)?
          {'0}
          : {'X};
    // io side decode
    // non-synthesizable X-pessimism prevention logic, for testbench only
    assign io_iddr_valid_lo[1] = ~(io_iddr_data_hi[0][channel_width_p/2-1+:2] === '0);
    assign io_iddr_valid_lo[0] = ~(io_iddr_data_lo[0] === '0);

    // valid and data signals are received together
    bsg_link_iddr_phy
   #(.width_p(channel_width_p/2+1)
    ) iddr_data_hi
    (.clk_i   (io_clk_i[i][1])
    ,.data_i  ({io_valid_i[i], io_data_i[i][channel_width_p-1:channel_width_p/2]})
    ,.data_r_o(io_iddr_data_hi)
    );

    bsg_link_iddr_phy
   #(.width_p(channel_width_p/2)
    ) iddr_data_lo
    (.clk_i   (io_clk_i[i][0])
    ,.data_i  ({io_data_i[i][channel_width_p/2-1:0]})
    ,.data_r_o(io_iddr_data_lo)
    );

    bsg_link_source_sync_downstream
   #(.channel_width_p(channel_width_p+2)
    ,.lg_fifo_depth_p(lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ) downstream_top
    (.core_clk_i       (core_clk_i)
    ,.core_link_reset_i(core_link_reset_i)
    ,.io_link_reset_i  (io_link_reset_i[i][1])

    // source synchronous input channel; coming from chip edge
    ,.io_clk_i         (io_clk_i[i][1])
    ,.io_data_i        (io_iddr_data_hi)
    ,.io_valid_i       (io_iddr_valid_lo[1])
    ,.core_token_r_o   (core_token_r_o[i])

    // going into core; uses core clock
    ,.core_data_o      (core_ss_data_hi)
    ,.core_valid_o     (core_ss_valid_lo[1])
    ,.core_yumi_i      (core_ss_yumi_li)
    );

    bsg_link_source_sync_downstream
   #(.channel_width_p(channel_width_p)
    ,.lg_fifo_depth_p(lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ) downstream_bot
    (.core_clk_i       (core_clk_i)
    ,.core_link_reset_i(core_link_reset_i)
    ,.io_link_reset_i  (io_link_reset_i[i][0])

    // source synchronous input channel; coming from chip edge
    ,.io_clk_i         (io_clk_i[i][0])
    ,.io_data_i        (io_iddr_data_lo)
    ,.io_valid_i       (io_iddr_valid_lo[0])
    ,.core_token_r_o   ()

    // going into core; uses core clock
    ,.core_data_o      (core_ss_data_lo)
    ,.core_valid_o     (core_ss_valid_lo[0])
    ,.core_yumi_i      (core_ss_yumi_li)
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
  ,.ready_and_o(core_sipo_ready_lo)
  ,.data_i (core_sipo_data_li)
  ,.data_o (core_data_o)
  ,.v_o    (core_valid_o)
  ,.yumi_i (core_yumi_i)
  );
  
`ifndef BSG_HIDE_FROM_SYNTHESIS
  initial 
  begin
    assert (sipo_ratio_lp > 0)
    else 
      begin 
        $error("BaseJump STL ERROR %m: width_p should be larger than or equal to (ddr_width_lp*num_channels_p)");
        $finish;
      end
      
    assert (sipo_ratio_lp*(ddr_width_lp*num_channels_p) == width_p)
    else 
      begin 
        $error("BaseJump STL ERROR %m: width_p should be multiple of (ddr_width_lp*num_channels_p)");
        $finish;
      end
  end
`endif

endmodule
`BSG_ABSTRACT_MODULE(bsg_link_ddr_downstream_encode)
