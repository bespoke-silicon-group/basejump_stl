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
   
   if (els_p == 1)
     begin
      assign data_o = data_i;
      wire unused = sel_i;
     end
   else
     assign data_o = data_i[sel_i];

   // synopsys translate_off
   initial
     assert(balanced_p == 0)
       else $error("%m warning: synthesizable implementation of bsg_mux does not support balanced_p");
   // synopsys translate_on

endmodule

