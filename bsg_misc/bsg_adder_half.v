/**
 *	bsg_adder_half.v
 *
 *	half adder
 *
 *	@author Tommy Jung
 */


module bsg_adder_half (
    input a_i
    , input b_i
    , output logic s_o
    , output logic c_o
    );

  assign {c_o, s_o} = a_i + b_i;

endmodule
