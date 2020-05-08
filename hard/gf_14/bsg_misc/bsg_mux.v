`include "bsg_defines.v"

module bsg_mux #(parameter width_p="inv"
                 , els_p=1
                 , harden_p = 0
                 , balanced_p = 0
                 , lg_els_lp=`BSG_SAFE_CLOG2(els_p)
                 )
   (
    input [els_p-1:0][width_p-1:0] data_i
    ,input [lg_els_lp-1:0] sel_i
    ,output [width_p-1:0] data_o
    );

   genvar j;

   if ((els_p == 4) && (harden_p == 1) && (balanced_p))
     begin : fi
        for (j = 0; j < width_p; j=j+1)
          begin: rof
             // fast, but not too extreme
             SC7P5T_MUX4X4_SSC16L BSG_BAL41MUX_DONT_TOUCH (.D0(data_i[0][j]), .D1(data_i[1][j]), .D2(data_i[2][j]), .D3(data_i[3][j]), .S0(sel_i[0]), .S1(sel_i[1]), .Z(data_o[j]));
          end
     end
   else
     begin : nofi

        if (els_p == 1) begin
          assign data_o = data_i;
          wire unused = sel_i;
        end
        else begin
          assign data_o = data_i[sel_i];
        end


        // synopsys translate_off
        initial
          assert(balanced_p == 0)
            else $error("%m warning: synthesizable implementation of bsg_mux does not support balanced_p");
       // synopsys translate_on
     end

endmodule




