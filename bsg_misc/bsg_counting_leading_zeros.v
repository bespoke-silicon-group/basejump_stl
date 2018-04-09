/**
 *	bsg_counting_leading_zeros.v
 *
 *	@author Tommy Jung
 */

module bsg_counting_leading_zeros #(parameter width_p="inv")
  (
    input [width_p-1:0] a_i
    , output logic [`BSG_SAFE_CLOG2(width_p)-1:0] num_zero_o
    );
 
  logic [`BSG_SAFE_CLOG2(width_p)-1:0] addr;
   
  bsg_priority_encode #(.width_p(width_p)
                        ,.lo_to_hi_p(0)) pe0
    (.i(a_i)
    ,.addr_o(addr)
    ,.v_o()
    );
  
  assign num_zero_o = ~addr;

endmodule
