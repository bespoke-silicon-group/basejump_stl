`include "bsg_defines.v"

`ifndef BSG_NO_TIMESCALE
`timescale 1ps/1ps
`endif

// This module is a behavioral model of the delay line.
// A TSMC 40nm hardened implementation of this module
// can be found at:
//
//  basejump_stl/hard/tsmc_40/bsg_clk_gen/bsg_dly_line.v
//
// This module should be replaced by the hardened version
// when being synthesized.

`include "bsg_clk_gen.vh"

module bsg_dly_line
  import bsg_tag_pkg::bsg_tag_s;

    #(parameter num_adgs_p=1)
  (
   input async_reset_i
   ,input bsg_tag_s bsg_tag_i
   ,input bsg_tag_s bsg_tag_trigger_i
   ,input clk_i
   ,output logic clk_o
   );

`ifdef BSG_OSC_BASE_DELAY
   localparam osc_base_delay_lp = `BSG_OSC_BASE_DELAY;
`else
   localparam osc_base_delay_lp = 1000;
`endif

`ifdef BSG_OSC_GRANULARITY
   localparam osc_granularity_lp = `BSG_OSC_GRANULARITY;
`else
   localparam osc_granularity_lp = 100;
`endif

   `declare_bsg_clk_gen_osc_tag_payload_s(num_adgs_p)

   bsg_clk_gen_osc_tag_payload_s fb_tag_r;
   wire  fb_we_r;

   // note: delay line has to be already working in order
   // for configuration state to pass through here

   bsg_tag_client_unsync
     #(.width_p($bits(bsg_clk_gen_osc_tag_payload_s))
       ,.harden_p(1)
       ) btc
       (.bsg_tag_i(bsg_tag_i)
        ,.data_async_r_o(fb_tag_r)
        );

   bsg_tag_client_unsync
     #(.width_p(1)
       ,.harden_p(1)
       ) btc_trigger
       (.bsg_tag_i(bsg_tag_trigger_i)
        ,.data_async_r_o(fb_we_r)
        );

   wire [1:0] cdt = fb_tag_r.cdt;
   wire [1:0] fdt = fb_tag_r.fdt;
   wire [num_adgs_p-1:0] adg_ctrl = fb_tag_r.adg;

   logic [4+num_adgs_p-1:0] ctrl_rrr;
   always @(posedge fb_we_r)
     ctrl_rrr <= {adg_ctrl, cdt, fdt};

   always
     begin
        #(osc_base_delay_lp);
        if (ctrl_rrr !== 'X)
          # (
             ((1 << $bits(ctrl_rrr)) - ctrl_rrr)*osc_granularity_lp
            )
        clk_o <= (clk_i | async_reset_i);

     end


endmodule
