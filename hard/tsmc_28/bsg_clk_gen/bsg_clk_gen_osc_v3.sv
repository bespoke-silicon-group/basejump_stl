// bsg_clk_gen_osc
//
// new settings are delivered via bsg_tag_i
//
// the clock is designed to be atomically updated
// between any of its values without glitching.
//
// We have verified this in TSMC 28 by running with sdf annotations.
//

`ifndef BSG_NO_TIMESCALE
`timescale 1ps/1ps
`endif

`include "bsg_clk_gen.svh"

module bsg_clk_gen_osc_v3
 import bsg_tag_pkg::*;
 #(parameter `BSG_INV_PARAM(num_taps_p)
   )
  (input bsg_tag_s bsg_tag_trigger_i
   , input bsg_tag_s bsg_tag_i
   , input async_reset_i
   , output logic clk_o
   );

  localparam ctl_width_lp = `BSG_SAFE_CLOG2(num_taps_p);

  logic trigger_r;
  bsg_tag_client_unsync #(.width_p(1))
   btc_clkgate
    (.bsg_tag_i(bsg_tag_trigger_i)
     ,.data_async_r_o(trigger_r)
     );

  logic [ctl_width_lp-1:0] ctl_r;
  bsg_tag_client_unsync
   #(.width_p(ctl_width_lp))
   btc_ctl
    (.bsg_tag_i(bsg_tag_i)
     ,.data_async_r_o(ctl_r)
     );

  logic [num_taps_p-1:0] ctl_one_hot_lo;
  bsg_decode #(.num_out_p(num_taps_p)) decode
   (.i(ctl_r)
    ,.o(ctl_one_hot_lo)
    );

  bsg_rp_clk_gen_osc_v3 osc_BSG_DONT_TOUCH
   (.async_reset_i(async_reset_i)
     ,.trigger_i(trigger_r)
     ,.ctl_one_hot_i(ctl_one_hot_lo)
     ,.clk_o(clk_o)
     );

endmodule

