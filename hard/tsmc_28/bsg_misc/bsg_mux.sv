`include "bsg_defines.sv"

module bsg_mux #(parameter `BSG_INV_PARAM(width_p)
                 , `BSG_INV_PARAM(els_p)
                 , harden_p = 0
                 , balanced_p = 0
                 , lg_els_lp=`BSG_SAFE_CLOG2(els_p)
                 )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [lg_els_lp-1:0] sel_i
    ,output [width_p-1:0] data_o
    );

   if ((els_p == 4) && (harden_p == 1) && (balanced_p))
     begin : macro
        for (genvar j = 0; j < width_p; j=j+1)
          begin: rof
             // fast, but not too extreme
             MUX4D4BWP7T30P140ULVT M0_BSG_RESIZE_OK (.I0(data_i[0][j]), .I1(data_i[1][j]), .I2(data_i[2][j]), .I3(data_i[3][j]), .S0(sel_i[0]), .S1(sel_i[1]), .Z(data_o[j]));
          end
     end
   else if ((els_p == 2) && (harden_p == 1) && (balanced_p))
     begin : macro
        for (genvar j = 0; j < width_p; j=j+1)
          begin: rof
              // fast, but not too extreme
              MUX2D4BWP7T30P140ULVT M0_BSG_RESIZE_OK (.I0(data_i[0][j]), .I1(data_i[1][j]), .S(sel_i[0]), .Z(data_o[j]));
          end
     end
   else if ((els_p == 1) && (harden_p == 1) && (balanced_p))
     begin : macro
        wire unused_sel;
        wire [width_p-1:0] unused;
        TIELBWP7T40P140 TIE_LO_BSG_DONT_TOUCH (.ZN(unused_sel));
        for (genvar j = 0; j < width_p; j=j+1)
          begin: rof
              // fast, but not too extreme
              TIELBWP7T40P140 TIE_LO_BSG_DONT_TOUCH (.ZN(unused[j]));
              MUX2D4BWP7T30P140ULVT M0_BSG_RESIZE_OK (.I0(data_i[0][j]), .I1(unused[j]), .S(unused_sel), .Z(data_o[j]));
          end
     end
   else if (els_p == 1)
     begin : notmacro
       `BSG_SYNTH_HARDEN_ATTEMPT(harden_p)
       assign data_o = data_i;
       wire unused = sel_i;
     end
   else
     begin : notmacro
       `BSG_SYNTH_HARDEN_ATTEMPT(harden_p)
       assign data_o = data_i[sel_i];
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_mux)




