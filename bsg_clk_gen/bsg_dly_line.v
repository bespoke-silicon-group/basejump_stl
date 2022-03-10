`include "bsg_defines.v"

`timescale 1ps/1ps

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

    #(parameter num_rows_p=2, num_cols_p=2)
  (
   input async_reset_i
   ,input bsg_tag_s bsg_tag_i
   ,input bsg_tag_s bsg_tag_trigger_i
   ,input clk_i
   ,output logic clk_o
   );

   `declare_bsg_clk_gen_osc_tag_payload_s(num_rows_p, num_cols_p);

   bsg_clk_gen_osc_tag_payload_s fb_tag_r;
   wire  fb_we_r;

   // note: oscillator has to be already working in order
   // for configuration state to pass through here

   bsg_tag_client #(.width_p($bits(bsg_clk_gen_osc_tag_payload_s))
                    ,.harden_p(1)
                    ) btc
     (.bsg_tag_i     (bsg_tag_i)
      ,.recv_clk_i   (clk_o)
      ,.recv_new_r_o (fb_we_r)  // default is already in OSC flops
      ,.recv_data_r_o(fb_tag_r)
      );

   logic [`BSG_SAFE_CLOG2(num_rows_p*num_cols_p)-1:0] ctrl_rrr;
   always @(clk_o or async_reset_i)
     if (async_reset_i)
       ctrl_rrr <= '0;
     else
       if (fb_we_r)
         ctrl_rrr <= fb_tag_r;

   always
     begin
        #1000
        if (ctrl_rrr !== 'X)
          # (
             ((1 << $bits(ctrl_rrr)) - ctrl_rrr)*100
            )
        clk_o <= (clk_i | async_reset_i);

     end


endmodule
