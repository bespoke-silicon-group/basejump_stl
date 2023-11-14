`include "bsg_defines.sv"

`timescale 1ps/1ps

// This module is a behavioral model of the clock generator ring
// oscillator. A TSMC 28nm hardened implementation of this module
// can be found at:
//
//      basejump_stl/hard/tsmc_28/bsg_clk_gen/bsg_clk_gen_osc_v3.sv
//
// This module should be replaced by the hardened version
// when being synthesized.

`include "bsg_clk_gen.svh"

module bsg_clk_gen_osc_v3
  import bsg_tag_pkg::bsg_tag_s;

    #(parameter num_taps_p=2)
  (
   input async_reset_i
   ,input bsg_tag_s bsg_tag_i
   ,input bsg_tag_s bsg_tag_trigger_i
   ,output logic clk_o
   );

  localparam ctl_width_lp = `BSG_SAFE_CLOG2(num_taps_p);

   logic [ctl_width_lp-1:0] fb_tag_r;
   bsg_tag_client_unsync
  #(.width_p(ctl_width_lp)
   ,.harden_p(0)
   ) btc
   (.bsg_tag_i(bsg_tag_i)
   ,.data_async_r_o(fb_tag_r)
   );

   logic trig_r; 
   bsg_tag_client_unsync
  #(.width_p(1)
   ,.harden_p(0)
   ) btc_trigger
   (.bsg_tag_i(bsg_tag_trigger_i)
   ,.data_async_r_o(trig_r)
   );


   logic [ctl_width_lp-1:0] ctrl_rrr;
   always @(clk_o or async_reset_i)
     if (async_reset_i)
       ctrl_rrr <= '0;
     else
       if (trig_r)
         ctrl_rrr <= fb_tag_r;

   always
     begin
        #1000
        if (ctrl_rrr !== 'X)
          # (
             ((1 << $bits(ctrl_rrr)) - ctrl_rrr)*100
            )
        clk_o <= ~(clk_o | async_reset_i);

     end


endmodule
