/**
 *	bsg_fpu_clz.v
 *	
 *	It counts the number of leading zeros.
 *
 *	@author Tommy Jung
 */

module bsg_fpu_clz
  #(parameter width_p="inv"
    , localparam lg_width_lp=`BSG_SAFE_CLOG2(width_p)
  )
  (
    input [width_p-1:0] i
    ,output logic [lg_width_lp-1:0] num_zero_o
  );
 

  logic [width_p-1:0] reversed;
  genvar j;
  for (j = 0; j < width_p; j++) begin
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
