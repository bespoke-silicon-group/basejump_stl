// -------------------------------------------------------
// -- bsg_div_srt_core.v
// -- sqlin16@fudan.edu.cn     05/18/2019
// -------------------------------------------------------
//
// This module performs SRT division, and currently only radix-4 division is supported.
// For signed integer division, divisor must be adjusted to this format before sent into this module:
//
// positive: 1, divisor[width_p-2:0], 0
// negative: 0, divisor[width_p-2:0], 0
//
// For unsigned number, divisor must be adjusted to:
// 1, divisor[width_p-2:0]
//
// There is no special requirement for dividend.
//
// Currently, Two CPA are used in the module. and the critical path is approximately a width_p + 1 CPA.
//
// Error conditions like overflow and zero divisor should be checked out of this module.
//
// TODO:
// 1. Squire root operation support 
// 2. Radix-8 SRT divider support
//
// Reference:
// Wey C L, Wang C P. Design of a fast radix-4 SRT divider and its VLSI implementation[J]. IEE Proceedings-Computers and Digital Techniques, 1999, 146(4): 205-210.
// -------------------------------------------------------


module bsg_div_srt_core #(
  parameter integer width_p = "inv"
  , parameter debug_p = 1
)(
  input clk_i
  ,input reset_i

  ,output ready_o
  ,input v_i

  ,input [2*width_p-1:0] dividend_i
  ,input [width_p-1:0] divisor_i
  ,input signed_i

  ,output [width_p:0] quotient_o
  ,output [width_p-1:0] remainder_o
  ,output v_o

  ,input yumi_i
);

typedef enum logic [2:0] {eIdle, eCal, eCPA, eCor, eDone} state_e;

initial assert(width_p % 2 == 0) else $error("For radix-4 divider, width_p can not be an odd number.");
initial assert(width_p > 7) else $error("There is no need to implement Radix-4 divider with so small width_p.");

state_e state_r, state_n;
reg [`BSG_SAFE_CLOG2(width_p):0] cal_cnt_r;

always_ff @(posedge clk_i) begin
  if(reset_i) state_r <= eIdle;
  else if(v_i & state_r == eIdle) state_r <= eCal;
  else if(state_r == eCal & cal_cnt_r == width_p/2) state_r <= eCPA;
  else if(state_r == eCPA) state_r <= eCor;
  else if(state_r == eCor) state_r <= eDone;
  else if(yumi_i & state_r == eDone) state_r <= eIdle;
end
// Update cal_cnt_r
always_ff @(posedge clk_i) begin
  if(reset_i) cal_cnt_r <= '0;
  else if(state_r == eIdle) cal_cnt_r <= '0;
  else if(state_r == eCal) cal_cnt_r <= cal_cnt_r + 1;

end

// Handshake signal

assign ready_o = state_r == eIdle;
assign v_o = state_r == eDone;


// Dividend is saved redundantly.
reg [2*width_p+2:0] dividend_r; 
wire [2*width_p+2:0] dividend_n;
assign dividend_n[width_p-1:0] = dividend_r[width_p-1:0];
reg dividend_sign_r;

reg [width_p+2:0] dividend_aux_csa_r;
wire [width_p+2:0] dividend_aux_csa_n;

localparam primary_csa_size_lp = 8;
reg [primary_csa_size_lp-1:0] dividend_partial_r; // Store the Most 8 significant bits of dividend from partial carry propagation, which is use to select the quotient.
wire [primary_csa_size_lp-1:0] dividend_partial_n;

reg [width_p:0] divisor_r;

reg signed_r;

// Quotient

reg [width_p+1:0] quotient_r;
reg quo_acc_opcode; // 1 for subtraction, 0 for addition
reg [width_p+1:0] quotient_increment_r;
logic [2:0] quotient_increment_n;

wire dividend_sign_bit = signed_i & dividend_i[2*width_p-1];
wire divisor_sign_bit = signed_i & ~divisor_i[width_p-1];

logic [width_p+2:0] dividend_cpa_input;
logic dividend_cpa_opcode;

wire [width_p+2:0] dividend_cpa = dividend_r[2*width_p+2:width_p] + dividend_cpa_input + dividend_cpa_opcode;
// Update 
always_ff @(posedge clk_i) begin
  if(reset_i) begin
    dividend_r <= '0;
    divisor_r <= (width_p+1)'(1);
    dividend_aux_csa_r <= '0;
    dividend_partial_r <= '0;
    dividend_sign_r <= '0;
    signed_r <= '0;
  end
  else unique case(state_r)
    eIdle: if(v_i) begin
      divisor_r <= {divisor_sign_bit, divisor_i};
      if(signed_i) begin
        dividend_r <= {{2{dividend_sign_bit}}, dividend_i,1'b0};
        dividend_partial_r <= {{2{dividend_sign_bit}}, dividend_i[2*width_p-1-:primary_csa_size_lp-2]};
      end
      else begin
        dividend_r <= {{3{dividend_sign_bit}}, dividend_i};
        dividend_partial_r <= {{3{dividend_sign_bit}}, dividend_i[2*width_p-1-:primary_csa_size_lp-3]}; // assert width_p > 4
      end
      dividend_aux_csa_r <= '0;
      dividend_sign_r <= dividend_sign_bit;
      signed_r <= signed_i;
    end
    eCal: begin
      dividend_r <= dividend_n << 2;
      dividend_aux_csa_r <= dividend_aux_csa_n << 2;
      dividend_partial_r <= dividend_partial_n << 2;
    end
    eCPA: begin
      dividend_r <= {dividend_cpa, (width_p)'(0)};
    end
    eCor: begin
      dividend_r <= {dividend_cpa, (width_p)'(0)};
    end
    default: begin

    end
  endcase
end
// Update of dividend_cpa_input
always_comb unique case(state_r)
  eCPA: begin
    dividend_cpa_input = dividend_aux_csa_r;
    dividend_cpa_opcode = 1'b0;
  end
  eCor: unique case ({dividend_r[2*width_p+2],dividend_sign_r, dividend_r[2*width_p+2:width_p+2] != 0})
    default: begin
      dividend_cpa_input = '0;
      dividend_cpa_opcode = '0;
    end
    3'b011: begin // dividend is negative while remainder is positive
      dividend_cpa_input = divisor_r[width_p] ? {divisor_r, 2'b00} :{~divisor_r, 2'b11};
      dividend_cpa_opcode = ~divisor_r[width_p];
    end
    3'b101: begin// dividend is positive while remainder is negative
      dividend_cpa_input = divisor_r[width_p] ? {~divisor_r, 2'b11} : {divisor_r, 2'b0};
      dividend_cpa_opcode = divisor_r[width_p];
    end
  endcase
  default: begin
    dividend_cpa_input = '0;
    dividend_cpa_opcode = 1'b0;
  end
endcase

assign remainder_o = signed_r ? dividend_r[2*width_p+2:width_p+3] : dividend_r[2*width_p+1:width_p+2];

/* -------------------------------------------------------
Quotient Selection
Four steps for selecting quotient:
  1. Approximate selection: determine the bit q_a in range [-2,1]
  2. Calculate approximate partial remainder (s - d*q_a) and (s - (q_a+1)*d)
  3. Quotient Correction q_b in [0,1] is selected based on approximate partial remainder.
  4. Aggregate Quotient. 
As for negative divisor, quotient is negated as well:
  1. q_a is in range [-1, 2].
  2. approximate partial remainder is (s - d*q_a) and (s - (q_a - 1)*d).
  3. q_b is in range [-1,0].
------------------------------------------------------- */

// First, select approximate quotient based on dividend_partial_r. 
wire q_sign = dividend_partial_r[primary_csa_size_lp-1]; 
wire q_diff = dividend_partial_r[primary_csa_size_lp-2-:3] != '1 & dividend_partial_r[primary_csa_size_lp-2-:3] != '0;

wire divisor_sign = divisor_r[width_p];

// Generate partial_remainder_0(s - d*q_a) and partial_remainder_1(s - (q_a+1)*d).

logic [width_p+2:0] partial_remainder_0_sum_vec;
logic [width_p+2:0] partial_remainder_0_car_vec;

logic [width_p+2:0] partial_remainder_1_sum_vec;
logic [width_p+2:0] partial_remainder_1_car_vec;

logic [width_p+2:0] quotient_times_divisor_0; // d*q_a
logic [width_p+2:0] quotient_times_divisor_1; // d*(q_a + 1) or d*(q_a - 1)
logic csa_opcode_0;
logic csa_opcode_1;

// Modification is needed for condition when divisor is negative.
always_comb unique case({divisor_sign, q_sign, q_diff})
  3'b000: begin // approximate quotient is 0
    quotient_times_divisor_0 = '0;
    quotient_times_divisor_1 = {~divisor_sign, ~divisor_sign, ~divisor_r};
    csa_opcode_0 = 1'b0;
    csa_opcode_1 = 1'b1;
  end
  3'b001: begin // approximate quotient is 1
    quotient_times_divisor_0 = {~divisor_sign,~divisor_sign,~divisor_r};
    quotient_times_divisor_1 = {~divisor_sign, ~divisor_r,1'b1};
    csa_opcode_0 = 1'b1;
    csa_opcode_1 = 1'b1;
  end
  3'b010: begin // approximate quotient is -1.
    quotient_times_divisor_0 = divisor_r;
    quotient_times_divisor_1 = '0;
    csa_opcode_0 = 1'b0;
    csa_opcode_1 = 1'b0;
  end
  3'b011: begin // approximate quotient is -2.
    quotient_times_divisor_0 = divisor_r << 1;
    quotient_times_divisor_1 = divisor_r;
    csa_opcode_0 = 1'b0;
    csa_opcode_1 = 1'b0;
  end
  3'b100: begin // approximate quotient is 0.
    quotient_times_divisor_0 = '0;
    quotient_times_divisor_1 = {2'b11, divisor_r};
    csa_opcode_0 = 1'b0;
    csa_opcode_1 = 1'b0;
  end
  3'b101: begin // approximate quotient is -1
    quotient_times_divisor_0 = {2'b11, divisor_r};
    quotient_times_divisor_1 = {1'b1, divisor_r, 1'b0};
    csa_opcode_0 = 1'b0;
    csa_opcode_1 = 1'b0;
  end
  3'b110: begin // approximate quotient is 1.
    quotient_times_divisor_0 = {~divisor_sign,~divisor_sign,~divisor_r};
    quotient_times_divisor_1 = '0;
    csa_opcode_0 = 1'b1;
    csa_opcode_1 = 1'b0;
  end
  3'b111: begin // approximate quotient is 2.
    quotient_times_divisor_0 = {~divisor_sign, ~divisor_r,1'b1}; // -(a << 1) = ({~a, 1'b1})
    quotient_times_divisor_1 = {~divisor_sign,~divisor_sign,~divisor_r};
    csa_opcode_0 = 1'b1;
    csa_opcode_1 = 1'b1;
  end
  default: begin
    quotient_times_divisor_1 = '0;
    quotient_times_divisor_0 = '0;
    csa_opcode_0 = 1'b0;
    csa_opcode_1 = 1'b1;
  end
endcase

// Two CSA is needed for generate partial_remainder_0 and partial_remainder_1:

bsg_adder_carry_save #(
  .width_p(width_p+3)
) i_patial_remainder_0_csa (
  .opA_i(dividend_r[2*width_p+2:width_p])
  ,.opB_i(dividend_aux_csa_r)
  ,.opC_i(quotient_times_divisor_0)

  ,.res_o(partial_remainder_0_sum_vec)
  ,.car_o(partial_remainder_0_car_vec)
);

bsg_adder_carry_save #(
  .width_p(width_p+3)
) i_patial_remainder_1_csa (
  .opA_i(dividend_r[2*width_p+2:width_p])
  ,.opB_i(dividend_aux_csa_r)
  ,.opC_i(quotient_times_divisor_1)

  ,.res_o(partial_remainder_1_sum_vec)
  ,.car_o(partial_remainder_1_car_vec)
);

// Two primary_csa_size_lp bit CPA is needed for selecting quotient correction.
wire [primary_csa_size_lp-1:0] partial_remainder_pca_0 = partial_remainder_0_sum_vec[width_p+2-:primary_csa_size_lp] + partial_remainder_0_car_vec[width_p+1-:primary_csa_size_lp]; // assert width_p >= 7
wire [primary_csa_size_lp-1:0] partial_remainder_pca_1 = partial_remainder_1_sum_vec[width_p+2-:primary_csa_size_lp] + partial_remainder_1_car_vec[width_p+1-:primary_csa_size_lp];

// Now, select quotient correction.

wire [3:0] rom_addr_divisor_part = divisor_r[width_p-2-:4] ^ {4{divisor_r[width_p]}};


wire [6:0] rom_addr = {partial_remainder_pca_0[primary_csa_size_lp-5-:3], rom_addr_divisor_part};
wire rom_out;
bsg_div_srt_sel_rom #(
  .width_p(1)
  ,.addr_width_p(7)
) sel_rom (
  .addr_i(rom_addr)
  ,.data_o(rom_out)
);

//wire q_corr = (~partial_remainder_pca_0[primary_csa_size_lp-1]) & (partial_remainder_pca_0[primary_csa_size_lp-3] | partial_remainder_pca_0[primary_csa_size_lp-4] | partial_remainder_pca_0[primary_csa_size_lp-5] & (~divisor_r[width_p-2]));
wire q_corr = (~partial_remainder_pca_0[primary_csa_size_lp-1]) & (partial_remainder_pca_0[primary_csa_size_lp-3] | partial_remainder_pca_0[primary_csa_size_lp-4] | rom_out);

assign dividend_partial_n = q_corr ? partial_remainder_pca_1 : partial_remainder_pca_0;
assign dividend_n[2*width_p + 2: width_p] = q_corr ? partial_remainder_1_sum_vec : partial_remainder_0_sum_vec;
assign dividend_aux_csa_n = q_corr ? {partial_remainder_1_car_vec[width_p+1:0], csa_opcode_1} : {partial_remainder_0_car_vec[width_p+1:0], csa_opcode_0};

// Using q_corr, q_sign and q_diff to generate quotient:

logic [2:0] quotient_increment_n_pos; // divisor is positive
logic [2:0] quotient_increment_n_neg; // divisor is negative

always_comb unique case({q_corr, q_sign, q_diff})
  3'b000: quotient_increment_n_pos = '0;
  3'b001: quotient_increment_n_pos = 3'b001;
  3'b010: quotient_increment_n_pos = '1;
  3'b011: quotient_increment_n_pos = 3'b110;
  3'b100: quotient_increment_n_pos = 3'b001;
  3'b101: quotient_increment_n_pos = 3'b010;
  3'b110: quotient_increment_n_pos = '0;
  3'b111: quotient_increment_n_pos = '1;
  default: quotient_increment_n_pos = '0;
endcase

always_comb unique case({q_corr, q_sign, q_diff})
  3'b000: quotient_increment_n_neg = '0;
  3'b001: quotient_increment_n_neg = '1;
  3'b010: quotient_increment_n_neg = 3'b001;
  3'b011: quotient_increment_n_neg = 3'b010;
  3'b100: quotient_increment_n_neg = '1;
  3'b101: quotient_increment_n_neg = 3'b110;
  3'b110: quotient_increment_n_neg = '0;
  3'b111: quotient_increment_n_neg = 3'b001;
  default: quotient_increment_n_neg = '0;
endcase

assign quotient_increment_n = divisor_r[width_p] ? quotient_increment_n_neg : quotient_increment_n_pos;

logic [width_p+1:0] quotient_cpa_input;

wire [width_p+1:0] quotient_cpa = quotient_r + quotient_cpa_input;

// Accumulate Quotient
always_ff @(posedge clk_i) begin
  if(reset_i) begin
    quotient_r <= '0;
    quo_acc_opcode <= '0;
    quotient_increment_r <= '0;
  end
  else if(state_r == eIdle & v_i) begin
    quotient_r <= '0;
    quo_acc_opcode <= '0;
    quotient_increment_r <= '0;
  end
  else if(state_r == eCal) begin
    quotient_r <= quotient_cpa << 2;
    quotient_increment_r <= {{(width_p-1){quotient_increment_n[2]}}, quotient_increment_n};
  end
  else if(state_r == eCPA | state_r == eCor) begin
    quotient_r <= quotient_cpa; // There is no need to right shift because of no incoming accumulation.
  end
end

assign quotient_o = quotient_r[width_p:0];
// Update of quotient_cpa_input
always_comb unique case(state_r) 
  eIdle: begin
    quotient_cpa_input = '0;
  end
  eCal: begin
    quotient_cpa_input = quotient_increment_r;
  end
  eCPA: begin
    quotient_cpa_input = quotient_increment_r;
  end
  eCor: unique case ({dividend_r[2*width_p+2],dividend_sign_r, dividend_r[2*width_p+2:width_p+2] != 0})
    default: begin
      quotient_cpa_input = '0;
    end
    3'b011: begin // dividend is negative while remainder is positive
      quotient_cpa_input = divisor_r[width_p] ? '1 : (width_p+2)'(1);
    end
    3'b101: begin// dividend is positive while remainder is negative
      quotient_cpa_input = divisor_r[width_p] ? (width_p+2)'(1) :'1;
    end
  endcase
  default: begin
    quotient_cpa_input = '0;
  end
endcase

if(debug_p) begin: DEBUG
  integer i = 0;
  always_ff @(posedge clk_i) begin
    $display("========== DIV SRT CORE ==========");
    $display("Cycle:%d",i);
    $display("state_r:%s",state_r.name());
    $display("dividend_r:%b",dividend_r);
    $display("dividend_aux_r:%b",dividend_aux_csa_r);
    $display("dividend_partial_r:%b",dividend_partial_r);
    $display("actual dividend:%b", dividend_r + {dividend_aux_csa_r, (width_p)'(0)});
    $display("divisor_r:%b",divisor_r);
    $display("partial_remainder_pca_0:%b",partial_remainder_pca_0);
    $display("full version of p_pca_0:%b",partial_remainder_0_sum_vec + (partial_remainder_0_car_vec << 1));
    $display("q selection bits:%b",{q_corr, q_sign, q_diff});
    $display("q selection:%d",quotient_increment_n);
    $display("quotient_times_divider_0:%b",quotient_times_divisor_0);
    $display("quotient_times_divider_1:%b",quotient_times_divisor_1);
    $display("dividend_partial_n:%b",dividend_partial_n);
    $display("quotient:%b",quotient_r);
    $display("dividend_cpa_input:%b",dividend_cpa_input);
    i = i + 1;
  end
end
endmodule
