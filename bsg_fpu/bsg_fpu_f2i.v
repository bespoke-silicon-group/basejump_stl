/**
 *  bsg_fpu_f2i.v
 *
 *  @author Tommy Jung
 *
 *  Parameterized float-to-int converter.
 *  It supports conversion to signed or unsigned int.
 *
 *  If the input float is negative, and the target is unsigned int 
 *  then the output is set to zero, and invalid flag is raised.
 *
 *  If the input float is too big (exp out of range), 
 *  then the output is set to zero, and invalid flag is raised. 
 *  
 *  Casting float to int should drop the fractional part, instead of 
 *  rounding up.
 *
 */

`include "bsg_defines.v"

`include "bsg_fpu_defines.vh"

module bsg_fpu_f2i
  #(parameter e_p="inv"
    , parameter m_p="inv"

    , localparam width_lp=(e_p+m_p+1)
    , localparam bias_lp={1'b0, {(e_p-1){1'b1}}}
  )
  (
    input [width_lp-1:0] a_i // input float
    , input signed_i

    , output logic [width_lp-1:0] z_o // output int
    , output logic invalid_o
  );


  // preprocess
  //
  logic sign;
  logic [e_p-1:0] exp;
  logic [m_p-1:0] mantissa;
  logic zero;
  logic nan;
  logic infty;
  
  bsg_fpu_preprocess #(
    .e_p(e_p)
    ,.m_p(m_p)
  ) preprocess (
    .a_i(a_i)
    ,.zero_o(zero)
    ,.nan_o(nan)
    ,.sig_nan_o()
    ,.infty_o(infty)
    ,.exp_zero_o()
    ,.man_zero_o()
    ,.denormal_o()
    ,.sign_o(sign)
    ,.exp_o(exp)
    ,.man_o(mantissa)
  );

  // determine if exp is in range
  //
  logic exp_too_big;
  logic exp_too_small;

  assign exp_too_big = signed_i
    ? (exp > (bias_lp+width_lp-2))
    : (exp > (bias_lp+width_lp-1));
    //? (exp > 8'd157)
    //: (exp > 8'd158);
  assign exp_too_small = exp < bias_lp; 

  // determine shift amount
  //
  logic [width_lp-1:0] preshift;
  logic [e_p-1:0] shamt;
  logic [width_lp-1:0] shifted;

  assign preshift = signed_i
    ? {1'b0, 1'b1, mantissa, {(width_lp-2-m_p){1'b0}}}
    : {1'b1, mantissa, {(width_lp-1-m_p){1'b0}}};

  assign shamt = signed_i
    ? (e_p)'((bias_lp+width_lp-2) - exp)
    : (e_p)'((bias_lp+width_lp-1) - exp);

  assign shifted = preshift >> shamt[`BSG_SAFE_CLOG2(width_lp):0];


  // invert
  //
  logic [width_lp-1:0] inverted;
  logic [width_lp-1:0] post_round;

  assign inverted = {width_lp{signed_i & sign}} ^ {shifted};
  assign post_round = inverted + (sign);

  always_comb begin

    if (nan) begin
      z_o = signed_i
        ? {1'b0, {(width_lp-1){1'b1}}}
        : {(width_lp){1'b1}};
      invalid_o = 1'b1;
    end
    else if (infty) begin
      //  neg_infty 
      //    signed   = 32'b80000000
      //    unsigned = 32'b00000000
      //  pos_infty
      //    signed   = 32'b7fffffff
      //    unsigned = 32'bffffffff
      z_o = sign
        ? {signed_i, {(width_lp-1){1'b0}}}
        : {~signed_i, {(width_lp-1){1'b1}}};
      invalid_o = 1'b1;
    end
    else if (~signed_i & sign) begin
      z_o = '0;
      invalid_o = 1'b1;
    end
    else if (zero) begin
      z_o = '0;
      invalid_o = 1'b0;
    end
    else if (exp_too_big) begin
      z_o = sign
        ? {1'b1, {(width_lp-1){1'b0}}}
        : {1'b0, {(width_lp-1){1'b1}}};
      invalid_o = 1'b1;
    end
    else if (exp_too_small) begin
      z_o = '0;
      invalid_o = 1'b0;
    end
    else begin
      z_o = post_round;
      invalid_o = 1'b0;
    end
  end

endmodule
