/**
 *  bsg_fpu_f2i_32.v
 *
 *  float-to-int converter
 *
 *  @author Tommy Jung
 */

module bsg_fpu_f2i_32 (
  input [31:0] a_i          // input float
  ,input [2:0] rm_i         // rounding mode
  ,output logic [31:0] o    // output int
);

  logic sign;
  logic [7:0] exp;
  logic [22:0] mantissa;
  logic zero;
  
  bsg_fpu_preprocess #(.exp_width_p(8), .mantissa_width_p(23)) preprocess (
    .a_i(a_i)
    ,.zero_o(zero)
    ,.nan_o()
    ,.sig_nan_o()
    ,.infty_o()
    ,.exp_zero_o()
    ,.man_zero_o()
    ,.denormal_o()
    ,.sign_o(sign)
    ,.exp_o(exp)
    ,.man_o(mantissa)
  );

  logic [7:0] shamt;
  assign shamt = 8'd157 - exp;

  logic [32:0] preshift;
  assign preshift = {1'b1, mantissa, 9'b0};

  logic [32:0] shifted;
  assign shifted = preshift >> shamt[5:0];

  logic sticky_bit;
  bsg_fpu_sticky #(.width_p(33)) sticky0 (
    .i(preshift)
    ,.shamt_i(shamt[5:0])
    ,.sticky_o(sticky_bit)
  );
  
  // lsb | g r s
  logic guard_bit;
  logic round_bit;
  assign guard_bit = shifted[1];
  assign round_bit = shifted[0];
 
  logic do_round;
  bsg_fpu_round round0 (
    .sign_i(sign)
    ,.lsb_i(shifted[2])
    ,.guard_i(guard_bit)
    ,.round_i(round_bit)
    ,.sticky_i(sticky_bit)
    ,.rm_i(rm_i)
    ,.do_round_o(do_round)
  );
  
  logic [31:0] inverted;
  assign inverted = {32{sign}} ^ {1'b0, shifted[32:2]};

  logic [31:0] post_round;
  assign post_round = inverted + (do_round ^ sign);

  logic exp_too_big;
  logic exp_too_small;
  assign exp_too_big = exp > 8'd157;
  assign exp_too_small = exp < 8'd125; 

  always_comb begin
    if (zero) begin
      o = 32'b0;
    end
    else if (exp_too_big) begin
      o = 32'h8000_0000;
    end
    else if (exp_too_small) begin
      o = 32'b0;
    end
    else begin
      o = post_round;
    end
  end

endmodule
