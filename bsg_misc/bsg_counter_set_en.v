/**
 *  bsg_counter_set_en.sv
 */

`include "bsg_defines.sv"

module bsg_counter_set_en
  #(parameter `BSG_INV_PARAM(max_val_p)
    , parameter lg_max_val_lp=`BSG_WIDTH(max_val_p)
    , parameter reset_val_p=0
  )
  (
    input clk_i
    , input reset_i

    , input set_i
    , input en_i
    , input [lg_max_val_lp-1:0] val_i
    , output logic [lg_max_val_lp-1:0] count_o
  );


  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      count_o <= (lg_max_val_lp)'(reset_val_p);
    end
    else if (set_i) begin
      count_o <= val_i;
    end
    else if (en_i) begin
      count_o <= count_o + 1'b1;
    end
  end


endmodule

`BSG_ABSTRACT_MODULE(bsg_counter_set_en)
