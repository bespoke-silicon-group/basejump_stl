// NB: for larger sizes, may make sense to have a benes network implementation option
// since it is assymptotically better than a full crossbar for datapath.

`include "bsg_defines.sv"

module bsg_crossbar_o_by_i #( parameter `BSG_INV_PARAM(i_els_p)
                             ,parameter `BSG_INV_PARAM(o_els_p)
                             ,parameter `BSG_INV_PARAM(width_p)
                            )
  ( input  [i_els_p-1:0][width_p-1:0] i
   ,input  [o_els_p-1:0][i_els_p-1:0] sel_oi_one_hot_i
   ,output [o_els_p-1:0][width_p-1:0] o
  );

  genvar lineout;

  for(lineout=0; lineout<o_els_p; lineout++) begin: l
    bsg_mux_one_hot #( .width_p(width_p)
                      ,.els_p  (i_els_p)
                     ) mux_one_hot
                     ( .data_i        (i)
                      ,.sel_one_hot_i (sel_oi_one_hot_i[lineout])
                      ,.data_o        (o[lineout])
                     );
  end

endmodule // bsg_crossbar_o_by_i

`BSG_ABSTRACT_MODULE(bsg_crossbar_o_by_i)
