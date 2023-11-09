
//
// Paul Gao 02/2021
//
// SDR communication endpoint over single source-synchronous channel.
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

module bsg_link_sdr

 #(parameter `BSG_INV_PARAM(width_p                         )
  ,parameter `BSG_INV_PARAM(lg_fifo_depth_p                 )
  ,parameter `BSG_INV_PARAM(lg_credit_to_token_decimation_p )
  ,parameter bypass_upstream_twofer_fifo_p   = 0
  ,parameter bypass_downstream_twofer_fifo_p = 1
  ,parameter strength_p                      = 0
  )

  (  input core_clk_i
   , input core_uplink_reset_i
   , input core_downstream_reset_i
   , input async_downlink_reset_i
   , input async_token_reset_i

   , input                 core_v_i
   , input  [width_p-1:0]  core_data_i
   , output                core_ready_o

   , output                core_v_o
   , output [width_p-1:0]  core_data_o
   , input                 core_yumi_i

   , output                link_clk_o
   , output [width_p-1:0]  link_data_o
   , output                link_v_o
   , input                 link_token_i

   , input                 link_clk_i
   , input  [width_p-1:0]  link_data_i
   , input                 link_v_i
   , output                link_token_o
   );

  bsg_link_sdr_upstream
 #(.width_p                        (width_p)
  ,.lg_fifo_depth_p                (lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ,.bypass_twofer_fifo_p           (bypass_upstream_twofer_fifo_p)
  ,.strength_p                     (strength_p)
  ) uplink
  (// Core side
   .io_clk_i           (core_clk_i)
  ,.io_link_reset_i    (core_uplink_reset_i)
  ,.async_token_reset_i(async_token_reset_i)
  ,.io_data_i          (core_data_i)
  ,.io_v_i             (core_v_i)
  ,.io_ready_and_o     (core_ready_o)
  // IO side
  ,.io_clk_o           (link_clk_o)
  ,.io_data_o          (link_data_o)
  ,.io_v_o             (link_v_o)
  ,.token_clk_i        (link_token_i)
  );

  bsg_link_sdr_downstream
 #(.width_p                        (width_p)
  ,.lg_fifo_depth_p                (lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ,.bypass_twofer_fifo_p           (bypass_downstream_twofer_fifo_p)
  ) downlink
  (// Core side
   .core_clk_i           (core_clk_i)
  ,.core_link_reset_i    (core_downstream_reset_i)
  ,.core_data_o          (core_data_o)
  ,.core_v_o             (core_v_o)
  ,.core_yumi_i          (core_yumi_i)
  // IO side
  ,.async_io_link_reset_i(async_downlink_reset_i)
  ,.io_clk_i             (link_clk_i)
  ,.io_data_i            (link_data_i)
  ,.io_v_i               (link_v_i)
  ,.core_token_r_o       (link_token_o)
  );

endmodule

`BSG_ABSTRACT_MODULE(bsg_link_sdr)
