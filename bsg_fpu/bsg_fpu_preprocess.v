/**
 *	bsg_fpu_preprocess.v
 *
 *	@author Tommy Jung
 */

module bsg_fpu_preprocess #(parameter exp_width_p = "inv"
                            , parameter mantissa_width_p = "inv")
  (
    input [exp_width_p+mantissa_width_p:0] a_i
    , output logic zero_o
    , output logic nan_o
    , output logic sig_nan_o
    , output logic infty_o
    , output logic exp_zero_o
    , output logic man_zero_o
    , output logic denormal_o
    , output logic sign_o
    , output logic [exp_width_p-1:0] exp_o
    , output logic [mantissa_width_p-1:0] man_o
    );

  assign man_o = a_i[mantissa_width_p-1:0];
  assign exp_o = a_i[exp_width_p+mantissa_width_p-1:mantissa_width_p];
  assign sign_o = a_i[exp_width_p+mantissa_width_p];

  logic mantissa_zero, exp_zero, exp_ones;
  assign mantissa_zero = (man_o == {mantissa_width_p{1'b0}});
  assign exp_zero = (exp_o == {exp_width_p{1'b0}});
  assign exp_ones = (exp_o == {exp_width_p{1'b1}});

  // outputs
  assign zero_o = exp_zero & mantissa_zero;
  assign nan_o = exp_ones & ~mantissa_zero; 
  assign sig_nan_o = nan_o & ~man_o[mantissa_width_p-1];
  assign infty_o = exp_ones & mantissa_zero;
  assign exp_zero_o = exp_zero;
  assign man_zero_o = mantissa_zero;
  assign denormal_o = exp_zero & ~mantissa_zero;

endmodule
