/**
 *	bsg_fpu_clz.v
 *	
 *	@author tommy
 *
 *	It counts the number of leading zeros.
 *  It does not detected if the input vector is all zero.
 *
 *  ------------------------
 *	example (width_p=4)
 *	------------------------
 *	i             num_zero_o
 *	------------------------
 *	4'b1xxx       2'b0
 *	4'b01xx       2'b1
 *	4'b001x       2'b2
 *	4'b0001       2'b3
 *	4'b0000       invalid
 *
 */

`include "bsg_defines.v"

module bsg_fpu_clz
  #(parameter width_p="inv"
    , localparam lg_width_lp=`BSG_SAFE_CLOG2(width_p)
  )
  (
    input [width_p-1:0] i
    , output logic [lg_width_lp-1:0] num_zero_o
  );
 

  logic [width_p-1:0] reversed;

  for (genvar j = 0; j < width_p; j++) begin
    assign reversed[j] = i[width_p-1-j];
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
