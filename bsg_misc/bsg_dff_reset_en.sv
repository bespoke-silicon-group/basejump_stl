/**
 *  bsg_dff_reset_en.sv
 */

`include "bsg_defines.sv"

module bsg_dff_reset_en
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter reset_val_p=0
    , parameter harden_p=0
  )
  (
    input clk_i
    , input reset_i
    , input en_i
    , input [width_p-1:0] data_i
    , output logic [width_p-1:0] data_o
  );

  logic  [width_p-1:0] data_r;

  assign data_o = data_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      data_r <= width_p'(reset_val_p);
    end
    else begin
      if (en_i) begin
        data_r <= data_i;
      end
    end
  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_dff_reset_en)
