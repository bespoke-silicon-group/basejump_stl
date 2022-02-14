`include "bsg_defines.v"


module bsg_dly_cell
  #(`BSG_INV_PARAM(width_p)
    ,parameter harden_p=0
  )
  (
    input [width_p-1:0] i
    , output logic [width_p-1:0] o
  );


  assign o = i;

endmodule


`BSG_ABSTRACT_MODULE(bsg_dly_cell)
