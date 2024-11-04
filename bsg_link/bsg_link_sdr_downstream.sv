
//
// Paul Gao 02/2021
//
// This is the receiver part of bsg_link_sdr, an SDR communication endpoint 
// over single source-synchronous channel.
//
// Typical usage: Communication between different hierarchical blocks in
// different clock domains on ASIC. In this way the clock trees can be
// fully independent in different hierarchical blocks.
//
//
// General reset procedures:
//
// Step 1: Assert io_link_reset and core_link_reset.
// Step 2: async_token_reset must be posedge/negedge toggled (0->1->0)
//         at least once. token_clk_i cannot toggle during this step.
// Step 3: io_clk_i posedge toggled at least four times after that.
// Step 4: De-assert upstream_io_link_reset to generate io_clk_o.
// Step 5: De-assert downstream_io_link_reset.
// Step 6: De-assert downstream_core_link_reset.
//
// *************************************************************************
//              async         upstream       downstream       downstream
//           token_reset    io_link_reset   io_link_reset   core_link_reset
//  Step 1        0               1               1                1
//  Step 2        1               1               1                1
//  Step 3        0               1               1                1
//  Step 4        0               0               1                1
//  Step 5        0               0               0                1
//  Step 6        0               0               0                0
// *************************************************************************
//

`include "bsg_defines.sv"

module bsg_link_sdr_downstream

 #(parameter `BSG_INV_PARAM(width_p )
  // Receive fifo depth 
  // MUST MATCH paired bsg_link_ddr_upstream setting
  ,parameter lg_fifo_depth_p = 3
  // Token credit decimation
  // MUST MATCH paired bsg_link_ddr_upstream setting
  ,parameter lg_credit_to_token_decimation_p = 0
  ,parameter bypass_twofer_fifo_p = 0
  )

  (// Core side
   input                core_clk_i
  ,input                core_link_reset_i
  ,output               core_v_o
  ,output [width_p-1:0] core_data_o
  ,input                core_yumi_i
  // IO side
  ,input                async_io_link_reset_i
  ,input                io_clk_i
  ,input                io_v_i
  ,input  [width_p-1:0] io_data_i
  ,output               core_token_r_o
  );

  logic isdr_clk_lo, isdr_v_lo;
  logic [width_p-1:0] isdr_data_lo;
  logic isdr_token_li;

  // valid and data signals are received together
  bsg_link_isdr_phy
 #(.width_p(width_p+1)
  ) isdr_phy
  (.clk_i  (io_clk_i)
  ,.clk_o  (isdr_clk_lo)
  ,.data_i ({io_v_i, io_data_i})
  ,.data_o ({isdr_v_lo, isdr_data_lo})
  ,.token_i(isdr_token_li)
  ,.token_o(core_token_r_o)
  );

  logic io_link_reset_sync;
  bsg_sync_sync #(.width_p(1)) bss
  (.oclk_i     (isdr_clk_lo          )
  ,.iclk_data_i(async_io_link_reset_i)
  ,.oclk_data_o(io_link_reset_sync   )
  );

  bsg_link_source_sync_downstream
 #(.channel_width_p(width_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ,.bypass_twofer_fifo_p(bypass_twofer_fifo_p)
  ) downstream
  (.core_clk_i       (core_clk_i)
  ,.core_link_reset_i(core_link_reset_i)
  ,.io_link_reset_i  (io_link_reset_sync)
  // source synchronous input channel
  ,.io_clk_i         (isdr_clk_lo)
  ,.io_data_i        (isdr_data_lo)
  ,.io_valid_i       (isdr_v_lo)
  ,.core_token_r_o   (isdr_token_li)
  // going into core
  ,.core_data_o      (core_data_o)
  ,.core_valid_o     (core_v_o)
  ,.core_yumi_i      (core_yumi_i)
  );

endmodule

`BSG_ABSTRACT_MODULE(bsg_link_sdr_downstream)
