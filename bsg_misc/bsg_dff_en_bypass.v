/**
 *  bsg_dff_en_bypass.v
 *
 */


`include "bsg_defines.v"

module bsg_dff_en_bypass
  #(parameter width_p="inv"
    , parameter harden_p=0
    , parameter strength_p=0
  )
  (
    input clk_i
    , input en_i
    , input [width_p-1:0] data_i
    , output logic [width_p-1:0] data_o
  );

  logic [width_p-1:0] data_r;

  bsg_dff_en #(
    .width_p(width_p)
    ,.harden_p(harden_p)
    ,.strength_p(strength_p)
  ) dff (
    .clk_i(clk_i)
    ,.en_i(en_i)
    ,.data_i(data_i)
    ,.data_o(data_r)
  );

  assign data_o = en_i
    ? data_i
    : data_r;



endmodule
