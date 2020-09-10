/**
 *	bsg_counting_leading_zeros.v
 *
 *	@author Tommy Jung
 */

`include "bsg_defines.v"

module bsg_counting_leading_zeros #(parameter width_p="inv")
(
  input [width_p-1:0] a_i
  ,output logic [`BSG_SAFE_CLOG2(width_p)-1:0] num_zero_o
);
 

  logic [width_p-1:0] reversed;
  genvar i;
  for (i = 0; i < width_p; i++) begin
    assign reversed[i] = a_i[width_p-1-i];
  end  

  bsg_priority_encode #(
    .width_p(width_p)
    ,.lo_to_hi_p(1)
  ) pe0 (
    .i(reversed)
    ,.addr_o(num_zero_o)
    ,.v_o()
  );
  
endmodule
