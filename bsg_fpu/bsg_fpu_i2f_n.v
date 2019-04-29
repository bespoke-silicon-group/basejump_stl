/**
 *  bsg_fpu_i2f_n.v
 *
 *  @author Tommy Jung
 *
 *  Parameterized int-to-float converter. 
 *
 *  It handles signed/unsigned integer.
 *
 */

module bsg_fpu_i2f_n
  #(parameter e_p="inv"
    , parameter m_p="inv"
  )
(
  input [31:0] a_i
  , input signed_i
  , output logic [31:0] o
);

  // sign bit
  logic sign;
  assign sign = a_i[31];

  // calculate absolute value
  logic [31:0] abs;

  bsg_abs #(
    .width_p(32)
  ) bsg_abs0 (
    .a_i(a_i)
    ,.o(abs)
  );

  // count the number of leading zeros
  logic [4:0] shamt;
  logic all_zero;

  bsg_counting_leading_zeros #(
    .width_p(32)
  ) clz (
    .a_i(abs)
    ,.num_zero_o(shamt)
  );

  assign all_zero = ~(|abs);

  // exponent 
  logic [7:0] exp;
  assign exp = 8'b1001_1110 - shamt;

  // shifted
  logic [31:0] shifted;
  assign shifted = abs << shamt;

  // sticky bit
  logic sticky;
  assign sticky = |shifted[6:0];

  // round bit
  logic round_bit;
  assign round_bit = shifted[7];

  // mantissa
  logic [22:0] mantissa;
  assign mantissa = shifted[30:8];

  // round up condition
  logic round_up;
  assign round_up = round_bit & (mantissa[0] | sticky);

  // round up
  logic [30:0] rounded;
  assign rounded = {exp, mantissa} + round_up;

  // final result
  assign o = all_zero
    ? 32'b0
    : {sign, rounded};

endmodule
