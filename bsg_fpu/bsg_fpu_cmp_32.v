/**
 *  bsg_fpu_cmp_n.v
 *
 *  parameterized floating-point comparator.
 *
 *  @author Tommy Jung
 */


module bsg_fpu_cmp_n
  #(parameter e_p="inv"
    , parameter m_p="inv"
  )
  (
    input [e_p+m_p:0] a_i
    , input [e_p+m_p:0] b_i

    , output logic eq_o
    , output logic ne_o
    , output logic gt_o
    , output logic lt_o
    , output logic ge_o
    , output logic le_o
  
    , output logic invalid_o
  );

  logic a_zero, a_nan, a_sig_nan, a_infty;
  logic b_zero, b_nan, b_sig_nan, b_infty;
  logic mag_a_lt;
  logic eq, ne, gt, lt, ge, le;

  bsg_fpu_preprocess #(
    .e_p(e_p)
    ,.m_p(m_p)
  ) a_preprocess (
    .a_i(a_i)
    ,.zero_o(a_zero)
    ,.nan_o(a_nan)
    ,.sig_nan_o(a_sig_nan)
    ,.infty_o(a_infty)
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
  );

  bsg_less_than #(
    .width_p(e_p+m_p)
  ) lt_mag (
    .a_i(a_i[e_p+m_p-1:0])
    ,.b_i(b_i[e_p+m_p-1:0])
    ,.o(mag_a_lt)
  );

  always_comb begin
    if (a_nan & b_nan) begin
      eq = 0; ne = 1;
      gt = 0; lt = 0;
      ge = 0; le = 0;
    end
    else if (a_nan ^ b_nan) begin
      eq = 0; ne = 1;
      gt = 0; lt = 0;
      ge = 0; le = 0;
    end
    else if (~a_nan & ~b_nan) begin
      if (a_zero & b_zero) begin
        eq = 1; ne = 0;
        gt = 0; lt = 0;
        ge = 1; le = 1; 
      end	
      else begin
        // a and b are neither NaNs nor zeros.
        // compare sign and compare magnitude.
        eq = (a_i == b_i);
        ne = ~eq;
        case ({a_i[31], b_i[31]})
          2'b00: begin
            gt = ~mag_a_lt & ~eq;
            lt = mag_a_lt;
            ge = ~mag_a_lt | eq;
            le = mag_a_lt | eq; 	
        end
          2'b01: begin 
            gt = 1;
            lt = 0;
            ge = ~lt;
            le = ~gt;	
        end
          2'b10: begin
            gt = 0;
            lt = 1;
            ge = ~lt;
            le = ~gt;	
        end
          2'b11: begin
            gt = mag_a_lt;
            lt = ~mag_a_lt & ~eq;
            ge = mag_a_lt | eq;
            le = ~mag_a_lt | eq; 	
          end
        endcase
      end
    end
  end

  assign invalid_o = a_sig_nan | b_sig_nan;

endmodule
