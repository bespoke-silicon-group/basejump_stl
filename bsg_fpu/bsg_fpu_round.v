// -------------------------------------------------------
// -- bsg_fpu_round_n.v
// 
// -- sqlin16@fudan.edu.cn     5/10/2019
// -------------------------------------------------------
// This is a rounding module for floating number calculation.
// Currently supported rounding type are:
// Rtne: rounding to nearest even number
// Rtna: rounding to nearest away-from-zero number
// inward: rounding toward zero
// upward: rounding toward to positive infinity
// downward: rounding toward to negative infinity
// -------------------------------------------------------


module bsg_fpu_round
  import bsg_fpu_pkg::*;
#(
  parameter integer width_i_p = "inv"
  ,parameter integer width_o_p = "inv"
)(
  input bsg_fpu_rounding_type_e type_i
  ,input [width_i_p-1:0] mantissa_i
  ,input sign_i

  ,output [width_o_p-1:0] mantissa_o
);

  initial assert(width_i_p > width_o_p) else $error("No rounding occurs because of output larger size than input");

  localparam width_diff_lp = width_i_p - width_o_p;
  wire [width_diff_lp-1:0] extra_bits = mantissa_i[width_diff_lp-1:0];
  wire no_need_rounding = extra_bits == '0;
  wire remnant_great_than_half;
  if(width_diff_lp > 1)
    assign remnant_great_than_half = extra_bits[width_diff_lp-2:0] != '0;
  else
    assign remnant_great_than_half = 1'b0;

  logic [width_o_p-1:0] fix_factor;
  assign mantissa_o = no_need_rounding ? mantissa_i[width_i_p-1:width_diff_lp]  : mantissa_i[width_i_p-1:width_diff_lp] + fix_factor;

  always_comb unique case(type_i)
    eInward: fix_factor = width_o_p'(sign_i);
    eUpward: fix_factor = width_o_p'(1);
    eDownward: fix_factor = '0;
    eRtne: begin
      if(remnant_great_than_half & extra_bits[width_diff_lp-1])
        fix_factor = (width_o_p)'(1);
      else if(extra_bits[width_diff_lp-1] & mantissa_i[width_diff_lp])
        fix_factor = (width_o_p)'(1);
      else
        fix_factor = '0;
    end
    eRtna: begin
      if(extra_bits[width_diff_lp-1])
        fix_factor =  width_o_p'(1);
      else
        fix_factor = '0;
    end
    default: fix_factor = '0;
  endcase

endmodule
