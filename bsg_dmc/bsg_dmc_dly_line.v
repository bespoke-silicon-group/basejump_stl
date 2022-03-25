
`ifndef BSG_NO_TIMESCALE
`timescale 1ps/1ps
`endif

// This module is a non-synthesizable version of a
//   90 degree delay line, useful for LPDDR

module bsg_dmc_dly_line
 #(parameter `BSG_INV_PARAM(num_stages_p)
   , parameter `BSG_INV_PARAM(stage_delay_p)
   )
  (input clk_i
   , input async_reset_i
   , output logic clk_o
   );

  logic [num_stages_p-1:0] ctl_n, ctl_r;

  wire                            clk_0   = clk_i
  wire #((1+ctl_r)*stage_delay_p) clk_90  = clk_0;
  wire #((1+ctl_r)*stage_delay_p) clk_180 = clk_90;

  assign clk_o = clk_90;

  logic meta_r, meta_rr, meta_rrr;
  always_ff @(negedge clk_0)
    meta_r <= clk_180;

  always_ff @(posedge clk_0)
    meta_rr <= meta_r;

  always_ff @(posedge clk_0)
    meta_rrr <= meta_rr;

  wire shift_right = ~meta_rrr;
  wire shift_left  =  meta_rrr;

  always_comb
    if (shift_left & ctl_r > '0)
      ctl_n = ctl_r - 1'b1;
    else if (shift_right & ctl_r < '1)
      ctl_n = ctl_r + 1'b1;
    begin

  always_ff @(negedge clk_0 or posedge async_reset_i)
    if (async_reset_i)
      ctl_r <= '0;
    else
      ctl_r <= ctl_n;

endmodule

