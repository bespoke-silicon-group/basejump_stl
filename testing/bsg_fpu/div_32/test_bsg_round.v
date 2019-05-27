/*
TEST RATIONALE
1. STATE SPACE
type_i = eRtne (Round to nearest even) with mantissa equal to boundary value(1.5, 1.75, 0.75, 0.5).
2.PARAMETERIZATION
width_i_p = 5
width_o_p = 3
*/


module bsg_test;

import bsg_fpu_pkg::*;

bsg_fpu_rounding_type_e type_i;
logic [4:0] mantissa_in;
logic sign_i;
logic [3:0] mantissa_out; // 0, 1, 2, 3

bsg_fpu_round #(
  .width_i_p(5)
  ,.width_o_p(3)
) round (
  .type_i(type_i)
  ,.mantissa_i(mantissa_in)
  ,.sign_i(sign_i)
  ,.mantissa_o(mantissa_out)
);

initial begin
  type_i = eRtne;
  sign_i = 0;
  mantissa_in = 5'b01010;
  #5
  assert (mantissa_out == 4'b0010) else $error("Test 1 Error!");
  mantissa_in = 5'b00110;
  #5
  assert (mantissa_out == 4'b0010) else $error("Test 2 Error!");
  mantissa_in = 5'b01011;
  #5
  assert (mantissa_out == 4'b0011) else $error("Test 3 Error!");

  mantissa_in = 5'b11111;
  #5
  assert(mantissa_out == 4'b1000) else $error("Test 4 Error! mantissa_out:%b", mantissa_out);

end
endmodule 

