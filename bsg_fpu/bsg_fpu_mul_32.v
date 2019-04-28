/**
 *  bsg_fpu_mul_32.v
 *  
 *  32-bit floating-point multiplier.
 *
 *  @author Tommy Jung
 */

module bsg_fpu_mul_32
  ( input clk_i
    , input rst_i
    , input en_i
    , input v_i
    , input yumi_i
    , input [31:0] a_i
    ,	input [31:0] b_i
    , output logic ready_o
    ,	output logic v_o
    , output logic [31:0] z_o
    , output logic unimplemented_o
    , output logic invalid_o
    ,	output logic overflow_o
    , output logic underflow_o
    , output logic wr_en_2_o
    , output logic wr_en_3_o
    );

  // pipeline states / signals
  logic v_1_r, v_2_r, v_3_r;
  logic v_1_n, v_2_n, v_3_n;

  // preprocessors
  logic a_zero, a_nan, a_sig_nan, a_infty, exp_a_zero, man_a_zero,
    a_denormal, sign_a;
  logic b_zero, b_nan, b_sig_nan, b_infty, exp_b_zero, man_b_zero,
    b_denormal, sign_b;
  logic [7:0] exp_a, exp_b;
  logic [22:0] man_a, man_b;

  bsg_fpu_preprocess #(.e_p(8)
                      ,.m_p(23))
    a_preprocess (.a_i(a_i)
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

  bsg_fpu_preprocess #(.e_p(8)
                      ,.m_p(23))
    b_preprocess (.a_i(b_i)
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
  logic [8:0] exp_sum;
  assign exp_sum = {1'b0, exp_a} + {1'b0, exp_b} + 9'b1;

  // sum of exp with bias removed
  logic [7:0] exp_sum_unbiased;
  assign exp_sum_unbiased = {~exp_sum[7], exp_sum[6:0]};

  // normalized mantissa
  logic [23:0] man_a_norm, man_b_norm;
  assign man_a_norm = {1'b1, man_a};
  assign man_b_norm = {1'b1, man_b};

  /////////////// first pipeline stage ///////////////////////////////
  logic final_sign_1_r;
  logic [7:0] exp_sum_unbiased_1_r;
  logic a_sig_nan_1_r, b_sig_nan_1_r;
  logic a_nan_1_r, b_nan_1_r;
  logic a_infty_1_r, b_infty_1_r;
  logic a_zero_1_r, b_zero_1_r;
  logic a_denormal_1_r, b_denormal_1_r;
  logic [8:0] exp_sum_1_r;
  logic [23:0] man_a_norm_r, man_b_norm_r;

  logic final_sign_1_n;
  logic [7:0] exp_sum_unbiased_1_n;
  logic a_sig_nan_1_n, b_sig_nan_1_n;
  logic a_nan_1_n, b_nan_1_n;
  logic a_infty_1_n, b_infty_1_n;
  logic a_zero_1_n, b_zero_1_n;
  logic a_denormal_1_n, b_denormal_1_n;
  logic [8:0] exp_sum_1_n;
  logic [23:0] man_a_norm_n, man_b_norm_n;


  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      v_1_r <= 0;
      final_sign_1_r <= 0;
      exp_sum_unbiased_1_r <= 0;
      a_sig_nan_1_r <= 0;
      b_sig_nan_1_r <= 0;
      a_nan_1_r <= 0;
      b_nan_1_r <= 0;
      a_infty_1_r <= 0;
      b_infty_1_r <= 0;
      a_zero_1_r <= 0;
      b_zero_1_r <= 0;
      a_denormal_1_r <= 0;
      b_denormal_1_r <= 0;
      exp_sum_1_r <= 0;
    end
    else begin
      v_1_r <= v_1_n;
      final_sign_1_r <= final_sign_1_n;
      exp_sum_unbiased_1_r <= exp_sum_unbiased_1_n;
      a_sig_nan_1_r <= a_sig_nan_1_n;
      b_sig_nan_1_r <= b_sig_nan_1_n;
      a_nan_1_r <= a_nan_1_n;
      b_nan_1_r <= b_nan_1_n;
      a_infty_1_r <= a_infty_1_n;
      b_infty_1_r <= b_infty_1_n;
      a_zero_1_r <= a_zero_1_n;
      b_zero_1_r <= b_zero_1_n;
      a_denormal_1_r <= a_denormal_1_n;
      b_denormal_1_r <= b_denormal_1_n;
      exp_sum_1_r <= exp_sum_1_n;
      man_a_norm_r <= man_a_norm_n;
      man_b_norm_r <= man_b_norm_n;
    end
  end

  always_comb begin
    ready_o = ((v_1_r & wr_en_2_o) | (~v_1_r)) & en_i;
    if (ready_o) begin
      v_1_n = v_i;
      final_sign_1_n = final_sign;
      exp_sum_unbiased_1_n = exp_sum_unbiased;
      a_sig_nan_1_n = a_sig_nan;
      b_sig_nan_1_n = b_sig_nan;
      a_nan_1_n = a_nan;
      b_nan_1_n = b_nan;
      a_infty_1_n = a_infty;
      b_infty_1_n = b_infty;
      a_zero_1_n = a_zero;
      b_zero_1_n = b_zero;
      a_denormal_1_n = a_denormal;
      b_denormal_1_n = b_denormal;
      exp_sum_1_n = exp_sum;
      man_a_norm_n = man_a_norm;
      man_b_norm_n = man_b_norm;
    end
    else begin
      v_1_n = v_1_r;
      final_sign_1_n = final_sign_1_r;
      exp_sum_unbiased_1_n = exp_sum_unbiased_1_r;
      a_sig_nan_1_n = a_sig_nan_1_r;
      b_sig_nan_1_n = b_sig_nan_1_r;
      a_nan_1_n = a_nan_1_r;
      b_nan_1_n = b_nan_1_r;
      a_infty_1_n = a_infty_1_r;
      b_infty_1_n = b_infty_1_r;
      a_zero_1_n = a_zero_1_r;
      b_zero_1_n = b_zero_1_r;
      a_denormal_1_n = a_denormal_1_r;
      b_denormal_1_n = b_denormal_1_r;
      exp_sum_1_n = exp_sum_1_r;
      man_a_norm_n = man_a_norm_r;
      man_b_norm_n = man_b_norm_r;
    end
  end

  ////////////////////////////////////////////////////////////////////


  //////////// second pipeline stage ///////////////////////////////
  // 24-bit multiplier
  logic [47:0] man_prod;

  bsg_mul_synth #(
    .width_p(24)
  ) mul_array (
    .a_i(man_a_norm_r)
    ,.b_i(man_b_norm_r)
    ,.o(man_prod)	
  );

  logic [47:0] man_prod_2_r;
  logic [7:0] exp_sum_unbiased_2_r;
  logic a_sig_nan_2_r, b_sig_nan_2_r;
  logic a_nan_2_r, b_nan_2_r;
  logic a_infty_2_r, b_infty_2_r;
  logic a_zero_2_r, b_zero_2_r;
  logic a_denormal_2_r, b_denormal_2_r;
  logic [8:0] exp_sum_2_r;
  logic final_sign_2_r;

  logic [47:0] man_prod_2_n;
  logic [7:0] exp_sum_unbiased_2_n;
  logic a_sig_nan_2_n, b_sig_nan_2_n;
  logic a_nan_2_n, b_nan_2_n;
  logic a_infty_2_n, b_infty_2_n;
  logic a_zero_2_n, b_zero_2_n;
  logic a_denormal_2_n, b_denormal_2_n;
  logic [8:0] exp_sum_2_n;
  logic final_sign_2_n;

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      v_2_r <= 0;
      man_prod_2_r <= 0;
      exp_sum_unbiased_2_r <= 0;
      a_sig_nan_2_r <= 0;
      b_sig_nan_2_r <= 0;
      a_nan_2_r <= 0;
      b_nan_2_r <= 0;
      a_infty_2_r <= 0;
      b_infty_2_r <= 0;
      a_zero_2_r <= 0;
      b_zero_2_r <= 0;
      a_denormal_2_r <= 0;
      b_denormal_2_r <= 0;
      exp_sum_2_r <= 0;
      final_sign_2_r <= 0;
    end
    else begin
      v_2_r <= v_2_n;
      man_prod_2_r <= man_prod_2_n;
      exp_sum_unbiased_2_r <= exp_sum_unbiased_2_n;
      a_sig_nan_2_r <= a_sig_nan_2_n;
      b_sig_nan_2_r <= b_sig_nan_2_n;
      a_nan_2_r <= a_nan_2_n;
      b_nan_2_r <= b_nan_2_n;
      a_infty_2_r <= a_infty_2_n;
      b_infty_2_r <= b_infty_2_n;
      a_zero_2_r <= a_zero_2_n;
      b_zero_2_r <= b_zero_2_n;
      a_denormal_2_r <= a_denormal_2_n;
      b_denormal_2_r <= b_denormal_2_n;
      exp_sum_2_r <= exp_sum_2_n;
      final_sign_2_r <= final_sign_2_n;
    end
  end

  always_comb begin
    wr_en_2_o = ((~v_2_r & v_1_r) | (v_2_r & wr_en_3_o)) & en_i; 
    if (wr_en_2_o) begin
      v_2_n = v_1_r;
      man_prod_2_n = man_prod;
      exp_sum_unbiased_2_n = exp_sum_unbiased_1_r;
      a_sig_nan_2_n = a_sig_nan_1_r;
      b_sig_nan_2_n = b_sig_nan_1_r;
      a_nan_2_n = a_nan_1_r;
      b_nan_2_n = b_nan_1_r;
      a_infty_2_n = a_infty_1_r;
      b_infty_2_n = b_infty_1_r;
      a_zero_2_n = a_zero_1_r;
      b_zero_2_n = b_zero_1_r;
      a_denormal_2_n = a_denormal_1_r;
      b_denormal_2_n = b_denormal_1_r;
      exp_sum_2_n = exp_sum_1_r;
      final_sign_2_n = final_sign_1_r;
    end
    else begin
      v_2_n = v_2_r;
      man_prod_2_n = man_prod_2_r;
      exp_sum_unbiased_2_n = exp_sum_unbiased_2_r;
      a_sig_nan_2_n = a_sig_nan_2_r;
      b_sig_nan_2_n = b_sig_nan_2_r;
      a_nan_2_n = a_nan_2_r;
      b_nan_2_n = b_nan_2_r;
      a_infty_2_n = a_infty_2_r;
      b_infty_2_n = b_infty_2_r;
      a_zero_2_n = a_zero_2_r;
      b_zero_2_n = b_zero_2_r;
      a_denormal_2_n = a_denormal_2_r;
      b_denormal_2_n = b_denormal_2_r;
      exp_sum_2_n = exp_sum_2_r;
      final_sign_2_n = final_sign_2_r;
    end
  end

  //////////////////////////////////////////////////////////////////

  // lowers bits
  logic sticky, round, guard;
  assign sticky = |man_prod_2_r[21:0];
  assign round = man_prod_2_r[22];
  assign guard = man_prod_2_r[23];

  // round condition
  logic round_up;
  assign round_up = sticky
    ? (man_prod_2_r[47] ? guard : round)
    : (guard & (round | (man_prod_2_r[47] & man_prod_2_r[24]))); 


  // exp with additional carry bit from the product of mantissa added.
  logic [8:0] final_exp;
  assign final_exp = {1'b0, exp_sum_unbiased_2_r} + {8'b0, man_prod_2_r[47]};

  // mantissa also needs to be shifted if the product is larger than 2. 
  logic [22:0] shifted_mantissa;
  assign shifted_mantissa = man_prod_2_r[47] ? man_prod_2_r[46:24] : man_prod_2_r[45:23];

  // pre_roundup;
  logic [30:0] pre_roundup;
  assign pre_roundup = {final_exp[7:0], shifted_mantissa};


  //////////// third pipeline stage ///////////////////////////////

  logic [30:0] pre_roundup_3_r;
  logic round_up_3_r;
  logic final_sign_3_r;
  logic a_sig_nan_3_r, b_sig_nan_3_r;
  logic a_nan_3_r, b_nan_3_r;
  logic a_infty_3_r, b_infty_3_r;
  logic a_zero_3_r, b_zero_3_r;
  logic a_denormal_3_r, b_denormal_3_r;
  logic [8:0] exp_sum_3_r;
  logic [8:0] final_exp_3_r;

  logic [30:0] pre_roundup_3_n;
  logic round_up_3_n;
  logic final_sign_3_n;
  logic a_sig_nan_3_n, b_sig_nan_3_n;
  logic a_nan_3_n, b_nan_3_n;
  logic a_infty_3_n, b_infty_3_n;
  logic a_zero_3_n, b_zero_3_n;
  logic a_denormal_3_n, b_denormal_3_n;
  logic [8:0] exp_sum_3_n;
  logic [8:0] final_exp_3_n;

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      v_3_r <= 0;
      pre_roundup_3_r <= 0;
      round_up_3_r <= 0;
      final_sign_3_r <= 0;
      a_sig_nan_3_r <= 0;
      b_sig_nan_3_r <= 0;
      a_nan_3_r <= 0;
      b_nan_3_r <= 0;
      a_infty_3_r <= 0;
      b_infty_3_r <= 0;
      a_zero_3_r <= 0;
      b_zero_3_r <= 0;
      a_denormal_3_r <= 0;
      b_denormal_3_r <= 0;
      exp_sum_3_r <= 0;
      final_exp_3_r <= 0;
    end
    else begin
      v_3_r <= v_3_n;
      pre_roundup_3_r <= pre_roundup_3_n;
      round_up_3_r <= round_up_3_n;
      final_sign_3_r <= final_sign_3_n;
      a_sig_nan_3_r <= a_sig_nan_3_n;
      b_sig_nan_3_r <= b_sig_nan_3_n;
      a_nan_3_r <= a_nan_3_n;
      b_nan_3_r <= b_nan_3_n ;
      a_infty_3_r <= a_infty_3_n;
      b_infty_3_r <= b_infty_3_n;
      a_zero_3_r <= a_zero_3_n;
      b_zero_3_r <= b_zero_3_n;
      a_denormal_3_r <= a_denormal_3_n;
      b_denormal_3_r <= b_denormal_3_n;
      exp_sum_3_r <= exp_sum_3_n;
      final_exp_3_r <= final_exp_3_n;
    end
  end

  always_comb begin
    v_o = v_3_r & en_i;
    wr_en_3_o = ((v_3_r & yumi_i) | (~v_3_r & ~yumi_i & v_2_r)) & en_i;
    if (wr_en_3_o) begin
      v_3_n = v_2_r;
      pre_roundup_3_n = pre_roundup;
      round_up_3_n = round_up;
      final_sign_3_n = final_sign_2_r;
      a_sig_nan_3_n = a_sig_nan_2_r;
      b_sig_nan_3_n = b_sig_nan_2_r;
      a_nan_3_n = a_nan_2_r;
      b_nan_3_n = b_nan_2_r ;
      a_infty_3_n = a_infty_2_r;
      b_infty_3_n = b_infty_2_r;
      a_zero_3_n = a_zero_2_r;
      b_zero_3_n = b_zero_2_r;
      a_denormal_3_n = a_denormal_2_r;
      b_denormal_3_n = b_denormal_2_r;
      exp_sum_3_n = exp_sum_2_r;
      final_exp_3_n = final_exp;
    end
    else begin
      v_3_n = v_3_r;
      pre_roundup_3_n = pre_roundup_3_r;
      round_up_3_n = round_up_3_r;
      final_sign_3_n = final_sign_3_r;
      a_sig_nan_3_n = a_sig_nan_3_r;
      b_sig_nan_3_n = b_sig_nan_3_r;
      a_nan_3_n = a_nan_3_r;
      b_nan_3_n = b_nan_3_r ;
      a_infty_3_n = a_infty_3_r;
      b_infty_3_n = b_infty_3_r;
      a_zero_3_n = a_zero_3_r;
      b_zero_3_n = b_zero_3_r;
      a_denormal_3_n = a_denormal_3_r;
      b_denormal_3_n = b_denormal_3_r;
      exp_sum_3_n = exp_sum_3_r;
      final_exp_3_n = final_exp_3_r;
    end
  end

  /////////////////////////////////////////////////////////////////

  // carry going into exp when rounding up
  // (important for distinguishing between overflow and underflow)
  logic carry_into_exp;
  assign carry_into_exp = &{round_up_3_r, pre_roundup_3_r[22:0]};

  // round up for the final result. 
  logic round_overflow;
  logic [30:0] rounded;
  assign {round_overflow, rounded} = pre_roundup_3_r + {30'b0, round_up_3_r};

  // final output
  always_comb begin
    z_o[31] = final_sign_3_r;	
    if (a_sig_nan_3_r | b_sig_nan_3_r) begin
      unimplemented_o = 0;
      invalid_o = 1;
      overflow_o = 0;
      underflow_o = 0;
      z_o[30:0] = {8'hff, 23'h3fffff}; // sig nan
    end
    else if (a_nan_3_r | b_nan_3_r) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 0;
      z_o[30:0] = {8'hff, 23'h7fffff}; // quiet nan
    end
    else if (a_infty_3_r) begin
      if (b_zero_3_r) begin
        unimplemented_o = 0;
        invalid_o = 1;
        overflow_o = 0;
        underflow_o = 0;
        z_o[30:0] = {8'hff, 23'h7fffff}; // quiet nan
      end
      else begin
        unimplemented_o = 0;
        invalid_o = 0;
        overflow_o = 0;
        underflow_o = 0;
        z_o[30:0] = {8'hff, 23'h0}; // infty 
      end
    end
    else if (b_infty_3_r) begin
      if (a_zero_3_r) begin
        unimplemented_o = 0;
        invalid_o = 1;
        overflow_o = 0;
        underflow_o = 0;
        z_o[30:0] = {8'hff, 23'h7fffff}; // quiet nan
      end
      else begin
        unimplemented_o = 0;
        invalid_o = 0;
        overflow_o = 0;
        underflow_o = 0;
        z_o[30:0] = {8'hff, 23'h0}; // infty 
      end
    end
    else if (a_zero_3_r | b_zero_3_r) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 0;
      z_o[30:0] = 31'b0; // zero
    end
    else if (a_denormal_3_r & b_denormal_3_r) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 1;
      z_o[30:0] = 31'b0; // zero
    end
    else if (a_denormal_3_r | b_denormal_3_r) begin
      unimplemented_o = 1;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 0;
      z_o[30:0] = {8'hff, 23'h7fffff}; // quiet nan
    end
    else if (exp_sum_3_r[8:7] == 2'b0) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 1;
      z_o[30:0] = 31'b0; // zero
    end
    else if (exp_sum_3_r[8:7] == 2'b11 | final_exp_3_r[8]) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 1;
      underflow_o = 0;
      z_o[30:0] = {8'hff, 23'h0}; // infty 
    end
    else begin 
      if (pre_roundup_3_r[30:23] == 8'hff & (pre_roundup_3_r[23] | carry_into_exp)) begin
        unimplemented_o = 0;
        invalid_o = 0;
        overflow_o = 1;
        underflow_o = 0;
        z_o[30:0] = {8'hff, 23'h0}; // infty 
      end
      else if (pre_roundup_3_r[30:23] == 8'b0 & ~carry_into_exp) begin
        unimplemented_o = 0;
        invalid_o = 0;
        overflow_o = 0;
        underflow_o = 1;
        z_o[30:0] = 31'b0; // zero
      end 
      else begin
        unimplemented_o = 0;
        invalid_o = 0;
        overflow_o = 0;
        underflow_o = 0;
        z_o[30:0] = rounded; // happy case
      end
    end
  end

endmodule
