/**
 *  bsg_fpu_f2i_n.v
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

module bsg_fpu_f2i_n
  import bsg_fpu_pkg::*;
  #(parameter e_p="inv"
    , parameter m_p="inv"

    , localparam width_lp=(e_p+m_p+1)
    , localparam bias_lp={1'b0, {(e_p-1){1'b1}}}
  )
  (
    input clk_i
    , input reset_i
    , input en_i

    , input v_i
    , input [width_lp-1:0] a_i // input float
    , input signed_i
    , output logic ready_o

    , output logic v_o
    , output logic [width_lp-1:0] z_o // output int
    , output logic invalid_o
    , input yumi_i
  );

  // pipeline status / ctrl
  //
  logic v_1_r;
  logic stall;

  assign v_o = v_1_r;
  assign stall = v_1_r & ~yumi_i;
  assign ready_o = en_i & ~stall;

  // preprocess
  //
  logic sign;
  logic [e_p-1:0] exp;
  logic [m_p-1:0] mantissa;
  logic zero;
  logic nan;
  
  bsg_fpu_preprocess #(
    .e_p(e_p)
    ,.m_p(m_p)
  ) preprocess (
    .a_i(a_i)
    ,.zero_o(zero)
    ,.nan_o(nan)
    ,.sig_nan_o()
    ,.infty_o()
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
    ? (bias_lp+width_lp-2) - exp
    : (bias_lp+width_lp-1) - exp;

  assign shifted = preshift >> shamt[`BSG_SAFE_CLOG2(width_lp):0];


  // invert
  //
  logic [width_lp-1:0] inverted;
  assign inverted = {width_lp{signed_i & sign}} ^ {shifted};

  //// first pipeline stage ///////////////////////////

  logic [width_lp-1:0] inverted_1_r;
  logic sign_1_r;
  logic signed_1_r;
  logic zero_1_r;
  logic nan_1_r;
  logic exp_too_big_1_r;
  logic exp_too_small_1_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_1_r <= 1'b0;
    end
    else begin
      if (ready_o) begin
        v_1_r <= v_i;
        if (v_i) begin
          inverted_1_r <= inverted;
          sign_1_r <= sign;
          signed_1_r <= signed_i;
          zero_1_r <= zero;
          nan_1_r <= nan;
          exp_too_big_1_r <= exp_too_big;
          exp_too_small_1_r <= exp_too_small;
        end
      end
    end
  end

  /////////////////////////////////////////////////////

  logic [width_lp-1:0] post_round;
  assign post_round = inverted_1_r + (sign_1_r);

  always_comb begin
    if (~signed_1_r & sign_1_r) begin
      z_o = '0;
      invalid_o = 1'b1;
    end
    else if (zero_1_r) begin
      z_o = '0;
      invalid_o = 1'b0;
    end
    else if (exp_too_big_1_r) begin
      z_o = '0;
      invalid_o = 1'b1;
    end
    else if (exp_too_small_1_r) begin
      z_o = '0;
      invalid_o = 1'b0;
    end
    else if (nan_1_r) begin
      z_o = '0;
      invalid_o = 1'b1;
    end
    else begin
      z_o = post_round;
      invalid_o = 1'b0;
    end
  end

endmodule
