/**
 *	bsg_hadder.v
 *
 *	half adder
 *
 *	@author Tommy Jung
 */


module bsg_hadder (
    input a_i,			// a
    input b_i,			// b
    output s_o,			// sum
    output c_o			// carry out
);

assign s_o = a_i ^ b_i;
assign c_o = a_i & b_i;

endmodule
