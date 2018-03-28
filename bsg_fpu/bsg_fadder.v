/**
 *	bsg_fadder.v
 *
 * 	full adder
 *
 *	@author Tommy Jung
 */


module bsg_fadder (
    input a_i,				// a
    input b_i,				// b
    input c_i,				// carry in
    output logic s_o,		// sum
    output logic c_o		// carry out
);

assign s_o = a_i ^ b_i ^ c_i;
assign c_o = (a_i & b_i) | (a_i & c_i) | (b_i & c_i);

endmodule
