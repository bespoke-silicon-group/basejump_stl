/**
 *	bsg_mul_array_24.v
 *
 *	pipelined 24-bit array multiplier.
 *
 *	@author Tommy Jung
 */

module bsg_mul_array_24 (
    input clk_i
    ,	input rst_i
    , input v_i
    , input [23:0] a_i
    , input [23:0] b_i
    , output logic [47:0] z_o
);

  genvar i; 

  // 0th row
  logic [23:0] s0;

  for (i = 0; i < 24; i++) begin
    assign s0[i] = a_i[i] & b_i[0];
  end

  // 1st row
  logic [23:0] s1, c1;

  bsg_adder_half hadder_1_0 (
    .a_i(a_i[0] & b_i[1]),
    .b_i(s0[1]),
    .s_o(s1[0]),
    .c_o(c1[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_1 (
      .a_i(a_i[i] & b_i[1]),
      .b_i(s0[i+1]),
      .c_i(c1[i-1]),
      .s_o(s1[i]),
      .c_o(c1[i])
    );
  end

  bsg_adder_half hadder_1_23 (
    .a_i(a_i[23] & b_i[1]),
    .b_i(c1[22]),
    .s_o(s1[23]),
    .c_o(c1[23])	
  );

  // 2nd row
  logic [23:0] s2, c2;

  bsg_adder_half hadder_2_0 (
    .a_i(s1[1]),
    .b_i(a_i[0] & b_i[2]),
    .s_o(s2[0]),
    .c_o(c2[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_2 (
      .a_i(s1[i+1]),
      .b_i(a_i[i] & b_i[2]),
      .c_i(c2[i-1]),
      .s_o(s2[i]),
      .c_o(c2[i])
    );
  end

  bsg_adder_full fadder_2_23 (
    .a_i(c1[23]),
    .b_i(a_i[23] & b_i[2]),
    .c_i(c2[22]),
    .s_o(s2[23]),
    .c_o(c2[23])
  );

  // 3rd row
  logic [23:0] s3, c3;

  bsg_adder_half hadder_3_0 (
    .a_i(s2[1]),
    .b_i(a_i[0] & b_i[3]),
    .s_o(s3[0]),
    .c_o(c3[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_3 (
      .a_i(s2[i+1]),
      .b_i(a_i[i] & b_i[3]),
      .c_i(c3[i-1]),
      .s_o(s3[i]),
      .c_o(c3[i])
    );
  end

  bsg_adder_full fadder_3_23 (
    .a_i(c2[23]),
    .b_i(a_i[23] & b_i[3]),
    .c_i(c3[22]),
    .s_o(s3[23]),
    .c_o(c3[23])
  );

  // 4th row
  logic [23:0] s4, c4;

  bsg_adder_half hadder_4_0 (
    .a_i(s3[1]),
    .b_i(a_i[0] & b_i[4]),
    .s_o(s4[0]),
    .c_o(c4[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_4 (
      .a_i(s3[i+1]),
      .b_i(a_i[i] & b_i[4]),
      .c_i(c4[i-1]),
      .s_o(s4[i]),
      .c_o(c4[i])
    );
  end

  bsg_adder_full fadder_4_23 (
    .a_i(c3[23]),
    .b_i(a_i[23] & b_i[4]),
    .c_i(c4[22]),
    .s_o(s4[23]),
    .c_o(c4[23])
  );

  // 5th row
  logic [23:0] s5, c5;

  bsg_adder_half hadder_5_0 (
    .a_i(s4[1]),
    .b_i(a_i[0] & b_i[5]),
    .s_o(s5[0]),
    .c_o(c5[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_5 (
      .a_i(s4[i+1]),
      .b_i(a_i[i] & b_i[5]),
      .c_i(c5[i-1]),
      .s_o(s5[i]),
      .c_o(c5[i])
    );
  end

  bsg_adder_full fadder_5_23 (
    .a_i(c4[23]),
    .b_i(a_i[23] & b_i[5]),
    .c_i(c5[22]),
    .s_o(s5[23]),
    .c_o(c5[23])
  );

  // 6th row
  logic [23:0] s6, c6;

  bsg_adder_half hadder_6_0 (
    .a_i(s5[1]),
    .b_i(a_i[0] & b_i[6]),
    .s_o(s6[0]),
    .c_o(c6[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_6 (
      .a_i(s5[i+1]),
      .b_i(a_i[i] & b_i[6]),
      .c_i(c6[i-1]),
      .s_o(s6[i]),
      .c_o(c6[i])
    );
  end

  bsg_adder_full fadder_6_23 (
    .a_i(c5[23]),
    .b_i(a_i[23] & b_i[6]),
    .c_i(c6[22]),
    .s_o(s6[23]),
    .c_o(c6[23])
  );

  // 7th row
  logic [23:0] s7, c7;

  bsg_adder_half hadder_7_0 (
    .a_i(s6[1]),
    .b_i(a_i[0] & b_i[7]),
    .s_o(s7[0]),
    .c_o(c7[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_7 (
      .a_i(s6[i+1]),
      .b_i(a_i[i] & b_i[7]),
      .c_i(c7[i-1]),
      .s_o(s7[i]),
      .c_o(c7[i])
    );
  end

  bsg_adder_full fadder_7_23 (
    .a_i(c6[23]),
    .b_i(a_i[23] & b_i[7]),
    .c_i(c7[22]),
    .s_o(s7[23]),
    .c_o(c7[23])
  );

  // 8th row
  logic [23:0] s8, c8;

  bsg_adder_half hadder_8_0 (
    .a_i(s7[1]),
    .b_i(a_i[0] & b_i[8]),
    .s_o(s8[0]),
    .c_o(c8[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_8 (
      .a_i(s7[i+1]),
      .b_i(a_i[i] & b_i[8]),
      .c_i(c8[i-1]),
      .s_o(s8[i]),
      .c_o(c8[i])
    );
  end

  bsg_adder_full fadder_8_23 (
    .a_i(c7[23]),
    .b_i(a_i[23] & b_i[8]),
    .c_i(c8[22]),
    .s_o(s8[23]),
    .c_o(c8[23])
  );

  // 9th row
  logic [23:0] s9, c9;

  bsg_adder_half hadder_9_0 (
    .a_i(s8[1]),
    .b_i(a_i[0] & b_i[9]),
    .s_o(s9[0]),
    .c_o(c9[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_9 (
      .a_i(s8[i+1]),
      .b_i(a_i[i] & b_i[9]),
      .c_i(c9[i-1]),
      .s_o(s9[i]),
      .c_o(c9[i])
    );
  end

  bsg_adder_full fadder_9_23 (
    .a_i(c8[23]),
    .b_i(a_i[23] & b_i[9]),
    .c_i(c9[22]),
    .s_o(s9[23]),
    .c_o(c9[23])
  );

  // 10th row
  logic [23:0] s10, c10;

  bsg_adder_half hadder_10_0 (
    .a_i(s9[1]),
    .b_i(a_i[0] & b_i[10]),
    .s_o(s10[0]),
    .c_o(c10[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_10 (
      .a_i(s9[i+1]),
      .b_i(a_i[i] & b_i[10]),
      .c_i(c10[i-1]),
      .s_o(s10[i]),
      .c_o(c10[i])
    );
  end

  bsg_adder_full fadder_10_23 (
    .a_i(c9[23]),
    .b_i(a_i[23] & b_i[10]),
    .c_i(c10[22]),
    .s_o(s10[23]),
    .c_o(c10[23])
  );

  // 11th row
  logic [23:0] s11, c11;

  bsg_adder_half hadder_11_0 (
    .a_i(s10[1]),
    .b_i(a_i[0] & b_i[11]),
    .s_o(s11[0]),
    .c_o(c11[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_11 (
      .a_i(s10[i+1]),
      .b_i(a_i[i] & b_i[11]),
      .c_i(c11[i-1]),
      .s_o(s11[i]),
      .c_o(c11[i])
    );
  end

  bsg_adder_full fadder_11_23 (
    .a_i(c10[23]),
    .b_i(a_i[23] & b_i[11]),
    .c_i(c11[22]),
    .s_o(s11[23]),
    .c_o(c11[23])
  );

  /////////// pipeline stage ///////////////

  logic [23:0] a_r;
  logic [23:0] b_r;
  logic c11_23_r;
  logic [23:0] s11_r;
  logic s0_0_r, s1_0_r, s2_0_r, s3_0_r,
    s4_0_r, s5_0_r, s6_0_r, s7_0_r,
    s8_0_r, s9_0_r, s10_0_r;

  logic [23:0] a_n;
  logic [23:0] b_n;
  logic c11_23_n;
  logic [23:0] s11_n;
  logic s0_0_n, s1_0_n, s2_0_n, s3_0_n,
    s4_0_n, s5_0_n, s6_0_n, s7_0_n,
    s8_0_n, s9_0_n, s10_0_n;

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      a_r <= 0;
      b_r <= 0;
      c11_23_r <= 0;
      s11_r <= 0;
      s0_0_r <= 0;
      s1_0_r <= 0;
      s2_0_r <= 0;
      s3_0_r <= 0;
      s4_0_r <= 0;
      s5_0_r <= 0;
      s6_0_r <= 0;
      s7_0_r <= 0;
      s8_0_r <= 0;
      s9_0_r <= 0;
      s10_0_r <= 0;
    end
    else begin
      a_r <= a_n;
      b_r <= b_n;
      c11_23_r <= c11_23_n;
      s11_r <= s11_n;
      s0_0_r <= s0_0_n;
      s1_0_r <= s1_0_n;
      s2_0_r <= s2_0_n;
      s3_0_r <= s3_0_n;
      s4_0_r <= s4_0_n;
      s5_0_r <= s5_0_n;
      s6_0_r <= s6_0_n;
      s7_0_r <= s7_0_n;
      s8_0_r <= s8_0_n;
      s9_0_r <= s9_0_n;
      s10_0_r <= s10_0_n;
    end
  end

  always_comb begin
    if (v_i) begin
      a_n = a_i;
      b_n = b_i;
      c11_23_n = c11[23];
      s11_n = s11;
      s0_0_n = s0[0];
      s1_0_n = s1[0];
      s2_0_n = s2[0];
      s3_0_n = s3[0];
      s4_0_n = s4[0];
      s5_0_n = s5[0];
      s6_0_n = s6[0];
      s7_0_n = s7[0];
      s8_0_n = s8[0];
      s9_0_n = s9[0];
      s10_0_n = s10[0];
    end
    else begin
      a_n = a_r;
      b_n = b_r;
      c11_23_n = c11_23_r;
      s11_n = s11_r;
      s0_0_n = s0_0_r;
      s1_0_n = s1_0_r;
      s2_0_n = s2_0_r;
      s3_0_n = s3_0_r;
      s4_0_n = s4_0_r;
      s5_0_n = s5_0_r;
      s6_0_n = s6_0_r;
      s7_0_n = s7_0_r;
      s8_0_n = s8_0_r;
      s9_0_n = s9_0_r;
      s10_0_n = s10_0_r;
    end
  end

  //////////////////////////////////////////

  // 12th row
  logic [23:0] s12, c12;

  bsg_adder_half hadder_12_0 (
    .a_i(s11_r[1]),
    .b_i(a_r[0] & b_r[12]),
    .s_o(s12[0]),
    .c_o(c12[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_12 (
      .a_i(s11_r[i+1]),
      .b_i(a_r[i] & b_r[12]),
      .c_i(c12[i-1]),
      .s_o(s12[i]),
      .c_o(c12[i])
    );
  end

  bsg_adder_full fadder_12_23 (
    .a_i(c11_23_r),
    .b_i(a_r[23] & b_r[12]),
    .c_i(c12[22]),
    .s_o(s12[23]),
    .c_o(c12[23])
  );

  // 13th row
  logic [23:0] s13, c13;

  bsg_adder_half hadder_13_0 (
    .a_i(s12[1]),
    .b_i(a_r[0] & b_r[13]),
    .s_o(s13[0]),
    .c_o(c13[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_13 (
      .a_i(s12[i+1]),
      .b_i(a_r[i] & b_r[13]),
      .c_i(c13[i-1]),
      .s_o(s13[i]),
      .c_o(c13[i])
    );
  end

  bsg_adder_full fadder_13_23 (
    .a_i(c12[23]),
    .b_i(a_r[23] & b_r[13]),
    .c_i(c13[22]),
    .s_o(s13[23]),
    .c_o(c13[23])
  );

  // 14th row
  logic [23:0] s14, c14;

  bsg_adder_half hadder_14_0 (
    .a_i(s13[1]),
    .b_i(a_r[0] & b_r[14]),
    .s_o(s14[0]),
    .c_o(c14[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_14 (
      .a_i(s13[i+1]),
      .b_i(a_r[i] & b_r[14]),
      .c_i(c14[i-1]),
      .s_o(s14[i]),
      .c_o(c14[i])
    );
  end

  bsg_adder_full fadder_14_23 (
    .a_i(c13[23]),
    .b_i(a_r[23] & b_r[14]),
    .c_i(c14[22]),
    .s_o(s14[23]),
    .c_o(c14[23])
  );

  // 15th row
  logic [23:0] s15, c15;

  bsg_adder_half hadder_15_0 (
    .a_i(s14[1]),
    .b_i(a_r[0] & b_r[15]),
    .s_o(s15[0]),
    .c_o(c15[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_15 (
      .a_i(s14[i+1]),
      .b_i(a_r[i] & b_r[15]),
      .c_i(c15[i-1]),
      .s_o(s15[i]),
      .c_o(c15[i])
    );
  end

  bsg_adder_full fadder_15_23 (
    .a_i(c14[23]),
    .b_i(a_r[23] & b_r[15]),
    .c_i(c15[22]),
    .s_o(s15[23]),
    .c_o(c15[23])
  );

  // 16th row
  logic [23:0] s16, c16;

  bsg_adder_half hadder_16_0 (
    .a_i(s15[1]),
    .b_i(a_r[0] & b_r[16]),
    .s_o(s16[0]),
    .c_o(c16[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_16 (
      .a_i(s15[i+1]),
      .b_i(a_r[i] & b_r[16]),
      .c_i(c16[i-1]),
      .s_o(s16[i]),
      .c_o(c16[i])
    );
  end

  bsg_adder_full fadder_16_23 (
    .a_i(c15[23]),
    .b_i(a_r[23] & b_r[16]),
    .c_i(c16[22]),
    .s_o(s16[23]),
    .c_o(c16[23])
  );

  // 17th row
  logic [23:0] s17, c17;

  bsg_adder_half hadder_17_0 (
    .a_i(s16[1]),
    .b_i(a_r[0] & b_r[17]),
    .s_o(s17[0]),
    .c_o(c17[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_17 (
      .a_i(s16[i+1]),
      .b_i(a_r[i] & b_r[17]),
      .c_i(c17[i-1]),
      .s_o(s17[i]),
      .c_o(c17[i])
    );
  end

  bsg_adder_full fadder_17_23 (
    .a_i(c16[23]),
    .b_i(a_r[23] & b_r[17]),
    .c_i(c17[22]),
    .s_o(s17[23]),
    .c_o(c17[23])
  );

  // 18th row
  logic [23:0] s18, c18;

  bsg_adder_half hadder_18_0 (
    .a_i(s17[1]),
    .b_i(a_r[0] & b_r[18]),
    .s_o(s18[0]),
    .c_o(c18[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_18 (
      .a_i(s17[i+1]),
      .b_i(a_r[i] & b_r[18]),
      .c_i(c18[i-1]),
      .s_o(s18[i]),
      .c_o(c18[i])
    );
  end

  bsg_adder_full fadder_18_23 (
    .a_i(c17[23]),
    .b_i(a_r[23] & b_r[18]),
    .c_i(c18[22]),
    .s_o(s18[23]),
    .c_o(c18[23])
  );

  // 19th row
  logic [23:0] s19, c19;

  bsg_adder_half hadder_19_0 (
    .a_i(s18[1]),
    .b_i(a_r[0] & b_r[19]),
    .s_o(s19[0]),
    .c_o(c19[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_19 (
      .a_i(s18[i+1]),
      .b_i(a_r[i] & b_r[19]),
      .c_i(c19[i-1]),
      .s_o(s19[i]),
      .c_o(c19[i])
    );
  end

  bsg_adder_full fadder_19_23 (
    .a_i(c18[23]),
    .b_i(a_r[23] & b_r[19]),
    .c_i(c19[22]),
    .s_o(s19[23]),
    .c_o(c19[23])
  );

  // 20th row
  logic [23:0] s20, c20;

  bsg_adder_half hadder_20_0 (
    .a_i(s19[1]),
    .b_i(a_r[0] & b_r[20]),
    .s_o(s20[0]),
    .c_o(c20[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_20 (
      .a_i(s19[i+1]),
      .b_i(a_r[i] & b_r[20]),
      .c_i(c20[i-1]),
      .s_o(s20[i]),
      .c_o(c20[i])
    );
  end

  bsg_adder_full fadder_20_23 (
    .a_i(c19[23]),
    .b_i(a_r[23] & b_r[20]),
    .c_i(c20[22]),
    .s_o(s20[23]),
    .c_o(c20[23])
  );

  // 21th row
  logic [23:0] s21, c21;

  bsg_adder_half hadder_21_0 (
    .a_i(s20[1]),
    .b_i(a_r[0] & b_r[21]),
    .s_o(s21[0]),
    .c_o(c21[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_21 (
      .a_i(s20[i+1]),
      .b_i(a_r[i] & b_r[21]),
      .c_i(c21[i-1]),
      .s_o(s21[i]),
      .c_o(c21[i])
    );
  end

  bsg_adder_full fadder_21_23 (
    .a_i(c20[23]),
    .b_i(a_r[23] & b_r[21]),
    .c_i(c21[22]),
    .s_o(s21[23]),
    .c_o(c21[23])
  );

  // 22th row
  logic [23:0] s22, c22;

  bsg_adder_half hadder_22_0 (
    .a_i(s21[1]),
    .b_i(a_r[0] & b_r[22]),
    .s_o(s22[0]),
    .c_o(c22[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_22 (
      .a_i(s21[i+1]),
      .b_i(a_r[i] & b_r[22]),
      .c_i(c22[i-1]),
      .s_o(s22[i]),
      .c_o(c22[i])
    );
  end

  bsg_adder_full fadder_22_23 (
    .a_i(c21[23]),
    .b_i(a_r[23] & b_r[22]),
    .c_i(c22[22]),
    .s_o(s22[23]),
    .c_o(c22[23])
  );

  // 23th row
  logic [23:0] s23, c23;

  bsg_adder_half hadder_23_0 (
    .a_i(s22[1]),
    .b_i(a_r[0] & b_r[23]),
    .s_o(s23[0]),
    .c_o(c23[0])
  );

  for (i = 1; i < 23; i++) begin
    bsg_adder_full fadder_23 (
      .a_i(s22[i+1]),
      .b_i(a_r[i] & b_r[23]),
      .c_i(c23[i-1]),
      .s_o(s23[i]),
      .c_o(c23[i])
    );
  end

  bsg_adder_full fadder_23_23 (
    .a_i(c22[23]),
    .b_i(a_r[23] & b_r[23]),
    .c_i(c23[22]),
    .s_o(s23[23]),
    .c_o(c23[23])
  );


  assign z_o[0] = s0_0_r;
  assign z_o[1] = s1_0_r;
  assign z_o[2] = s2_0_r;
  assign z_o[3] = s3_0_r;
  assign z_o[4] = s4_0_r;
  assign z_o[5] = s5_0_r;
  assign z_o[6] = s6_0_r;
  assign z_o[7] = s7_0_r;
  assign z_o[8] = s8_0_r;
  assign z_o[9] = s9_0_r;
  assign z_o[10] = s10_0_r;
  assign z_o[11] = s11_r[0];
  assign z_o[12] = s12[0];
  assign z_o[13] = s13[0];
  assign z_o[14] = s14[0];
  assign z_o[15] = s15[0];
  assign z_o[16] = s16[0];
  assign z_o[17] = s17[0];
  assign z_o[18] = s18[0];
  assign z_o[19] = s19[0];
  assign z_o[20] = s20[0];
  assign z_o[21] = s21[0];
  assign z_o[22] = s22[0];
  assign z_o[46:23] = s23[23:0];
  assign z_o[47] = c23[23];

endmodule
