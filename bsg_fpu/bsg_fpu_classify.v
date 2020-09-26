/**
 *  bsg_fpu_classify.v
 *
 *  in the spirit of RISC-V FCLASS instruction.
 *
 *  o[0] = neg infty.
 *  o[1] = neg normal number
 *  o[2] = neg subnormal number
 *  o[3] = neg zero
 *  o[4] = pos zero
 *  o[5] = pos subnormal number
 *  o[6] = pos normal number
 *  o[7] = pos infty
 *  o[8] = sig nan
 *  o[9] = quite nan
 */


`include "bsg_defines.v"

module bsg_fpu_classify
  #(parameter e_p="inv"
    , parameter m_p="inv"

    , parameter width_lp=(e_p+m_p+1)
    , parameter out_width_lp=width_lp
  )
  (
    input [width_lp-1:0] a_i
    , output [out_width_lp-1:0] class_o
  );

  logic zero;
  logic nan;
  logic sig_nan;
  logic infty;
  logic denormal;
  logic sign;

  bsg_fpu_preprocess #(
    .e_p(e_p)
    ,.m_p(m_p)
  ) prep (
    .a_i(a_i)
    ,.zero_o(zero)
    ,.nan_o(nan)
    ,.sig_nan_o(sig_nan)
    ,.infty_o(infty)
    ,.exp_zero_o()
    ,.man_zero_o()
    ,.denormal_o(denormal)
    ,.sign_o(sign)
    ,.exp_o()
    ,.man_o()
  );


  assign class_o[0] = sign & infty;
  assign class_o[1] = sign & (~infty) & (~denormal) & (~nan) & (~zero);
  assign class_o[2] = sign & denormal;
  assign class_o[3] = sign & zero;
  assign class_o[4] = ~sign & zero;
  assign class_o[5] = ~sign & denormal;
  assign class_o[6] = ~sign & (~infty) & (~denormal) & (~nan) & (~zero);
  assign class_o[7] = ~sign & infty;
  assign class_o[8] = sig_nan;
  assign class_o[9] = nan & ~sig_nan;

  assign class_o[out_width_lp-1:10] = '0;

endmodule
