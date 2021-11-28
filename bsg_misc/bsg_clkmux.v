`include "bsg_defines.v"
module bsg_clkmux #(`BSG_INV_PARAM(els_p)
                 , harden_p = 0
                 , lg_els_lp=`BSG_SAFE_CLOG2(els_p)
                 )
   (
    input [els_p-1:0] data_i
    ,input [lg_els_lp-1:0] sel_i
    ,output data_o
    );

   if (els_p == 1)
     begin
      assign data_o = data_i;
      wire unused = sel_i;
     end
   else
     assign data_o = data_i[sel_i];

endmodule

`BSG_ABSTRACT_MODULE(bsg_clkmux)

