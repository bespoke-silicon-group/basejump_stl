/**
 *  bsg_fpu_cmp.v
 *
 *  @author Tommy Jung
 *
 *  parameterized floating-point comparator.
 *
 *  comparison
 *  - eq_o: equal
 *  - lt_o: less than
 *  - le_o: less or equal
 *
 *  Note:
 *  - lt and le raises invalid exception if either input is NaN.
 *  - eq raises invalid exception only when there is signaling NaN input.
 *
 *  min-max
 *  - if either input is signaling NaN, the result is canonical NaN.
 *    also, the invalid exception is raised.
 *  - if both inputs are quiet NaN, the result is canonical NaN.
 *  - if one is quiet NaN and the other is non-NaN,
 *    then the result is non-NaN input.
 *  - if both inputs are (positive or negative zero), then the output is
 *    positive zero.
 *
 */

`include "bsg_defines.v"

`include "bsg_fpu_defines.vh"

module bsg_fpu_cmp
  #(parameter e_p="inv"
    , parameter m_p="inv"
  )
  (
    input [e_p+m_p:0] a_i
    , input [e_p+m_p:0] b_i

    // comparison
    , output logic eq_o
    , output logic lt_o
    , output logic le_o
    
    , output logic lt_le_invalid_o
    , output logic eq_invalid_o

    // min-max
    , output logic [e_p+m_p:0] min_o
    , output logic [e_p+m_p:0] max_o
    , output logic min_max_invalid_o
  );

  // preprocess
  //
  logic a_zero, a_nan, a_sig_nan, a_infty, a_sign;
  logic b_zero, b_nan, b_sig_nan, b_infty, b_sign;

  bsg_fpu_preprocess #(
    .e_p(e_p)
    ,.m_p(m_p)
  ) a_preprocess (
    .a_i(a_i)
    ,.zero_o(a_zero)
    ,.nan_o(a_nan)
    ,.sig_nan_o(a_sig_nan)
    ,.infty_o(a_infty)
    ,.exp_zero_o()
    ,.man_zero_o()
    ,.denormal_o()
    ,.sign_o(a_sign)
    ,.exp_o()
    ,.man_o()
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
    ,.exp_zero_o()
    ,.man_zero_o()
    ,.denormal_o()
    ,.sign_o(b_sign)
    ,.exp_o()
    ,.man_o()
  );

  // compare
  //
  logic mag_a_lt;

  bsg_less_than #(
    .width_p(e_p+m_p)
  ) lt_mag (
    .a_i(a_i[0+:e_p+m_p])
    ,.b_i(b_i[0+:e_p+m_p])
    ,.o(mag_a_lt)
  );


  // comparison
  //
  always_comb begin
    if (a_nan | b_nan) begin
      eq_o = 1'b0;
      lt_o = 1'b0;
      le_o = 1'b0;
      lt_le_invalid_o = 1'b1;
      eq_invalid_o = a_sig_nan | b_sig_nan;
    end
    else begin

      if (a_zero & b_zero) begin
        eq_o = 1'b1;
        lt_o = 1'b0;
        le_o = 1'b1;
        lt_le_invalid_o = 1'b0;
        eq_invalid_o = 1'b0;
      end	
      else begin
        // a and b are neither NaNs nor zeros.
        // compare sign and compare magnitude.
        eq_o = (a_i == b_i);
        lt_le_invalid_o = 1'b0;
        eq_invalid_o = 1'b0;

        case ({a_sign, b_sign})
          2'b00: begin
            lt_o = mag_a_lt;
            le_o = mag_a_lt | eq_o; 	
        end
          2'b01: begin 
            lt_o = 1'b0;
            le_o = 1'b0;	
        end
          2'b10: begin
            lt_o = 1'b1;
            le_o = 1'b1;	
        end
          2'b11: begin
            lt_o = ~mag_a_lt & ~eq_o;
            le_o = ~mag_a_lt | eq_o; 	
          end
        endcase

      end

    end
  end

  // min-max
  //
  always_comb begin
    if (a_nan & b_nan) begin
      min_o = `BSG_FPU_QUIETNAN(e_p,m_p);
      max_o = `BSG_FPU_QUIETNAN(e_p,m_p);
      min_max_invalid_o = a_sig_nan | b_sig_nan;
    end
    else if (a_nan & ~b_nan) begin
      min_o = b_i;
      max_o = b_i;
      min_max_invalid_o = a_sig_nan;
    end
    else if (~a_nan & b_nan) begin
      min_o = a_i;
      max_o = a_i;
      min_max_invalid_o = b_sig_nan;
    end
    else begin
      min_max_invalid_o = 1'b0;

      if (a_zero & b_zero) begin
        min_o = `BSG_FPU_ZERO(a_sign | b_sign, e_p, m_p);
        max_o = `BSG_FPU_ZERO(a_sign & b_sign, e_p, m_p);
      end
      else if (lt_o) begin
        min_o = a_i;
        max_o = b_i;
      end
      else begin
        min_o = b_i;
        max_o = a_i;
      end
    end
  end

endmodule
