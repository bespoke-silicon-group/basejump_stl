/**
 *  bsg_fpu_add_sub_n.v
 *
 *  parameterized floating-point adder/subtractor.
 *
 *  @author Tommy Jung
 */

module bsg_fpu_add_sub_n #( parameter e_p="inv"
                            ,parameter m_p="inv")
(
  input clk_i
  ,input rst_i
  ,input en_i
  ,input v_i
  ,input yumi_i
  ,input [e_p+m_p:0] a_i
  ,input [e_p+m_p:0] b_i
  ,input sub_i
  ,output logic v_o
  ,output logic ready_o
  ,output logic [e_p+m_p:0] z_o
  ,output logic unimplemented_o
  ,output logic invalid_o
  ,output logic overflow_o
  ,output logic underflow_o
  ,output logic wr_en_2_o
  ,output logic wr_en_3_o
);

  // pipeline states/signals
  logic v_1_r, v_2_r, v_3_r;
  logic v_1_n, v_2_n, v_3_n;

  // preprocessors
  logic a_zero, a_nan, a_sig_nan, a_infty, exp_a_zero, a_denormal;
  logic b_zero, b_nan, b_sig_nan, b_infty, exp_b_zero, b_denormal;
  logic sign_a, sign_b;
  logic [e_p-1:0] exp_a, exp_b;
  logic [m_p-1:0] man_a, man_b;

  bsg_fpu_preprocess #(.e_p(e_p), .m_p(m_p)) a_preprocess (
    .a_i(a_i)
    ,.zero_o(a_zero)
    ,.nan_o(a_nan)
    ,.sig_nan_o(a_sig_nan)
    ,.infty_o(a_infty)
    ,.exp_zero_o(exp_a_zero)
    ,.man_zero_o()
    ,.denormal_o(a_denormal)
    ,.sign_o(sign_a)
    ,.exp_o(exp_a)
    ,.man_o(man_a)
  );

  bsg_fpu_preprocess #(.e_p(e_p), .m_p(m_p)) b_preprocess (
    .a_i(b_i)
    ,.zero_o(b_zero)
    ,.nan_o(b_nan)
    ,.sig_nan_o(b_sig_nan)
    ,.infty_o(b_infty)
    ,.exp_zero_o(exp_b_zero)
    ,.man_zero_o()
    ,.denormal_o(b_denormal)
    ,.sign_o(sign_b)
    ,.exp_o(exp_b)
    ,.man_o(man_b)
  );

  // process exponents
  logic exp_a_less;
  logic [e_p-1:0] larger_exp;
  logic [e_p-1:0] exp_diff;
  bsg_less_than #(.width_p(e_p)) lt_exp (
    .a_i(exp_a)
    ,.b_i(exp_b)
    ,.o(exp_a_less)
  );

  assign larger_exp = (exp_a_less ? exp_b : exp_a) + 1'b1;

  assign exp_diff = exp_a_less 
    ? exp_b - exp_a
    : exp_a - exp_b;

  // hidden bit of mantissa
  // filtered out denormalized input
  logic [m_p:0] man_a_norm, man_b_norm;
  assign man_a_norm = {1'b1, man_a};
  assign man_b_norm = {1'b1, man_b};

  // which mantissa is the one of larger exp?
  logic [m_p:0] larger_exp_man, smaller_exp_man;
  assign larger_exp_man = exp_a_less ? man_b_norm : man_a_norm;
  assign smaller_exp_man = exp_a_less ? man_a_norm : man_b_norm;

  // determine sticky bit
  logic sticky;
  bsg_fpu_sticky #(.width_p(m_p+3)) sticky0 (
    .i({smaller_exp_man[m_p:0], 2'b0})
    ,.shamt_i(exp_diff[`BSG_WIDTH(m_p+3)-1:0])
    ,.sticky_o(sticky)
  );

  // determine final sign
  logic final_sign;
  logic mag_a_less;
  bsg_less_than #(.width_p(e_p+m_p)) lt_mag (
    .a_i(a_i[e_p+m_p-1:0])
    ,.b_i(b_i[e_p+m_p-1:0])
    ,.o(mag_a_less)
  );

  assign final_sign = (sign_a & ~mag_a_less)
    | (~sign_b & mag_a_less & sub_i)
    | (sign_b & mag_a_less & ~sub_i);

  // add or sub mantissa?
  logic do_sub;
  assign do_sub = sub_i ^ sign_a ^ sign_b;

  logic [m_p+3:0] larger_exp_man_padded;
  assign larger_exp_man_padded = {larger_exp_man, 3'b0};

  logic [m_p+3:0] smaller_exp_man_shifted;
  assign smaller_exp_man_shifted = {
    ({smaller_exp_man, 2'b0} >> exp_diff),
    sticky	
  };

  /////////// first pipeline stage /////////////////
  logic final_sign_1_r;
  logic do_sub_1_r;
  logic [e_p-1:0] larger_exp_1_r;
  logic [m_p+3:0] smaller_exp_man_shifted_1_r;
  logic [m_p+3:0] larger_exp_man_padded_1_r;
  logic a_sig_nan_1_r, b_sig_nan_1_r;
  logic a_nan_1_r, b_nan_1_r;
  logic a_infty_1_r, b_infty_1_r;
  logic a_denormal_1_r, b_denormal_1_r;

  logic final_sign_1_n;
  logic do_sub_1_n;
  logic [e_p:0] larger_exp_1_n;
  logic [m_p+3:0] smaller_exp_man_shifted_1_n;
  logic [m_p+3:0] larger_exp_man_padded_1_n;
  logic a_sig_nan_1_n, b_sig_nan_1_n;
  logic a_nan_1_n, b_nan_1_n;
  logic a_infty_1_n, b_infty_1_n;
  logic a_denormal_1_n, b_denormal_1_n;

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      v_1_r <= 0;
      final_sign_1_r <= 0;
      do_sub_1_r <= 0;
      larger_exp_1_r <= 0;
      smaller_exp_man_shifted_1_r <= 0;
      larger_exp_man_padded_1_r <= 0;
      a_sig_nan_1_r <= 0;
      b_sig_nan_1_r <= 0;
      a_nan_1_r <= 0;
      b_nan_1_r <= 0;
      a_infty_1_r <= 0;
      b_infty_1_r <= 0;
      a_denormal_1_r <= 0;
      b_denormal_1_r <= 0;
    end
    else begin
      v_1_r <= v_1_n;
      final_sign_1_r <= final_sign_1_n;
      do_sub_1_r <= do_sub_1_n;
      larger_exp_1_r <= larger_exp_1_n;
      smaller_exp_man_shifted_1_r <= smaller_exp_man_shifted_1_n;
      larger_exp_man_padded_1_r <= larger_exp_man_padded_1_n;
      a_sig_nan_1_r <= a_sig_nan_1_n;
      b_sig_nan_1_r <= b_sig_nan_1_n;
      a_nan_1_r <= a_nan_1_n;
      b_nan_1_r <= b_nan_1_n;
      a_infty_1_r <= a_infty_1_n;
      b_infty_1_r <= b_infty_1_n;
      a_denormal_1_r <= a_denormal_1_n;
      b_denormal_1_r <= b_denormal_1_n;
    end
  end

  always_comb begin
    ready_o = ((v_1_r & wr_en_2_o) | (~v_1_r)) & en_i;
    if (ready_o) begin
      v_1_n = v_i;
      final_sign_1_n = final_sign;
      do_sub_1_n = do_sub;
      larger_exp_1_n = larger_exp;
      smaller_exp_man_shifted_1_n = smaller_exp_man_shifted;
      larger_exp_man_padded_1_n = larger_exp_man_padded;
      a_sig_nan_1_n = a_sig_nan;
      b_sig_nan_1_n = b_sig_nan;
      a_nan_1_n = a_nan;
      b_nan_1_n = b_nan;
      a_infty_1_n = a_infty;
      b_infty_1_n = b_infty;
      a_denormal_1_n = a_denormal;
      b_denormal_1_n = b_denormal;
    end
    else begin
      v_1_n = v_1_r;
      final_sign_1_n = final_sign_1_r;
      do_sub_1_n = do_sub_1_r;
      larger_exp_1_n = larger_exp_1_r;
      smaller_exp_man_shifted_1_n = smaller_exp_man_shifted_1_r;
      larger_exp_man_padded_1_n = larger_exp_man_padded_1_r;
      a_sig_nan_1_n = a_sig_nan_1_r;
      b_sig_nan_1_n = b_sig_nan_1_r;
      a_nan_1_n = a_nan_1_r;
      b_nan_1_n = b_nan_1_r;
      a_infty_1_n = a_infty_1_r;
      b_infty_1_n = b_infty_1_r;
      a_denormal_1_n = a_denormal_1_r;
      b_denormal_1_n = b_denormal_1_r;
    end
  end

  //////////////////////////////////////////////////
 
  // which mantissa has smaller magnitude?
  logic larger_exp_man_less;
  bsg_less_than #(.width_p(m_p+4)) lt_man_norm (
    .a_i(larger_exp_man_padded_1_r)
    ,.b_i(smaller_exp_man_shifted_1_r)
    ,.o(larger_exp_man_less)
    );

  logic [m_p+3:0] larger_mag_man, smaller_mag_man;
  assign larger_mag_man = larger_exp_man_less
    ? smaller_exp_man_shifted_1_r
    : larger_exp_man_padded_1_r;
  assign smaller_mag_man = larger_exp_man_less 
    ? larger_exp_man_padded_1_r 
    : smaller_exp_man_shifted_1_r;


  // add or sub two mantissas
  logic [m_p+4:0] adder_output;
  assign adder_output = {1'b0, larger_mag_man}
    + {do_sub_1_r, ({(m_p+4){do_sub_1_r}} ^ smaller_mag_man)}
    + do_sub_1_r;


  /////////// second pipeline stage /////////////////
  logic [e_p-1:0] larger_exp_2_r;
  logic [m_p+4:0] adder_output_2_r;
  logic final_sign_2_r;
  logic a_sig_nan_2_r, b_sig_nan_2_r;
  logic a_nan_2_r, b_nan_2_r;
  logic a_infty_2_r, b_infty_2_r;
  logic do_sub_2_r;
  logic a_denormal_2_r, b_denormal_2_r;

  logic [e_p-1:0] larger_exp_2_n;
  logic [m_p+4:0] adder_output_2_n;
  logic final_sign_2_n;
  logic a_sig_nan_2_n, b_sig_nan_2_n;
  logic a_nan_2_n, b_nan_2_n;
  logic a_infty_2_n, b_infty_2_n;
  logic do_sub_2_n;
  logic a_denormal_2_n, b_denormal_2_n;

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      v_2_r <= 0;
      larger_exp_2_r <= 0;
      adder_output_2_r <= 0;
      final_sign_2_r <= 0;
      do_sub_2_r <= 0;
      a_sig_nan_2_r <= 0;
      b_sig_nan_2_r <= 0;
      a_nan_2_r <= 0;
      b_nan_2_r <= 0;
      a_infty_2_r <= 0;
      b_infty_2_r <= 0;
      a_denormal_2_r <= 0;
      b_denormal_2_r <= 0;	
    end
    else begin
      v_2_r <= v_2_n;
      larger_exp_2_r <= larger_exp_2_n;
      adder_output_2_r <= adder_output_2_n;
      final_sign_2_r <= final_sign_2_n;
      do_sub_2_r <= do_sub_2_n;
      a_sig_nan_2_r <= a_sig_nan_2_n;
      b_sig_nan_2_r <= b_sig_nan_2_n;
      a_nan_2_r <= a_nan_2_n;
      b_nan_2_r <= b_nan_2_n;
      a_infty_2_r <= a_infty_2_n;
      b_infty_2_r <= b_infty_2_n;
      a_denormal_2_r <= a_denormal_2_n;
      b_denormal_2_r <= b_denormal_2_n;
    end
  end

  always_comb begin
    wr_en_2_o = ((~v_2_r & v_1_r) | (v_2_r & wr_en_3_o)) & en_i; 
    if (wr_en_2_o) begin
      v_2_n = v_1_r;
      larger_exp_2_n = larger_exp_1_r;
      adder_output_2_n = adder_output;
      final_sign_2_n = final_sign_1_r;
      do_sub_2_n = do_sub_1_r;
      a_sig_nan_2_n = a_sig_nan_1_r;
      b_sig_nan_2_n = b_sig_nan_1_r;
      a_nan_2_n = a_nan_1_r;
      b_nan_2_n = b_nan_1_r;
      a_infty_2_n = a_infty_1_r;
      b_infty_2_n = b_infty_1_r;
      a_denormal_2_n = a_denormal_1_r;
      b_denormal_2_n = b_denormal_1_r;
    end
    else begin
      v_2_n = v_2_r;
      larger_exp_2_n = larger_exp_2_r;
      adder_output_2_n = adder_output_2_r;
      final_sign_2_n = final_sign_2_r;
      do_sub_2_n = do_sub_2_r;
      a_sig_nan_2_n = a_sig_nan_2_r;
      b_sig_nan_2_n = b_sig_nan_2_r;
      a_nan_2_n = a_nan_2_r;
      b_nan_2_n = b_nan_2_r;
      a_infty_2_n = a_infty_2_r;
      b_infty_2_n = b_infty_2_r;
      a_denormal_2_n = a_denormal_2_r;
      b_denormal_2_n = b_denormal_2_r;
    end
  end

  ///////////////////////////////////////////////////

  // count leading zero
  logic [`BSG_SAFE_CLOG2(m_p+5)-1:0] num_zero;
  logic reduce_o;
  logic all_zero;

  bsg_counting_leading_zeros #(.width_p(m_p+5)) clz
    (.a_i(adder_output_2_r)
    ,.num_zero_o(num_zero)
    );

  bsg_reduce  #(.width_p(m_p+5), .or_p(1)) reduce0 ( 
    .i(adder_output_2_r)
    ,.o(reduce_o)
    ); 

  assign all_zero = ~reduce_o;

  // shift adder output
  logic [m_p+4:0] shifted_adder_output;
  assign shifted_adder_output = all_zero
    ? (m_p+5)'(1'b0)
    : (adder_output_2_r << num_zero); // might not need mux here.

  // subtract from the larger exp by the amount the mantissa was shifted (number of leading zeros). 
  logic [e_p-1:0] adjusted_exp;
  logic adjusted_exp_cout;
  assign {adjusted_exp_cout, adjusted_exp} = larger_exp_2_r - num_zero; 

  // pre_roundup
  logic [e_p+m_p-1:0] pre_roundup;
  assign pre_roundup = {adjusted_exp, shifted_adder_output[4+:m_p]};

  // round up condition
  logic round_up;
  assign round_up = shifted_adder_output[3]
    & ((|shifted_adder_output[2:0]) | shifted_adder_output[4]); 

  /////////// third pipeline stage /////////////////
  logic [e_p+m_p-1:0] pre_roundup_3_r;
  logic round_up_3_r;
  logic all_zero_3_r;
  logic a_sig_nan_3_r, b_sig_nan_3_r;
  logic a_nan_3_r, b_nan_3_r;
  logic a_infty_3_r, b_infty_3_r;
  logic do_sub_3_r;
  logic a_denormal_3_r, b_denormal_3_r;
  logic adjusted_exp_cout_3_r;
  logic final_sign_3_r;

  logic [e_p+m_p-1:0] pre_roundup_3_n;
  logic round_up_3_n;
  logic all_zero_3_n;
  logic a_sig_nan_3_n, b_sig_nan_3_n;
  logic a_nan_3_n, b_nan_3_n;
  logic a_infty_3_n, b_infty_3_n;
  logic do_sub_3_n;
  logic a_denormal_3_n, b_denormal_3_n;
  logic adjusted_exp_cout_3_n;
  logic final_sign_3_n;

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      v_3_r <= 0;
      pre_roundup_3_r <= 0;
      round_up_3_r <= 0;
      all_zero_3_r <= 0;
      a_sig_nan_3_r <= 0;
      b_sig_nan_3_r <= 0;
      a_nan_3_r <= 0;
      b_nan_3_r <= 0;
      a_infty_3_r <= 0;
      b_infty_3_r <= 0;
      do_sub_3_r <= 0;
      a_denormal_3_r <= 0;
      b_denormal_3_r <= 0;
      adjusted_exp_cout_3_r <= 0;
      final_sign_3_r <= 0;
    end
    else begin
      v_3_r <= v_3_n;
      pre_roundup_3_r <= pre_roundup_3_n;
      round_up_3_r <= round_up_3_n;
      all_zero_3_r <= all_zero_3_n;
      a_sig_nan_3_r <= a_sig_nan_3_n;
      b_sig_nan_3_r <= b_sig_nan_3_n;
      a_nan_3_r <= a_nan_3_n;
      b_nan_3_r <= b_nan_3_n;
      a_infty_3_r <= a_infty_3_n;
      b_infty_3_r <= b_infty_3_n;
      do_sub_3_r <= do_sub_3_n;
      a_denormal_3_r <= a_denormal_3_n;
      b_denormal_3_r <= b_denormal_3_n;
      adjusted_exp_cout_3_r <= adjusted_exp_cout_3_n;
      final_sign_3_r <= final_sign_3_n;	
    end
  end

  always_comb begin
    v_o = v_3_r & en_i;
    wr_en_3_o = ((v_3_r & yumi_i) | (~v_3_r & ~yumi_i & v_2_r)) & en_i;
    if (wr_en_3_o) begin // take from previous pipeline
      v_3_n = v_2_r;
      pre_roundup_3_n = pre_roundup;
      round_up_3_n = round_up;
      all_zero_3_n = all_zero;
      a_sig_nan_3_n = a_sig_nan_2_r;
      b_sig_nan_3_n = b_sig_nan_2_r;
      a_nan_3_n = a_nan_2_r;
      b_nan_3_n = b_nan_2_r;
      a_infty_3_n = a_infty_2_r;
      b_infty_3_n = b_infty_2_r;
      do_sub_3_n = do_sub_2_r;
      a_denormal_3_n = a_denormal_2_r;
      b_denormal_3_n = b_denormal_2_r;
      adjusted_exp_cout_3_n = adjusted_exp_cout;
      final_sign_3_n = final_sign_2_r;
    end
    else begin // hold the pipeline
      v_3_n = v_3_r;
      pre_roundup_3_n = pre_roundup_3_r;
      round_up_3_n = round_up_3_r;
      all_zero_3_n = all_zero_3_r;
      a_sig_nan_3_n = a_sig_nan_3_r;
      b_sig_nan_3_n = b_sig_nan_3_r;
      a_nan_3_n = a_nan_3_r;
      b_nan_3_n = b_nan_3_r;
      a_infty_3_n = a_infty_3_r;
      b_infty_3_n = b_infty_3_r;
      do_sub_3_n = do_sub_3_r;
      a_denormal_3_n = a_denormal_3_r;
      b_denormal_3_n = b_denormal_3_r;
      adjusted_exp_cout_3_n = adjusted_exp_cout_3_r;
      final_sign_3_n = final_sign_3_r;
    end
  end

  //////////////////////////////////////////////////

  // carry going into exp when rounding up
  // (important for distinguishing between overflow and underflow)
  logic carry_into_exp;
  assign carry_into_exp = &{round_up_3_r, pre_roundup_3_r[m_p-1:0]};

  // round up for the final result
  logic [e_p+m_p-1:0] rounded;
  assign rounded = pre_roundup_3_r + round_up_3_r;

  // final output stage
  logic sgn;
  always_comb begin
    sgn = final_sign_3_r;

    if (a_sig_nan_3_r | b_sig_nan_3_r) begin
      unimplemented_o = 0;
      invalid_o = 1;
      overflow_o = 0;
      underflow_o = 0;
      z_o = `SIGNAN(sgn,e_p,m_p);
    end
    else if (a_nan_3_r | b_nan_3_r) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 0;
      z_o = `QUIETNAN(sgn,e_p,m_p);
    end
    else if (a_infty_3_r & b_infty_3_r) begin
      unimplemented_o = 0;
      invalid_o = do_sub_3_r;
      overflow_o = 0;
      underflow_o = 0;
      z_o = do_sub_3_r ? `QUIETNAN(sgn,e_p,m_p) : `INFTY(sgn,e_p,m_p);
    end
    else if (a_infty_3_r & ~b_infty_3_r) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 0;
      z_o = `INFTY(sgn,e_p,m_p);
    end
    else if (~a_infty_3_r & b_infty_3_r) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 0;
      z_o = `INFTY(sgn,e_p,m_p);
    end
    else if (a_denormal_3_r | b_denormal_3_r) begin
      unimplemented_o = 1;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 0;
      z_o =`QUIETNAN(sgn,e_p,m_p);
    end
    else if(all_zero_3_r) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 0;
      z_o = `ZERO(sgn,e_p,m_p);
    end
    else if (adjusted_exp_cout_3_r) begin
      unimplemented_o = 0;
      invalid_o = 0;
      overflow_o = 0;
      underflow_o = 1;
      z_o = `ZERO(sgn,e_p,m_p);
    end
    else begin
      if (pre_roundup_3_r[m_p+:e_p] == {e_p{1'b1}} & (pre_roundup_3_r[m_p] | carry_into_exp)) begin
        unimplemented_o = 0;
        invalid_o = 0;
        overflow_o = 1;
        underflow_o = 0;
        z_o =`INFTY(sgn,e_p,m_p);
      end
      else if (pre_roundup_3_r[m_p+:e_p] == {e_p{1'b0}} & ~carry_into_exp) begin
        unimplemented_o = 0;
        invalid_o = 0;
        overflow_o = 0;
        underflow_o = 1;
        z_o = `ZERO(sgn,e_p,m_p);
      end 
      else begin
        unimplemented_o = 0;
        invalid_o = 0;
        overflow_o = 0;
        underflow_o = 0;
        z_o = {sgn, rounded}; // happy case
      end
    end
  end

endmodule
