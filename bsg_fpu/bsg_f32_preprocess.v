/**
 *	bsg_f32_preprocess.v
 *
 *	@author Tommy Jung
 */

module bsg_f32_preprocess (
    input [31:0] a_i,			// input
    output logic zero_o,		// it is zero
    output logic nan_o,			// it is nan
    output logic sig_nan_o, 	// it is sig nan
    output logic infty_o,		// it is infinity
    output logic exp_zero_o,	// exp is zero
    output logic man_zero_o,	// mantissa is zero
    output logic denormal_o,	// it is denormal
    output logic sign_o,	 	// sign
    output logic [7:0] exp_o,	// exponent
    output logic [22:0] man_o	// mantissa
);

logic [22:0] mantissa;
logic [7:0] exp;
logic sign;

assign mantissa = a_i[22:0];
assign exp = a_i[30:23];
assign sign = a_i[31];

logic mantissa_zero, exp_zero, exp_ones;
assign mantissa_zero = (mantissa == 23'b0);
assign exp_zero = (exp == 8'b0);
assign exp_ones = (exp == 8'hff);

// outputs
assign zero_o = exp_zero & mantissa_zero;
assign nan_o = exp_ones & ~mantissa_zero; 
assign sig_nan_o = nan_o & ~mantissa[22];
assign infty_o = exp_ones & mantissa_zero;
assign exp_zero_o = exp_zero;
assign man_zero_o = mantissa_zero;
assign denormal_o = exp_zero & ~mantissa_zero;
assign sign_o = sign;
assign exp_o = exp;
assign man_o = mantissa;

endmodule
