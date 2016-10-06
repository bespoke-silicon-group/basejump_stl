// This module is a behavioral model of the clock generator ring
// oscillator. A TSMC 250nm hardened implementation of this module
// can be found at:
//
//      bsg_ip_cores/hard/bsg_clk_gen/bsg_clk_gen_osc.v
//
// This module should be replaced by the hardened version
// when being synthesized.
//
//
// mbt: this file is out of date and probably not consistent
//      with the real implementations in the hard directory
//

module bsg_clk_gen_osc
  (input        rst
  ,input  [1:0] adg_ctrl
  ,input  [1:0] cdt
  ,input  [1:0] fdt
  ,input        pwr_off
  ,output logic clk
  );

  wire [5:0] ctrl = {adg_ctrl, cdt, fdt};

  logic [5:0] ctrl_r, ctrl_rr, ctrl_rrr;

  always @(posedge clk or posedge rst)
    begin
      if (rst)
        begin
          ctrl_r   <= 6'b000000;
          ctrl_rr  <= 6'b000000;
          ctrl_rrr <= 6'b000000;
        end
      else
        begin
          ctrl_r   <= ctrl;
          ctrl_rr  <= ctrl_r;
          ctrl_rrr <= ctrl_rr;
        end
    end

  always
    begin

      if ($isunknown(ctrl_rrr))
        #1 clk = 1'bx;
      else
        begin

          integer delay;

          if      (ctrl_rrr == 6'd0 ) delay = 136;
          else if (ctrl_rrr == 6'd1 ) delay = 134;
          else if (ctrl_rrr == 6'd2 ) delay = 132;
          else if (ctrl_rrr == 6'd3 ) delay = 130;
          else if (ctrl_rrr == 6'd4 ) delay = 128;
          else if (ctrl_rrr == 6'd5 ) delay = 126;
          else if (ctrl_rrr == 6'd6 ) delay = 124;
          else if (ctrl_rrr == 6'd7 ) delay = 122;
          else if (ctrl_rrr == 6'd8 ) delay = 120;
          else if (ctrl_rrr == 6'd9 ) delay = 118;
          else if (ctrl_rrr == 6'd10) delay = 116;
          else if (ctrl_rrr == 6'd11) delay = 114;
          else if (ctrl_rrr == 6'd12) delay = 112;
          else if (ctrl_rrr == 6'd13) delay = 110;
          else if (ctrl_rrr == 6'd14) delay = 108;
          else if (ctrl_rrr == 6'd15) delay = 106;
          else if (ctrl_rrr == 6'd16) delay = 104;
          else if (ctrl_rrr == 6'd17) delay = 102;
          else if (ctrl_rrr == 6'd18) delay = 100;
          else if (ctrl_rrr == 6'd19) delay = 98;
          else if (ctrl_rrr == 6'd20) delay = 96;
          else if (ctrl_rrr == 6'd21) delay = 94;
          else if (ctrl_rrr == 6'd22) delay = 92;
          else if (ctrl_rrr == 6'd23) delay = 90;
          else if (ctrl_rrr == 6'd24) delay = 88;
          else if (ctrl_rrr == 6'd25) delay = 86;
          else if (ctrl_rrr == 6'd26) delay = 84;
          else if (ctrl_rrr == 6'd27) delay = 82;
          else if (ctrl_rrr == 6'd28) delay = 80;
          else if (ctrl_rrr == 6'd29) delay = 78;
          else if (ctrl_rrr == 6'd30) delay = 76;
          else if (ctrl_rrr == 6'd31) delay = 74;
          else if (ctrl_rrr == 6'd32) delay = 72;
          else if (ctrl_rrr == 6'd33) delay = 70;
          else if (ctrl_rrr == 6'd34) delay = 68;
          else if (ctrl_rrr == 6'd35) delay = 66;
          else if (ctrl_rrr == 6'd36) delay = 64;
          else if (ctrl_rrr == 6'd37) delay = 62;
          else if (ctrl_rrr == 6'd38) delay = 60;
          else if (ctrl_rrr == 6'd39) delay = 58;
          else if (ctrl_rrr == 6'd40) delay = 56;
          else if (ctrl_rrr == 6'd41) delay = 54;
          else if (ctrl_rrr == 6'd42) delay = 52;
          else if (ctrl_rrr == 6'd43) delay = 50;
          else if (ctrl_rrr == 6'd44) delay = 48;
          else if (ctrl_rrr == 6'd45) delay = 46;
          else if (ctrl_rrr == 6'd46) delay = 44;
          else if (ctrl_rrr == 6'd47) delay = 42;
          else if (ctrl_rrr == 6'd48) delay = 40;
          else if (ctrl_rrr == 6'd49) delay = 38;
          else if (ctrl_rrr == 6'd50) delay = 36;
          else if (ctrl_rrr == 6'd51) delay = 34;
          else if (ctrl_rrr == 6'd52) delay = 32;
          else if (ctrl_rrr == 6'd53) delay = 30;
          else if (ctrl_rrr == 6'd54) delay = 28;
          else if (ctrl_rrr == 6'd55) delay = 26;
          else if (ctrl_rrr == 6'd56) delay = 24;
          else if (ctrl_rrr == 6'd57) delay = 22;
          else if (ctrl_rrr == 6'd58) delay = 20;
          else if (ctrl_rrr == 6'd59) delay = 18;
          else if (ctrl_rrr == 6'd60) delay = 16;
          else if (ctrl_rrr == 6'd61) delay = 14;
          else if (ctrl_rrr == 6'd62) delay = 12;
          else if (ctrl_rrr == 6'd63) delay = 10;
      
          #delay clk = 1'b0 & ~rst;
          #delay clk = 1'b1 & ~rst;

        end
    end

endmodule
