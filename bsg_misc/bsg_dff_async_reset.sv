`include "bsg_defines.sv"

module bsg_dff_async_reset

 #(parameter `BSG_INV_PARAM(width_p     )
  ,parameter reset_val_p = 0
  ,parameter harden_p    = 0
  )

  (input                clk_i
  ,input                async_reset_i
  ,input  [width_p-1:0] data_i
  ,output [width_p-1:0] data_o
  );

  logic [width_p-1:0] data_r;

  assign data_o = data_r;

  always_ff @(posedge clk_i or posedge async_reset_i)
    if (async_reset_i)
        data_r <= (width_p)'(reset_val_p);
    else
        data_r <= data_i;

endmodule

`BSG_ABSTRACT_MODULE(bsg_dff_async_reset)
