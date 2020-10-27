/**
 *  bsg_fpu_mul.v
 *  
 *  parameterized floating-point multiplier.
 *
 *  @author Tommy Jung
 */


`include "bsg_defines.v"

`include "bsg_fpu_defines.vh"

module bsg_fpu_mul
  #(parameter e_p="inv"   // exponent width
    , parameter m_p="inv" // mantissa width
  )
  (
    input clk_i
    , input reset_i
    , input en_i

    , input v_i
    , input [e_p+m_p:0] a_i
    , input [e_p+m_p:0] b_i
    , output logic ready_o

    , output logic v_o
    , output logic [e_p+m_p:0] z_o
    , output logic unimplemented_o
    , output logic invalid_o
    , output logic overflow_o
    , output logic underflow_o
    , input yumi_i // when yumi_i is high, en_i also has to be high
  );

  // pipeline states / signals
  logic v_1_r, v_2_r, v_3_r;
  logic stall;

  assign stall = v_3_r & ~yumi_i;
  assign v_o = v_3_r;
  assign ready_o = ~stall & en_i;

  // preprocessors
  logic a_zero, a_nan, a_sig_nan, a_infty, exp_a_zero, man_a_zero,
    a_denormal, sign_a;
  logic b_zero, b_nan, b_sig_nan, b_infty, exp_b_zero, man_b_zero,
    b_denormal, sign_b;
  logic [e_p-1:0] exp_a, exp_b;
  logic [m_p-1:0] man_a, man_b;

  bsg_fpu_preprocess #(
    .e_p(e_p)
    ,.m_p(m_p)
  ) a_preprocess (
    .a_i(a_i)
    ,.zero_o(a_zero)
    ,.nan_o(a_nan)
    ,.sig_nan_o(a_sig_nan)
    ,.infty_o(a_infty)
    ,.exp_zero_o(exp_a_zero)
    ,.man_zero_o(man_a_zero)
    ,.denormal_o(a_denormal)
    ,.sign_o(sign_a)
    ,.exp_o(exp_a)
    ,.man_o(man_a)
  );

  bsg_fpu_preprocess #(
    .e_p(e_p)
    ,.m_p(m_p)
  ) b_preprocess (
    .a_i(b_i)
    ,.zero_o(b_zero)
    ,.nan_o(b_nan)
    ,.sig_nan_o(b_sig_nan)
    ,.infty_o(b_infty)
    ,.exp_zero_o(exp_b_zero)
    ,.man_zero_o(man_b_zero)
    ,.denormal_o(b_denormal)
    ,.sign_o(sign_b)
    ,.exp_o(exp_b)
    ,.man_o(man_b)
  );

  // final sign
  logic final_sign;
  assign final_sign = sign_a ^ sign_b; 

  // add exponents together
  logic [e_p:0] exp_sum;
  assign exp_sum = {1'b0, exp_a} + {1'b0, exp_b} + 9'b1;

  // sum of exp with bias removed
  logic [e_p-1:0] exp_sum_unbiased;
  assign exp_sum_unbiased = {~exp_sum[e_p-1], exp_sum[e_p-2:0]};

  // normalized mantissa
  logic [m_p:0] man_a_norm, man_b_norm;
  assign man_a_norm = {1'b1, man_a};
  assign man_b_norm = {1'b1, man_b};

  /////////////// first pipeline stage ///////////////////////////////
  //
  logic final_sign_1_r;
  logic [e_p-1:0] exp_sum_unbiased_1_r;
  logic a_sig_nan_1_r, b_sig_nan_1_r;
  logic a_nan_1_r, b_nan_1_r;
  logic a_infty_1_r, b_infty_1_r;
  logic a_zero_1_r, b_zero_1_r;
  logic a_denormal_1_r, b_denormal_1_r;
  logic [e_p:0] exp_sum_1_r;
  logic [m_p:0] man_a_norm_r, man_b_norm_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_1_r <= 1'b0;
    end
    else begin
      if (~stall & en_i) begin
        v_1_r <= v_i;
        if (v_i) begin
          final_sign_1_r <= final_sign;
          exp_sum_unbiased_1_r <= exp_sum_unbiased;
          a_sig_nan_1_r <= a_sig_nan;
          b_sig_nan_1_r <= b_sig_nan;
          a_nan_1_r <= a_nan;
          b_nan_1_r <= b_nan;
          a_infty_1_r <= a_infty;
          b_infty_1_r <= b_infty;
          a_zero_1_r <= a_zero;
          b_zero_1_r <= b_zero;
          a_denormal_1_r <= a_denormal;
          b_denormal_1_r <= b_denormal;
          exp_sum_1_r <= exp_sum;
          man_a_norm_r <= man_a_norm;
          man_b_norm_r <= man_b_norm;
        end
      end
    end
  end

  //////////// second pipeline stage ///////////////////////////////

  // for single precision: 24-bit multiplier
  logic [((m_p+1)*2)-1:0] man_prod;

  bsg_mul_synth #(
    .width_p(m_p+1)
  ) mul_synth (
    .a_i(man_a_norm_r)
    ,.b_i(man_b_norm_r)
    ,.o(man_prod)	
  );

  logic [((m_p+1)*2)-1:0] man_prod_2_r;
  logic [e_p-1:0] exp_sum_unbiased_2_r;
  logic a_sig_nan_2_r, b_sig_nan_2_r;
  logic a_nan_2_r, b_nan_2_r;
  logic a_infty_2_r, b_infty_2_r;
  logic a_zero_2_r, b_zero_2_r;
  logic a_denormal_2_r, b_denormal_2_r;
  logic [e_p:0] exp_sum_2_r;
  logic final_sign_2_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_2_r <= 1'b0;
    end
    else begin
      if (~stall & en_i) begin
        v_2_r <= v_1_r;
        if (v_1_r) begin
          man_prod_2_r <= man_prod;
          exp_sum_unbiased_2_r <= exp_sum_unbiased_1_r;
          a_sig_nan_2_r <= a_sig_nan_1_r;
          b_sig_nan_2_r <= b_sig_nan_1_r;
          a_nan_2_r <= a_nan_1_r;
          b_nan_2_r <= b_nan_1_r;
          a_infty_2_r <= a_infty_1_r;
          b_infty_2_r <= b_infty_1_r;
          a_zero_2_r <= a_zero_1_r;
          b_zero_2_r <= b_zero_1_r;
          a_denormal_2_r <= a_denormal_1_r;
          b_denormal_2_r <= b_denormal_1_r;
          exp_sum_2_r <= exp_sum_1_r;
          final_sign_2_r <= final_sign_1_r;
        end
      end
    end
  end

  // lowers bits
  logic sticky, round, guard;
  assign sticky = |man_prod_2_r[m_p-2:0];
  assign round = man_prod_2_r[m_p-1];
  assign guard = man_prod_2_r[m_p];

  // round condition
  logic round_up;
  assign round_up = sticky
    ? (man_prod_2_r[(2*(m_p+1))-1] ? guard : round)
    : (guard & (round | (man_prod_2_r[(2*(m_p+1))-1] & man_prod_2_r[m_p+1]))); 


  // exp with additional carry bit from the product of mantissa added.
  logic [e_p:0] final_exp;
  assign final_exp = {1'b0, exp_sum_unbiased_2_r} + man_prod_2_r[(2*(m_p+1))-1];

  // mantissa also needs to be shifted if the product is larger than 2. 
  logic [m_p-1:0] shifted_mantissa;

  assign shifted_mantissa = man_prod_2_r[(2*(m_p+1))-1]
    ? man_prod_2_r[(m_p+1)+:m_p]
    : man_prod_2_r[m_p+:m_p];

  // pre_roundup;
  logic [e_p+m_p-1:0] pre_roundup;

  assign pre_roundup = {final_exp[e_p-1:0], shifted_mantissa};


  //////////// third pipeline stage ///////////////////////////////

  logic [e_p+m_p-1:0] pre_roundup_3_r;
  logic round_up_3_r;
  logic final_sign_3_r;
  logic a_sig_nan_3_r, b_sig_nan_3_r;
  logic a_nan_3_r, b_nan_3_r;
  logic a_infty_3_r, b_infty_3_r;
  logic a_zero_3_r, b_zero_3_r;
  logic a_denormal_3_r, b_denormal_3_r;
  logic [e_p:0] exp_sum_3_r;
  logic [e_p:0] final_exp_3_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_3_r <= 1'b0;
    end
    else begin
      if (~stall & en_i) begin
        v_3_r <= v_2_r;
        if (v_2_r) begin
          pre_roundup_3_r <= pre_roundup;
          round_up_3_r <= round_up;
          final_sign_3_r <= final_sign_2_r;
          a_sig_nan_3_r <= a_sig_nan_2_r;
          b_sig_nan_3_r <= b_sig_nan_2_r;
          a_nan_3_r <= a_nan_2_r;
          b_nan_3_r <= b_nan_2_r ;
          a_infty_3_r <= a_infty_2_r;
          b_infty_3_r <= b_infty_2_r;
          a_zero_3_r <= a_zero_2_r;
          b_zero_3_r <= b_zero_2_r;
          a_denormal_3_r <= a_denormal_2_r;
          b_denormal_3_r <= b_denormal_2_r;
          exp_sum_3_r <= exp_sum_2_r;
          final_exp_3_r <= final_exp;
        end
      end
    end
  end

  // carry going into exp when rounding up
  // (important for distinguishing between overflow and underflow)
  logic carry_into_exp;
  assign carry_into_exp = &{round_up_3_r, pre_roundup_3_r[m_p-1:0]};

  // round up for the final result. 
  logic round_overflow;
  logic [e_p+m_p-1:0] rounded;
  assign {round_overflow, rounded} = pre_roundup_3_r + round_up_3_r;

  // final output
  logic sgn;

  always_comb begin
    sgn = final_sign_3_r;

    if (a_sig_nan_3_r | b_sig_nan_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b1;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_SIGNAN(e_p,m_p); // sig nan
    end
    else if (a_nan_3_r | b_nan_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_QUIETNAN(e_p,m_p); // quiet nan
    end
    else if (a_infty_3_r) begin
      if (b_zero_3_r) begin
        unimplemented_o = 1'b0;
        invalid_o = 1'b1;
        overflow_o = 1'b0;
        underflow_o = 1'b0;
        z_o = `BSG_FPU_QUIETNAN(e_p,m_p); // quiet nan
      end
      else begin
        unimplemented_o = 1'b0;
        invalid_o = 1'b0;
        overflow_o = 1'b0;
        underflow_o = 1'b0;
        z_o = `BSG_FPU_INFTY(sgn,e_p,m_p); // infty 
      end
    end
    else if (b_infty_3_r) begin
      if (a_zero_3_r) begin
        unimplemented_o = 1'b0;
        invalid_o = 1'b1;
        overflow_o = 1'b0;
        underflow_o = 1'b0;
        z_o = `BSG_FPU_QUIETNAN(e_p,m_p); // quiet nan
      end
      else begin
        unimplemented_o = 1'b0;
        invalid_o = 1'b0;
        overflow_o = 1'b0;
        underflow_o = 1'b0;
        z_o = `BSG_FPU_INFTY(sgn,e_p,m_p); // infty 
      end
    end
    else if (a_zero_3_r | b_zero_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_ZERO(sgn,e_p,m_p); // zero
    end
    else if (a_denormal_3_r & b_denormal_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b1;
      z_o = `BSG_FPU_ZERO(sgn,e_p,m_p); // zero
    end
    else if (a_denormal_3_r | b_denormal_3_r) begin
      unimplemented_o = 1'b1;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_QUIETNAN(e_p,m_p); // quiet nan
    end
    else if (exp_sum_3_r[(e_p-1)+:2] == 2'b0) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b1;
      z_o = `BSG_FPU_ZERO(sgn,e_p,m_p); // zero
    end
    else if (exp_sum_3_r[(e_p-1)+:2] == 2'b11 | final_exp_3_r[e_p]) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b1;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_INFTY(sgn,e_p,m_p); // infty 
    end
    else begin 
      if (pre_roundup_3_r[m_p+:e_p] == {e_p{1'b1}} & (pre_roundup_3_r[m_p] | carry_into_exp)) begin
        unimplemented_o = 1'b0;
        invalid_o = 1'b0;
        overflow_o = 1'b1;
        underflow_o = 1'b0;
        z_o = `BSG_FPU_INFTY(sgn,e_p,m_p); // infty 
      end
      else if (pre_roundup_3_r[m_p+:e_p] == {e_p{1'b0}} & ~carry_into_exp) begin
        unimplemented_o = 1'b0;
        invalid_o = 1'b0;
        overflow_o = 1'b0;
        underflow_o = 1'b1;
        z_o = `BSG_FPU_ZERO(sgn,e_p,m_p); // zero
      end 
      else begin
        unimplemented_o = 1'b0;
        invalid_o = 1'b0;
        overflow_o = 1'b0;
        underflow_o = 1'b0;
        z_o = {sgn, rounded}; // happy case
      end
    end
  end

endmodule
