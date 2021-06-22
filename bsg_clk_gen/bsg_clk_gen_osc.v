`timescale 1ps/1ps

// This module is a behavioral model of the clock generator ring
// oscillator. A TSMC 250nm hardened implementation of this module
// can be found at:
//
//      bsg_ip_cores/hard/bsg_clk_gen/bsg_clk_gen_osc.v
//
// This module should be replaced by the hardened version
// when being synthesized.

`include "bsg_clk_gen.vh"

module bsg_clk_gen_osc
  import bsg_tag_pkg::bsg_tag_s;

    #(parameter num_adgs_p=1)
  (
   input async_reset_i
   ,input bsg_tag_s bsg_tag_i
   ,input bsg_tag_s bsg_tag_trigger_i
   ,output logic clk_o
   );

   `declare_bsg_clk_gen_osc_tag_payload_s(num_adgs_p)

   bsg_clk_gen_osc_tag_payload_s fb_tag_r;
   bsg_tag_client_unsync
  #(.width_p($bits(bsg_clk_gen_osc_tag_payload_s))
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

   wire [1:0] cdt = fb_tag_r.cdt;
   wire [1:0] fdt = fb_tag_r.fdt;
   wire [num_adgs_p-1:0] adg_ctrl = fb_tag_r.adg;

   logic [4+num_adgs_p-1:0] ctrl_rrr;
   always @(clk_o or async_reset_i)
     if (async_reset_i)
       ctrl_rrr <= '0;
     else
       if (trig_r)
         ctrl_rrr <= {adg_ctrl, cdt, fdt};

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
