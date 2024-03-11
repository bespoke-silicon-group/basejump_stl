
`ifndef BSG_NO_TIMESCALE
`timescale 1ps/1ps
`endif

// This module is a behavioral model of the DMC delay line,
// which provides adaptive 90 degree phase shift to an input clock
// as required by LPDDR1, for example. 
// A TSMC 28nm hardened implementation of this module
// can be found at:
//
//      basejump_stl/hard/tsmc_28/bsg_dmc/bsg_dmc_dly_line_v3.sv
//
// This module should be replaced by the hardened version
// when being synthesized.

`include "bsg_defines.sv"

module bsg_dmc_dly_line_v3
 #(parameter `BSG_INV_PARAM(num_taps_p)
   )
  (input clk_i
   , input async_reset_i
   , output logic clk_o
   );

`ifdef BSG_OSC_GRANULARITY
  localparam osc_granularity_lp = `BSG_OSC_GRANULARITY;
`else
  localparam osc_granularity_lp = 100;
`endif

  logic [num_taps_p-1:0] ctl_n, ctl_r;
  logic clk_0, clk_90, clk_180;

  assign #((1        )*osc_granularity_lp) clk_0   = clk_i;
  assign #((1+1*ctl_r)*osc_granularity_lp) clk_90  = clk_0;
  assign #((1+1*ctl_r)*osc_granularity_lp) clk_180 = clk_90;

  wire #(10) test = clk_i;

  assign clk_o = clk_90;

  logic meta_r, meta_rr, meta_rrr;
  always_ff @(negedge clk_0)
    meta_r <= clk_180;

  always_ff @(posedge clk_0)
    meta_rr <= meta_r;

  always_ff @(posedge clk_0)
    meta_rrr <= meta_rr;

  logic [1:0] state_n, state_r;
  wire is_trig_off = (state_r == 2'b00);
  wire is_count    = (state_r == 2'b01);
  wire is_pause    = (state_r == 2'b10);
  wire is_trig_on  = (state_r == 2'b11);

  always_ff @(posedge clk_0 or posedge async_reset_i)
    if (async_reset_i)
      state_r <= '0;
    else
      state_r <= state_r + 1'b1;

  wire shift_right =  meta_rrr & is_trig_on;
  wire shift_left  = ~meta_rrr & is_trig_on;

  always_ff @(negedge clk_0 or posedge async_reset_i)
    if (async_reset_i)
      ctl_r <= '0;
    else 
    if (shift_left & ctl_r > '0)
      ctl_r <= ctl_r - 1'b1;
    else if (shift_right & ctl_r < '1)
      ctl_r <= ctl_r + 1'b1;

endmodule

`BSG_ABSTRACT_MODULE(bsg_dmc_dly_line_v3)

