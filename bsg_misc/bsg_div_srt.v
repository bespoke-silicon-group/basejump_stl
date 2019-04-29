/*
======================
bsg_div_srt.v
04/16/2019 sqlin16@fudan.edu.cn
=====================
A radix-4 SRT divider using carry save addition to store intermittent remainder.
Design doc: https://docs.google.com/document/d/10YhNfc81pXje2fKQs5IgFZxHONHRqtQdeLGdTJkAAZU/edit?usp=sharing
*/

module bsg_div_srt #(
  parameter integer width_p = "inv"
  ,parameter debug_p = 0
)(

  input clk_i
  ,input reset_i
  
  //handshake signal
  ,output ready_o
  ,input v_i

  ,input [2*width_p-1:0] dividend_i
  ,input [width_p-1:0] divisor_i
  ,input signed_i

  ,output [width_p-1:0] quotient_o
  ,output [width_p-1:0] remainder_o

  ,output v_o

  ,output error_o
  ,output error_type_o // 0: divisor is zero, 1: result is overflow

  ,input yumi_i       // accept result.
  ,input yumi_error_i // accept error.
);

typedef enum [3:0] {eIDLE,eNeg, eALIGN, eCAL, eCPA, eADJREM, eADJQUO, eSHIFT, eDONE, eERROR} state_e;

state_e current_state_r, current_state_n;
wire reset_internal = reset_i | (yumi_i & current_state_r == eDONE) | (yumi_error_i & current_state_r == eERROR);

always_ff @(posedge clk_i) begin
  if(reset_internal)
    current_state_r <= eIDLE;
  else
    current_state_r <=  current_state_n;
end

assign error_o = current_state_r == eERROR;
assign ready_o = current_state_r == eIDLE;

wire is_overflow;

// dividend is stored in carry saved form.
reg [2*width_p+2:0] dividendA_r;
reg [width_p+2:0] dividendB_r;
reg [width_p:0] divisor_r;
reg [width_p:0] divisor_neg_r;
reg [`BSG_SAFE_CLOG2(width_p/2):0] calc_counter_r;
// Switching logic of FSM.
always_comb unique case(current_state_r)
  eIDLE: current_state_n = v_i ? eNeg : eIDLE;
  eNeg: current_state_n = divisor_r == '0 ? eERROR : eALIGN;
  eALIGN: current_state_n = eCAL;
  eCAL: begin
    if(is_overflow) current_state_n = eERROR;
    else current_state_n = calc_counter_r[`BSG_SAFE_CLOG2(width_p/2)] ? eCPA : eCAL;
  end
  eCPA: current_state_n = is_overflow ? eERROR : eADJREM;
  eADJREM: current_state_n = eADJQUO;
  eADJQUO: current_state_n = eSHIFT;
  eSHIFT: current_state_n = eDONE;
  eDONE: current_state_n = eDONE;
  eERROR: current_state_n = eERROR;
  default: current_state_n = eERROR;
endcase

assign error_type_o = calc_counter_r != '0;

wire [width_p+1:0] cpa_out; // output of carry propagate adder

wire [width_p+2:0] dividendA_high_n; // high bits of dividendA, where remainder is stored.
wire [width_p+2:0] dividendB_n; // carry saved addition output

// counting leading sign bits(zero for the positive or one for the negative)
logic [width_p:0] clz_input; // counting leading zero input
wire [`BSG_SAFE_CLOG2(width_p):0] leading_zero;
wire [width_p-1:0] leading_zero_a_li = clz_input[width_p] ? ~clz_input[width_p-1:0] :clz_input[width_p-1:0];
bsg_counting_leading_zeros #(
  .width_p(width_p)
) leading_zero_counter (
  .a_i(leading_zero_a_li)
  ,.num_zero_o(leading_zero[`BSG_SAFE_CLOG2(width_p)-1:0])
);

// As for condition where input is '0 and '1, leading zero counter outputs zero, which is invalid.
// '0 and '1 input must be handled manually.
assign leading_zero[`BSG_SAFE_CLOG2(width_p)] = clz_input[width_p] ? clz_input == '1 : clz_input == '0;

reg [`BSG_SAFE_CLOG2(width_p):0] divisor_leading_zero_r;
reg [`BSG_SAFE_CLOG2(width_p):0] dividend_leading_zero_r;
// determine clz_input 
always_comb unique case(current_state_r)
  eNeg: clz_input = dividendA_r[2*width_p-:width_p+1];
  default: clz_input = divisor_r;
endcase

reg dividend_sign_r; // for remainder's sign modification
// update operand registers
always_ff @(posedge clk_i) begin
  if(reset_internal) begin
    dividendA_r <= '0;
    dividendB_r <= '0;
    divisor_r <= width_p'(1);
    divisor_neg_r <= '1;
    divisor_leading_zero_r <= '0;
    dividend_leading_zero_r <= '0;
    dividend_sign_r <= 1'b0;
  end  
  else unique case(current_state_r) 
    eIDLE: begin
      if(v_i) begin
        dividendA_r <= {{3{signed_i & dividend_i[2*width_p-1]}}, dividend_i};
        divisor_r <= {signed_i & divisor_i[width_p-1], divisor_i};
        dividend_sign_r <= signed_i & dividend_i[2*width_p-1];
      end
    end
    eNeg: begin
      divisor_neg_r <= cpa_out[width_p:0];
      dividend_leading_zero_r <= leading_zero;
    end
    eALIGN: begin
      divisor_neg_r <= divisor_neg_r << leading_zero;
      divisor_r <= divisor_r << leading_zero;
      dividendA_r <= dividendA_r << leading_zero;
      divisor_leading_zero_r <= leading_zero;
    end
    eCAL: begin
      dividendA_r <= {dividendA_high_n[width_p:0], dividendA_r[width_p-1:0], 2'b0};
      dividendB_r <= {dividendB_n << 3};
    end
    eCPA: begin 
      dividendA_r[2*width_p+2-:width_p+2] <= cpa_out;
    end
    eADJREM: begin
      dividendA_r[2*width_p+2-:width_p+2] <= cpa_out;
    end
    eSHIFT: begin
      dividendA_r[2*width_p+2-:width_p+2] <= {dividendA_r[2*width_p+2-:width_p+2] >> divisor_leading_zero_r} | ({(width_p+2){dividendA_r[2*width_p+2]}}  << (width_p + 2 - divisor_leading_zero_r));
    end
    default: begin

    end
  endcase
end
// update calc_counter_r
always_ff @(posedge clk_i) begin
  if(reset_internal)
    calc_counter_r <= '0;
  else if(current_state_r == eCAL) begin
    calc_counter_r <= calc_counter_r + 1;
  end
end

// quotient
reg [width_p+1:0] quotient_r;

// selection logic
localparam primary_cpa_size = width_p+3;

wire [7:0] primary_cpa_out; // partial carry propagate

// Most 8 significant bits are determined for selection of quotient bit.
if(primary_cpa_size >= 8) 
  assign primary_cpa_out = dividendA_r[2*width_p+2-:8] + dividendB_r[width_p+2-:8]; // p
else // if operand width_ < 8, we have to align the output same with condition width_p >= 8.
  assign primary_cpa_out = (dividendA_r[2*width_p+2-:primary_cpa_size] + dividendB_r) << (8-primary_cpa_size);

// Overflow Judgement!
assign is_overflow = (current_state_r == eCAL & primary_cpa_out[6] != primary_cpa_out[7])  // overflow when calculation
                    | quotient_r[width_p+1] != quotient_r[width_p] // overflow when aggregating quotient
                    | dividend_leading_zero_r < divisor_leading_zero_r; //overflow when aligning

// selecting quotient from ROM, please check the design docs for detail.
wire [1:0] rom_out;
wire [7:0] rom_addr;
assign rom_addr[7:3] = primary_cpa_out[7] ? -primary_cpa_out[6:2] : primary_cpa_out[6:2];
assign rom_addr[2:0] = divisor_r[width_p] ? divisor_neg_r[width_p-2-:3] : divisor_r[width_p-2-:3];

bsg_div_srt_sel_rom #(
  .width_p(2)
  ,.addr_width_p(8)
)sel_rom(
  .addr_i(rom_addr)
  ,.data_o(rom_out)
);

// selected quotient times divisor
wire partial_product_signed = primary_cpa_out[7] ^ divisor_r[width_p];
logic [width_p+2:0] partial_product;
// select partial product (which is subtracted from current remainder later) according to booth encoding.
always_comb unique case(rom_out)
  2'b00 : partial_product = '0;
  2'b01 : partial_product = partial_product_signed ? {{2{divisor_r[width_p]}},divisor_r}: {{2{divisor_neg_r[width_p]}},divisor_neg_r};
  2'b11 : partial_product = partial_product_signed ? {divisor_r[width_p], divisor_r, 1'b0} : {divisor_neg_r[width_p],divisor_neg_r,1'b0};
  default: partial_product = '0;
endcase
// CSA for partial product subtraction
bsg_adder_carry_save #(
  .width_p(width_p+3)
) csa (
  .opA_i(dividendA_r[2*width_p+2-:width_p+3])
  ,.opB_i(dividendB_r)
  ,.opC_i(partial_product)

  ,.res_o(dividendA_high_n)
  ,.car_o(dividendB_n)
);

reg [1:0] div_rem_sign_info_r; // for adjustment of quotient
always_ff @(posedge clk_i) begin
  if(reset_internal) div_rem_sign_info_r <= '0;
  else div_rem_sign_info_r <= {dividend_sign_r, dividendA_r[2*width_p+2]};
end

// Carry propagate adder
logic [width_p+1:0] cpa_opA;
logic [width_p+1:0] cpa_opB;
assign cpa_out = cpa_opA + cpa_opB;
always_comb unique case(current_state_r) 
  eNeg: begin
    // negate divisor
    cpa_opA = ~divisor_r;
    cpa_opB = width_p'(1);
  end
  eCAL: begin
    // accumulate quotient
    cpa_opA = quotient_r << 2;
    unique case({partial_product_signed,rom_out})
      3'b000: cpa_opB = (width_p+2)'(0);
      3'b001: cpa_opB = (width_p+2)'(1);
      3'b011: cpa_opB = (width_p+2)'(2);
      3'b111: cpa_opB = (width_p+2)'(-2);
      3'b101: cpa_opB = (width_p+2)'(-1);
      default: cpa_opB = (width_p+2)'(0);
    endcase
  end
  eCPA: begin
    // recover remainder
    // there is no need to include the LSB of dividendA/B because it's zero and won't affect the final result.
    cpa_opA = dividendA_r[2*width_p+2-:width_p+2];
    cpa_opB = dividendB_r[width_p+2-:width_p+2];
  end
  eADJREM: begin
    // adjust remainder according to sign bit of dividend and remainder
    cpa_opA = dividendA_r[2*width_p+2-:width_p+2];
    if(dividendA_r[2*width_p+1-:width_p] != '0)
      unique case({dividend_sign_r, dividendA_r[2*width_p+2]})
        2'b00 : cpa_opB = '0;
        2'b11 : cpa_opB = '0;
        2'b10 : cpa_opB = {divisor_r[width_p] ? divisor_r : divisor_neg_r, 1'b0};
        2'b01:  cpa_opB = {divisor_r[width_p] ? divisor_neg_r : divisor_r, 1'b0};
      endcase
    else 
      cpa_opB = '0;
  end
  eADJQUO: begin
    // adjust quotient correspondingly.
    cpa_opA = quotient_r;
    if(dividendA_r[2*width_p+1-:width_p] != '0)
      unique case(div_rem_sign_info_r)
        2'b00 : cpa_opB = '0;
        2'b11 : cpa_opB = '0;
        2'b10 : cpa_opB = (width_p+2)'(divisor_r[width_p] ? -1 : 1);
        2'b01:  cpa_opB = (width_p+2)'(divisor_r[width_p] ? 1 : -1);
      endcase
    else 
      cpa_opB = '0;
  end
  default: begin
    cpa_opA = '0;
    cpa_opB = '0;
  end
endcase

// Update quotient
always_ff @(posedge clk_i) begin
  if(reset_internal)
    quotient_r <= '0;
  else if(current_state_r == eCAL | current_state_r == eADJQUO) begin
    quotient_r <= cpa_out; 
  end
end

assign quotient_o = quotient_r[width_p-1:0];
assign remainder_o = dividendA_r[2*width_p+1-:width_p];
assign v_o = current_state_r == eDONE;

// Debug information
if(debug_p)
  always_ff @(posedge clk_i) begin
    $display("===========================");
    $display("current state:%s",current_state_r.name());
    $display("Divisor:%b",divisor_r);
    $display("Quotient:%b",quotient_r);
    $display("primary_cpa_out:%b",primary_cpa_out);
    $display("sel_signal:%b",{partial_product_signed,rom_out});
    $display("rom_addr:%b",rom_addr);
    $display("partial_product:%b",partial_product);
    $display("cpa_out:%b",cpa_out);
    $display("leading_zero:%b",leading_zero);
    $display("dividendA_r:%b",dividendA_r);
    $display("dividendB_r:%b",dividendB_r);
    $display("divisor_leading_zero_r:%b",divisor_leading_zero_r);
    $display("dividend_leading_zero_r:%b",dividend_leading_zero_r);
    $display("clz_input:%b",clz_input);
    $display("leading_zero:%b",leading_zero);
    $display("leading_zero_a_li:%b",leading_zero_a_li);
    $display("sign_error:%b",{dividend_sign_r, dividendA_r[2*width_p+2]});
  end

endmodule

