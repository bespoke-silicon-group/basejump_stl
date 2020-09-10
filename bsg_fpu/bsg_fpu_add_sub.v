/**
 *  bsg_fpu_add_sub.v
 *
 *  @author tommy
 *
 *  parameterized floating-point adder/subtractor.
 *
 */

`include "bsg_defines.v"

`include "bsg_fpu_defines.vh"

module bsg_fpu_add_sub
  #(parameter e_p="inv"     // exponent width
    , parameter m_p="inv"   // mantissa width
  )
  (
    input clk_i
    , input reset_i
    , input en_i  // enable

    , input v_i
    , input [e_p+m_p:0] a_i
    , input [e_p+m_p:0] b_i
    , input sub_i
    , output logic ready_o

    , output logic v_o
    , output logic [e_p+m_p:0] z_o
    , output logic unimplemented_o
    , output logic invalid_o
    , output logic overflow_o
    , output logic underflow_o
    , input yumi_i // when yumi_i is high, en_i also has to be high
  );

  // pipeline states/signals
  logic v_1_r, v_2_r, v_3_r;
  logic stall;

  assign stall = v_3_r & ~yumi_i;
  assign v_o = v_3_r;
  assign ready_o = ~stall & en_i;

  // preprocessors
  logic a_zero, a_nan, a_sig_nan, a_infty, exp_a_zero, a_denormal;
  logic b_zero, b_nan, b_sig_nan, b_infty, exp_b_zero, b_denormal;
  logic sign_a, sign_b;
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
    ,.man_zero_o()
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
    ,.man_zero_o()
    ,.denormal_o(b_denormal)
    ,.sign_o(sign_b)
    ,.exp_o(exp_b)
    ,.man_o(man_b)
  );

  // process exponents
  logic exp_a_less;
  logic [e_p-1:0] larger_exp;
  (* keep = "true" *) logic [e_p-1:0] exp_diff;

  bsg_less_than #(
    .width_p(e_p)
  ) lt_exp (
    .a_i(exp_a)
    ,.b_i(exp_b)
    ,.o(exp_a_less)
  );

  assign larger_exp = (exp_a_less ? exp_b : exp_a) + 1'b1;

  // The following KEEP attribute prevents the following warning in the Xilinx
  // toolchain. It may stop the tool from inferring a timing loop in the FPU: 
  // [Synth 8-5818] HDL ADVISOR - The operator resource <adder> is
  // shared. To prevent sharing consider applying a KEEP on the output of the
  // operator [<path>/bsg_fpu_add_sub.v:104]. (Xilinx Vivado 2018.2)
  (* keep = "true" *) logic [e_p-1:0] diff_ab, diff_ba;

  assign diff_ab = exp_a - exp_b;
  assign diff_ba = exp_b - exp_a;
    
  assign exp_diff = exp_a_less ? diff_ba : diff_ab;
    
  // hidden bit of mantissa
  // filtered out denormalized input
  logic [m_p:0] man_a_norm, man_b_norm;
  assign man_a_norm = {1'b1, man_a};
  assign man_b_norm = {1'b1, man_b};

  // which mantissa is the one of larger exp?
  logic [m_p:0] larger_exp_man, smaller_exp_man;
  assign larger_exp_man = exp_a_less
    ? man_b_norm
    : man_a_norm;
  assign smaller_exp_man = exp_a_less
    ? man_a_norm
    : man_b_norm;

  // determine sticky bit
  logic sticky;
  bsg_fpu_sticky #(
    .width_p(m_p+3)
  ) sticky0 (
    .i({smaller_exp_man[m_p:0], 2'b0})
    ,.shamt_i(exp_diff[`BSG_WIDTH(m_p+3)-1:0])
    ,.sticky_o(sticky)
  );

  // determine final sign
  logic final_sign;
  logic mag_a_less;

  bsg_less_than #(
    .width_p(e_p+m_p)
  ) lt_mag (
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

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_1_r <= 1'b0;
    end
    else begin
      if (~stall & en_i) begin
        v_1_r <= v_i;
        if (v_i) begin
          final_sign_1_r <= final_sign;
          do_sub_1_r <= do_sub;
          larger_exp_1_r <= larger_exp;
          smaller_exp_man_shifted_1_r <= smaller_exp_man_shifted;
          larger_exp_man_padded_1_r <= larger_exp_man_padded;
          a_sig_nan_1_r <= a_sig_nan;
          b_sig_nan_1_r <= b_sig_nan;
          a_nan_1_r <= a_nan;
          b_nan_1_r <= b_nan;
          a_infty_1_r <= a_infty;
          b_infty_1_r <= b_infty;
          a_denormal_1_r <= a_denormal;
          b_denormal_1_r <= b_denormal;
        end
      end
    end
  end

 
  // which mantissa has smaller magnitude?
  logic larger_exp_man_less;
  bsg_less_than #(
    .width_p(m_p+4)
  ) lt_man_norm (
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

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_2_r <= 1'b0;
    end
    else begin
      if (~stall & en_i) begin
        v_2_r <= v_1_r;
        if (v_1_r) begin
          larger_exp_2_r <= larger_exp_1_r;
          adder_output_2_r <= adder_output;
          final_sign_2_r <= final_sign_1_r;
          do_sub_2_r <= do_sub_1_r;
          a_sig_nan_2_r <= a_sig_nan_1_r;
          b_sig_nan_2_r <= b_sig_nan_1_r;
          a_nan_2_r <= a_nan_1_r;
          b_nan_2_r <= b_nan_1_r;
          a_infty_2_r <= a_infty_1_r;
          b_infty_2_r <= b_infty_1_r;
          a_denormal_2_r <= a_denormal_1_r;
          b_denormal_2_r <= b_denormal_1_r;
        end
      end
    end
  end

  // count leading zero
  logic [`BSG_SAFE_CLOG2(m_p+5)-1:0] num_zero;
  logic reduce_o;
  logic all_zero;

  bsg_fpu_clz #(
    .width_p(m_p+5)
  ) clz (
    .i(adder_output_2_r)
    ,.num_zero_o(num_zero)
  );

  bsg_reduce #(
    .width_p(m_p+5)
    ,.or_p(1)
  ) reduce0 ( 
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
    if (reset_i) begin
      v_3_r <= 1'b0;
    end
    else begin
      if (~stall & en_i) begin
        v_3_r <= v_2_r;
        if (v_2_r) begin
          pre_roundup_3_r <= pre_roundup;
          round_up_3_r <= round_up;
          all_zero_3_r <= all_zero;
          a_sig_nan_3_r <= a_sig_nan_2_r;
          b_sig_nan_3_r <= b_sig_nan_2_r;
          a_nan_3_r <= a_nan_2_r;
          b_nan_3_r <= b_nan_2_r;
          a_infty_3_r <= a_infty_2_r;
          b_infty_3_r <= b_infty_2_r;
          do_sub_3_r <= do_sub_2_r;
          a_denormal_3_r <= a_denormal_2_r;
          b_denormal_3_r <= b_denormal_2_r;
          adjusted_exp_cout_3_r <= adjusted_exp_cout;
          final_sign_3_r <= final_sign_2_r;	
        end
      end
    end
  end

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
      unimplemented_o = 1'b0;
      invalid_o = 1'b1;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_SIGNAN(e_p,m_p);
    end
    else if (a_nan_3_r | b_nan_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_QUIETNAN(e_p,m_p);
    end
    else if (a_infty_3_r & b_infty_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = do_sub_3_r;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = do_sub_3_r 
        ? `BSG_FPU_QUIETNAN(e_p,m_p)
        : `BSG_FPU_INFTY(sgn,e_p,m_p);
    end
    else if (a_infty_3_r & ~b_infty_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_INFTY(sgn,e_p,m_p);
    end
    else if (~a_infty_3_r & b_infty_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_INFTY(sgn,e_p,m_p);
    end
    else if (a_denormal_3_r | b_denormal_3_r) begin
      unimplemented_o = 1'b1;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o =`BSG_FPU_QUIETNAN(e_p,m_p);
    end
    else if(all_zero_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b0;
      z_o = `BSG_FPU_ZERO(sgn,e_p,m_p);
    end
    else if (adjusted_exp_cout_3_r) begin
      unimplemented_o = 1'b0;
      invalid_o = 1'b0;
      overflow_o = 1'b0;
      underflow_o = 1'b1;
      z_o = `BSG_FPU_ZERO(sgn,e_p,m_p);
    end
    else begin
      if (pre_roundup_3_r[m_p+:e_p] == {e_p{1'b1}} & (pre_roundup_3_r[m_p] | carry_into_exp)) begin
        unimplemented_o = 1'b0;
        invalid_o = 1'b0;
        overflow_o = 1'b1;
        underflow_o = 1'b0;
        z_o =`BSG_FPU_INFTY(sgn,e_p,m_p);
      end
      else if (pre_roundup_3_r[m_p+:e_p] == {e_p{1'b0}} & ~carry_into_exp) begin
        unimplemented_o = 1'b0;
        invalid_o = 1'b0;
        overflow_o = 1'b0;
        underflow_o = 1'b1;
        z_o = `BSG_FPU_ZERO(sgn,e_p,m_p);
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
