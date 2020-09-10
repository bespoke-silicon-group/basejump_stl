/**
 *  bsg_dff_en.v
 *  @param width_p data width
 */

`include "bsg_defines.v"

module bsg_dff_en #(parameter width_p="inv"
                   ,parameter harden_p=1   // mbt fixme: maybe this should not be a default
                   ,parameter strength_p=1)
(
  input clk_i
  ,input [width_p-1:0] data_i
  ,input en_i
  ,output logic [width_p-1:0] data_o
);

  logic [width_p-1:0] data_r;

  assign data_o = data_r;

  always_ff @ (posedge clk_i) begin
    if (en_i) begin
      data_r <= data_i;
    end
  end

endmodule
