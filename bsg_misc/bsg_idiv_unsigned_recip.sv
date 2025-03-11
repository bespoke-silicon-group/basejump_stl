`include "bsg_defines.sv"
`include "bsg_idiv_unsigned_recip.svh"

// This implements unsigned divide of a variable numerator by an infrequently changing divisor. 
// Outside of this module the divisor is pre-processed into a multiply value and a shift value, 
// which are inputs to this module and are applied to the input numerator.
//
// The shift value is calculated as ceil(log_2 divisor), and the multiply value is
// calculated as ceil(2^(shift+numer_width_p) / divisor). Importantly the width of 
// the multiply value is 1 bit wider than the numerator width. This creates some issue
// in software implementations since it requires a 33-bit constant for a 32-bit numerator
// but is not an issue in hardware. Note that when the shift and multiply value are applied
// the expression is   N * multiply >> (shift + numer_width_p). This is a slight reformulation vs.
// than the publication below.

// See also bsg_hash_bank, which implements division by constants of the form 2^n * (2^m-1).
//
// This implements what is described in "Integer Division Using Reciprocals" 
// by Robert Alverson, ARITH 10, 1991.
// http://degiorgi.math.hr/aaa_sem/Div/186-190.pdf



module bsg_idiv_unsigned_recip #(parameter `BSG_INV_PARAM(numer_width_p)
				 , `BSG_INV_PARAM(denom_width_p)
				 , parameter shift_width_p=`bsg_idiv_unsigned_recip_shift_width(denom_width_p)
				 , parameter multiply_width_p=`bsg_idiv_unsigned_recip_multiply_width(numer_width_p)
				 )
   (
    // these are the "infrequently changing" inputs
    // that represent the constant being divided by
    input [multiply_width_p-1:0] cfg_multiply_i
    , input [shift_width_p-1:0] cfg_shift_i
    // these are the "live" inputs and outputs
    , input [numer_width_p-1:0] i
    , output [numer_width_p-1:0] o
    );

   wire [multiply_width_p+numer_width_p-1:0]   mul = cfg_multiply_i * i;
   // implicit shift right by numer_width_p, followed by shift by cfg_shift_i
   assign o = mul[multiply_width_p+numer_width_p-1:numer_width_p] >> cfg_shift_i;

endmodule

`BSG_ABSTRACT_MODULE(bsg_idiv_unsigned_recip)
