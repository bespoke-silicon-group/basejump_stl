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
   input bsg_tag_s bsg_tag_i
   ,input async_reset_i
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

  wire [4+num_adgs_p-1:0] ctrl_rrr = {adg_ctrl, cdt, fdt};

  always
    begin

      if ($isunknown(ctrl_rrr))
        #1 clk_o = 1'bx;
      else
        begin

          integer delay;

          if      (ctrl_rrr == 6'd0 ) delay = 1360;
          else if (ctrl_rrr == 6'd1 ) delay = 1340;
          else if (ctrl_rrr == 6'd2 ) delay = 1320;
          else if (ctrl_rrr == 6'd3 ) delay = 1300;
          else if (ctrl_rrr == 6'd4 ) delay = 1280;
          else if (ctrl_rrr == 6'd5 ) delay = 1260;
          else if (ctrl_rrr == 6'd6 ) delay = 1240;
          else if (ctrl_rrr == 6'd7 ) delay = 1220;
          else if (ctrl_rrr == 6'd8 ) delay = 1200;
          else if (ctrl_rrr == 6'd9 ) delay = 1180;
          else if (ctrl_rrr == 6'd10) delay = 1160;
          else if (ctrl_rrr == 6'd11) delay = 1140;
          else if (ctrl_rrr == 6'd12) delay = 1120;
          else if (ctrl_rrr == 6'd13) delay = 1100;
          else if (ctrl_rrr == 6'd14) delay = 1080;
          else if (ctrl_rrr == 6'd15) delay = 1060;
          else if (ctrl_rrr == 6'd16) delay = 1040;
          else if (ctrl_rrr == 6'd17) delay = 1020;
          else if (ctrl_rrr == 6'd18) delay = 1000;
          else if (ctrl_rrr == 6'd19) delay = 980;
          else if (ctrl_rrr == 6'd20) delay = 960;
          else if (ctrl_rrr == 6'd21) delay = 940;
          else if (ctrl_rrr == 6'd22) delay = 920;
          else if (ctrl_rrr == 6'd23) delay = 900;
          else if (ctrl_rrr == 6'd24) delay = 880;
          else if (ctrl_rrr == 6'd25) delay = 860;
          else if (ctrl_rrr == 6'd26) delay = 840;
          else if (ctrl_rrr == 6'd27) delay = 820;
          else if (ctrl_rrr == 6'd28) delay = 800;
          else if (ctrl_rrr == 6'd29) delay = 780;
          else if (ctrl_rrr == 6'd30) delay = 760;
          else if (ctrl_rrr == 6'd31) delay = 740;
          else if (ctrl_rrr == 6'd32) delay = 720;
          else if (ctrl_rrr == 6'd33) delay = 700;
          else if (ctrl_rrr == 6'd34) delay = 680;
          else if (ctrl_rrr == 6'd35) delay = 660;
          else if (ctrl_rrr == 6'd36) delay = 640;
          else if (ctrl_rrr == 6'd37) delay = 620;
          else if (ctrl_rrr == 6'd38) delay = 600;
          else if (ctrl_rrr == 6'd39) delay = 580;
          else if (ctrl_rrr == 6'd40) delay = 560;
          else if (ctrl_rrr == 6'd41) delay = 540;
          else if (ctrl_rrr == 6'd42) delay = 520;
          else if (ctrl_rrr == 6'd43) delay = 500;
          else if (ctrl_rrr == 6'd44) delay = 480;
          else if (ctrl_rrr == 6'd45) delay = 460;
          else if (ctrl_rrr == 6'd46) delay = 440;
          else if (ctrl_rrr == 6'd47) delay = 420;
          else if (ctrl_rrr == 6'd48) delay = 400;
          else if (ctrl_rrr == 6'd49) delay = 380;
          else if (ctrl_rrr == 6'd50) delay = 360;
          else if (ctrl_rrr == 6'd51) delay = 340;
          else if (ctrl_rrr == 6'd52) delay = 320;
          else if (ctrl_rrr == 6'd53) delay = 300;
          else if (ctrl_rrr == 6'd54) delay = 280;
          else if (ctrl_rrr == 6'd55) delay = 260;
          else if (ctrl_rrr == 6'd56) delay = 240;
          else if (ctrl_rrr == 6'd57) delay = 220;
          else if (ctrl_rrr == 6'd58) delay = 200;
          else if (ctrl_rrr == 6'd59) delay = 180;
          else if (ctrl_rrr == 6'd60) delay = 160;
          else if (ctrl_rrr == 6'd61) delay = 140;
          else if (ctrl_rrr == 6'd62) delay = 120;
          else if (ctrl_rrr == 6'd63) delay = 100;
      
          #delay clk_o = 1'b0 & ~async_reset_i;
          #delay clk_o = 1'b1 & ~async_reset_i;

        end
    end

endmodule
