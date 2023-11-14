/**
 *  bsg_dff_en.sv
 *  @param width_p data width
 */

`include "bsg_defines.sv"

module bsg_dff_en #(parameter `BSG_INV_PARAM(width_p)
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

`BSG_ABSTRACT_MODULE(bsg_dff_en)
