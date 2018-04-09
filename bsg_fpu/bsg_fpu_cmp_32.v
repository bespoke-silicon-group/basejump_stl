/**
 *  bsg_fpu_cmp_32.v
 *
 *  32-bit floating-point comparator.
 *
 *  @author Tommy Jung
 */

// ---------------
// subop encoding
// ---------------
// 0    =       eq
// 1    <       lt
// 2    <=      le
// ---------------

module bsg_fpu_cmp_32
  ( input [31:0] a_i
    , input [31:0] b_i
    , input [1:0] subop_i
    , output logic o
    , output logic invalid_o
    );

  logic a_zero, a_nan, a_sig_nan, a_infty;
  logic b_zero, b_nan, b_sig_nan, b_infty;
  logic mag_a_lt;
  logic eq, lt, le;

  bsg_fpu_preprocess #(.exp_width_p(8)
                        ,.mantissa_width_p(23))
    a_preprocess (.a_i(a_i)
                  ,.zero_o(a_zero)
                  ,.nan_o(a_nan)
                  ,.sig_nan_o(a_sig_nan)
                  ,.infty_o(a_infty)
                  ,.exp_zero_o()
                  ,.man_zero_o()
                  ,.denormal_o()
                  ,.sign_o()
                  ,.exp_o()
                  ,.man_o()
                  );

  bsg_fpu_preprocess #(.exp_width_p(8)
                      ,.mantissa_width_p(23))
    b_preprocess (.a_i(b_i)
                  ,.zero_o(b_zero)
                  ,.nan_o(b_nan)
                  ,.sig_nan_o(b_sig_nan)
                  ,.infty_o(b_infty)
                  ,.exp_zero_o()
                  ,.man_zero_o()
                  ,.denormal_o()
                  ,.sign_o()
                  ,.exp_o()
                  ,.man_o()
                  );

  bsg_less_than #(.width_p(31)) lt_mag (
    .a_i(a_i[30:0])
    ,.b_i(b_i[30:0])
    ,.o(mag_a_lt)
    );

  always_comb begin
    if (a_nan & b_nan) begin
      eq = 0;
      lt = 0;
      le = 0;
    end
    else if (a_nan ^ b_nan) begin
      eq = 0;
      lt = 0;
      le = 0;
    end
    else if (~a_nan & ~b_nan) begin
      if (a_zero & b_zero) begin
        eq = 1;
        lt = 0;
        le = 1; 
      end	
      else begin
        // a and b are neither NaNs nor zeros.
        // compare sign and compare magnitude.
        eq = (a_i == b_i);
        case ({a_i[31], b_i[31]})
          2'b00: begin
            lt = mag_a_lt;
            le = mag_a_lt | eq; 	
        end
          2'b01: begin 
            lt = 0;
            le = 0;	
        end
          2'b10: begin
            lt = 1;
            le = 1;	
        end
          2'b11: begin
            lt = ~mag_a_lt & ~eq;
            le = ~mag_a_lt | eq; 	
          end
        endcase
      end
    end
  end

  always_comb begin
    case (subop_i)
      2'd0: o = eq;
      2'd1: o = lt;
      2'd2: o = le;
      default: o = 1'bx;
    endcase
  end 

  assign invalid_o = a_sig_nan | b_sig_nan;

endmodule
