/**
 *	bsg_adder_full.v
 *
 * 	full adder
 *
 *	@author Tommy Jung
 */


module bsg_adder_full (
    input a_i
    , input b_i
    , input c_i
    , output logic s_o
    , output logic c_o
    );

  assign {c_o, s_o} = a_i + b_i + c_i;

endmodule
