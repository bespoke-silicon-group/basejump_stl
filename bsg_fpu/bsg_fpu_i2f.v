/**
 *  bsg_fpu_i2f.v
 *
 *  @author Tommy Jung
 *
 *  Parameterized int-to-float converter.
 *  It can handle signed/unsigned integer.
 *
 */

`include "bsg_defines.v"

module bsg_fpu_i2f
  #(parameter e_p="inv"
    , parameter m_p="inv"
    
    , localparam width_lp = (e_p+m_p+1)
    , localparam bias_lp = {1'b0, {(e_p-1){1'b1}}}
  )
  (
    input clk_i
    , input reset_i
    , input en_i

    , input v_i
    , input signed_i
    , input [width_lp-1:0] a_i
    , output logic ready_o

    , output logic v_o
    , output logic [width_lp-1:0] z_o
    , input yumi_i
  );
  

  // pipeline status / control
  //
  logic v_1_r;
  logic stall;

  assign v_o = v_1_r;
  assign stall = v_1_r & ~yumi_i;
  assign ready_o = ~stall & en_i;

  // sign bit
  //
  logic sign;
  assign sign = signed_i
    ? a_i[width_lp-1]
    : 1'b0;

  // calculate absolute value
  logic [width_lp-1:0] abs;
  // The following KEEP attribute prevents the following warning in the Xilinx
  // toolchain: [Synth 8-3936] Found unconnected internal register
  // 'chosen_abs_1_r_reg' and it is trimmed from '32' to '31'
  // bits. [<path>/bsg_fpu_i2f.v:98] (Xilinx Vivado 2018.2)
  (* keep = "true" *) logic [width_lp-1:0] chosen_abs;

  bsg_abs #(
    .width_p(width_lp)
  ) abs0 (
    .a_i(a_i)
    ,.o(abs)
  );

  assign chosen_abs = signed_i
    ? abs
    : a_i;

  // count the number of leading zeros
  logic [`BSG_SAFE_CLOG2(width_lp)-1:0] shamt;
  logic all_zero;

  bsg_fpu_clz #(
    .width_p(width_lp)
  ) clz (
    .i(chosen_abs)
    ,.num_zero_o(shamt)
  );

  assign all_zero = ~(|chosen_abs);

  /////////// first pipeline stage /////////////

  // The following KEEP attribute prevents the following warning in the Xilinx
  // toolchain: [Synth 8-3936] Found unconnected internal register
  // 'chosen_abs_1_r_reg' and it is trimmed from '32' to '31'
  // bits. [<path>/bsg_fpu_i2f.v:98] (Xilinx Vivado 2018.2)
  (* keep = "true" *) logic [width_lp-1:0] chosen_abs_1_r;
  logic [`BSG_SAFE_CLOG2(width_lp)-1:0] shamt_1_r;
  logic sign_1_r;
  logic all_zero_1_r;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_1_r <= 1'b0;
    end
    else begin
      if (~stall & en_i) begin
        v_1_r <= v_i;
        if (v_i) begin
          chosen_abs_1_r <= chosen_abs;
          shamt_1_r <= shamt;
          sign_1_r <= sign;
          all_zero_1_r <= all_zero;
        end
      end
    end
  end

  //////////////////////////////////////////////

  // exponent 
  logic [e_p-1:0] exp;
  assign exp = (e_p)'((bias_lp+e_p+m_p) - shamt_1_r);

  // shifted
  logic [width_lp-1:0] shifted;
  assign shifted = chosen_abs_1_r << shamt_1_r;

  // sticky bit
  logic sticky;
  assign sticky = |shifted[width_lp-3-m_p:0];

  // round bit
  logic round_bit;
  assign round_bit = shifted[width_lp-2-m_p];

  // mantissa
  logic [m_p-1:0] mantissa;
  assign mantissa = shifted[width_lp-2:width_lp-1-m_p];

  // round up condition
  logic round_up;
  assign round_up = round_bit & (mantissa[0] | sticky);

  // round up
  logic [width_lp-2:0] rounded;
  assign rounded = {exp, mantissa} + round_up;

  // final result
  assign z_o = all_zero_1_r
    ? {width_lp{1'b0}}
    : {sign_1_r, rounded};


endmodule
