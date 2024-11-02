
//
// Paul Gao 02/2021
//
// This is the sender part of bsg_link_sdr, an SDR communication endpoint 
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

module bsg_link_sdr_upstream

 #(parameter `BSG_INV_PARAM(width_p )
  // Receive fifo depth 
  // MUST MATCH paired bsg_link_sdr_downstream setting
  ,parameter lg_fifo_depth_p = 3
  // Token credit decimation
  // MUST MATCH paired bsg_link_sdr_downstream setting
  ,parameter lg_credit_to_token_decimation_p = 0
  ,parameter bypass_twofer_fifo_p = 0
  ,parameter strength_p = 0
  )

  (// Core side
   input                io_clk_i
  ,input                io_link_reset_i
  ,input                async_token_reset_i
  ,input                io_v_i
  ,input  [width_p-1:0] io_data_i
  ,output               io_ready_and_o
  // IO side
  ,output               io_clk_o
  ,output               io_v_o
  ,output [width_p-1:0] io_data_o
  ,input                token_clk_i
  );

  logic osdr_v_li;
  logic [width_p-1:0] osdr_data_li;
  logic osdr_token_lo;

  bsg_link_source_sync_upstream_sync
 #(.width_p                        (width_p)
  ,.lg_fifo_depth_p                (lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ,.bypass_twofer_fifo_p           (bypass_twofer_fifo_p)
  ) sso
  (.io_clk_i           (io_clk_i)
  ,.io_link_reset_i    (io_link_reset_i)
  ,.async_token_reset_i(async_token_reset_i)
  ,.io_v_i             (io_v_i)
  ,.io_data_i          (io_data_i)
  ,.io_ready_and_o     (io_ready_and_o)
  ,.io_v_o             (osdr_v_li)
  ,.io_data_o          (osdr_data_li)
  ,.token_clk_i        (osdr_token_lo)
  );

  // valid and data signals are sent together
  bsg_link_osdr_phy
 #(.width_p(width_p+1)
  ,.strength_p(strength_p)
  ) osdr_phy
  (.clk_i  (io_clk_i)
  ,.reset_i(io_link_reset_i)
  ,.data_i ({osdr_v_li, osdr_data_li})
  ,.clk_o  (io_clk_o)
  ,.data_o ({io_v_o, io_data_o})
  ,.token_i(token_clk_i)
  ,.token_o(osdr_token_lo)
  );

endmodule

`BSG_ABSTRACT_MODULE(bsg_link_sdr_upstream)
