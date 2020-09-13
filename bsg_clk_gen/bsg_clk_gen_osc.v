`include "bsg_defines.v"

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
   ,output logic clk_o
   );

   `declare_bsg_clk_gen_osc_tag_payload_s(num_adgs_p)

   bsg_clk_gen_osc_tag_payload_s fb_tag_r;
   wire  fb_we_r;

   // note: oscillator has to be already working in order
   // for configuration state to pass through here

   bsg_tag_client #(.width_p($bits(bsg_clk_gen_osc_tag_payload_s))
                    ,.harden_p(1)
                    ,.default_p(0)
                    ) btc
     (.bsg_tag_i     (bsg_tag_i)
      ,.recv_clk_i   (clk_o)
      ,.recv_reset_i (1'b0)     // no default value is loaded;
      ,.recv_new_r_o (fb_we_r)  // default is already in OSC flops
      ,.recv_data_r_o(fb_tag_r)
      );

   wire [1:0] cdt = fb_tag_r.cdt;
   wire [1:0] fdt = fb_tag_r.fdt;
   wire [num_adgs_p-1:0] adg_ctrl = fb_tag_r.adg;

   logic [4+num_adgs_p-1:0] ctrl_rrr;
   always @(clk_o or async_reset_i)
     if (async_reset_i)
       ctrl_rrr <= '0;
     else
       if (fb_we_r)
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
