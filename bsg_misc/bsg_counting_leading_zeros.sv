/**
 *	bsg_counting_leading_zeros.sv
 *
 *	@author Tommy Jung
 */

`include "bsg_defines.sv"

module bsg_counting_leading_zeros #(
  parameter `BSG_INV_PARAM(width_p)
  , parameter num_zero_width_lp=`BSG_WIDTH(width_p)
)
(
  input [width_p-1:0] a_i
  ,output logic [num_zero_width_lp-1:0] num_zero_o
);
 

  logic [width_p:0] reversed;
  genvar i;
  for (i = 0; i < width_p; i++) begin
    assign reversed[i] = a_i[width_p-1-i];
  end
  assign reversed[width_p] = 1'b1;

  bsg_priority_encode #(
    .width_p(width_p+1)
    ,.lo_to_hi_p(1)
  ) pe0 (
    .i(reversed)
    ,.addr_o(num_zero_o)
    ,.v_o()
  );
   
endmodule

`BSG_ABSTRACT_MODULE(bsg_counting_leading_zeros)
