/*
===============================
bsg_mul_booth_iter.v
4/5/2019 sqlin16@fudan.edu.cn
===============================

This is an iterative booth encoded (radix-4) multiplier with configurable iteration stride.

*/
// define the booth encoder
// sel[0]: whether the bits is not zero
// sel[1]: how many left shifts are need to do
// sel[2]: sign
module bsg_booth_encoder #(
  parameter integer width_p = "inv"
)(
  input [2:0] source_bits_i
  ,input [width_p-1:0] pos_op_i
  ,input [width_p-1:0] neg_op_i
  ,output [width_p:0] sel_op_o
);
logic [2:0] sel;
always_comb begin
  unique case(source_bits_i)
    3'b000: sel = 3'b000;//eZERO
    3'b001: sel = 3'b001;//ePOS_1
    3'b010: sel = 3'b001;//ePOS_1
    3'b011: sel = 3'b011;//ePOS_2
    3'b100: sel = 3'b111;//eNEG_2
    3'b101: sel = 3'b101;//eNEG_1
    3'b110: sel = 3'b101;//eNEG_1
    3'b111: sel = 3'b000;//eZERO
  endcase
end
wire [width_p-1:0] p_n = sel[2] ?  neg_op_i : pos_op_i;
wire [width_p:0] o_t = sel[1] ? { p_n, 1'b0 } : {p_n[width_p-1],p_n };
assign sel_op_o = {(width_p+1){sel[0]}} & o_t;

endmodule

module bsg_mul_iterative_booth #(
  parameter integer width_p = "inv"
  ,parameter integer iter_step_p = "inv"
) (
  input clk_i
  ,input reset_i

  ,output ready_o

  ,input [width_p-1:0] opA_i
  ,input [width_p-1:0] opB_i
  ,input signed_i
  ,input v_i

  ,output [2*width_p-1:0] result_o
  ,output v_o
  ,input yumi_i
);

initial assert (width_p % iter_step_p != 0) else $error("iter_step_p should be a factor of width_p!");

localparam int iteration_lp = width_p / iter_step_p;

typedef enum [2:0] {eIDLE, eCAL, eSIG, eCPA, eDONE} state_e;
state_e current_state_r, current_state_n;
wire reset_internal = reset_i | yumi_i & current_state_r == eDONE;


// FSM

reg [`BSG_SAFE_CLOG2(iteration_lp)-1:0] cal_counter_r;
always_comb begin
  unique case(current_state_r) 
    eIDLE: begin
      if(v_i) current_state_n = eCAL;
      else current_state_n = eIDLE;
    end
    eCAL: begin
      if(cal_counter_r == '1 | iter_step_p == width_p) current_state_n = eSIG;
      else current_state_n = eCAL;
    end
    eSIG: current_state_n = eCPA;
    eCPA: current_state_n = eDONE;
    eDONE: current_state_n = eDONE;
    default: current_state_n = eIDLE;
  endcase
end
always_ff @(posedge clk_i) begin
  if(reset_internal)
    cal_counter_r <= '0;
  else if(current_state_r == eCAL) 
    cal_counter_r <= cal_counter_r + 1;
end


always_ff @(posedge clk_i) begin
  if(reset_internal)
    current_state_r <= eIDLE;
  else
    current_state_r <= current_state_n;
end

reg [width_p:0] opA_r;
reg             opA_is_unsigned;

reg [width_p:0] opB_r;
reg [width_p:0] neg_opB_r;

logic [width_p:0] cpa_opA;
logic [width_p:0] cpa_opB;
logic               cpa_carry;
wire [width_p+1:0] cpa_res = cpa_opA + cpa_opB + cpa_carry;


localparam booth_reg_len_lp = iter_step_p / 2;
wire [booth_reg_len_lp-1:0] [2:0] opB_booth_n;

wire [width_p:0] opB_n = {opB_i[width_p-1] & signed_i, opB_i};
always_ff @(posedge clk_i) begin
  if(reset_internal) begin
    opA_r <= '0;
    opB_r <= '0;
    neg_opB_r <= '0;
    opA_is_unsigned <= 1'b0;
  end
  else unique case(current_state_r)
    eIDLE: begin
      if(v_i) begin
        opA_r <= {opA_i, 1'b0};
        opA_is_unsigned <= (~signed_i) & opA_i[width_p-1];
        opB_r <= opB_n;
        neg_opB_r <= cpa_res[width_p:0];
      end
    end
    eCAL: begin
      opA_r <= opA_r >> iter_step_p;
    end
    default: begin

    end
  endcase
end

wire [booth_reg_len_lp-1:0] [width_p+1:0] sel_op_lo;

localparam wallace_tree_width_lp = 2*width_p;
wire [booth_reg_len_lp-1:0][wallace_tree_width_lp-1:0] wallace_input;

assign wallace_input[0] = {{(width_p - 2){sel_op_lo[0][width_p+1]}},sel_op_lo[0]};
for(genvar i = 1; i < booth_reg_len_lp; ++i) begin: WALLACE_TREE_INPUT
  assign wallace_input[i] = {{(width_p - 2*i - 2){sel_op_lo[i][width_p+1]}},sel_op_lo[i],(2*i)'(0)}; 
end // WALLACE_TREE_INPUT

for(genvar i = 0; i <booth_reg_len_lp; ++i) begin: BOOTH_ENCODER
  bsg_booth_encoder #(
    .width_p(width_p+1)
  )enc(
    .source_bits_i(opA_r[2*i+:3])
    ,.pos_op_i(opB_r)
    ,.neg_op_i(neg_opB_r)
    ,.sel_op_o(sel_op_lo[i])
  );
end // BOOTH_ENCODER

wire [wallace_tree_width_lp-1:0] w_resA;
wire [wallace_tree_width_lp-1:0] w_resB;

bsg_adder_wallace_tree #(
  .width_p(wallace_tree_width_lp)
  ,.iter_step_p(booth_reg_len_lp)
  ,.max_out_size_lp(wallace_tree_width_lp)
) wallace_tree(
  .op_i(wallace_input)
  ,.resA_o(w_resA)
  ,.resB_o(w_resB)
);

logic [wallace_tree_width_lp-1:0] csa_opA;
logic [wallace_tree_width_lp-1:0] csa_opB;

reg [wallace_tree_width_lp-iter_step_p-1:0] csa_acc_opA_r;
reg [wallace_tree_width_lp-iter_step_p-1:0] csa_acc_opB_r;

wire [wallace_tree_width_lp-1:0] csa_optA;
wire [wallace_tree_width_lp-1:0] csa_optB;
 
bsg_adder_carry_save_4_2 #(
  .width_p(wallace_tree_width_lp)
) csa_acc(
  .opA_i(csa_opA)
  ,.opB_i(csa_opB)
  ,.opC_i(csa_acc_opA_r)
  ,.opD_i(csa_acc_opB_r)

  ,.A_o(csa_optA)
  ,.B_o(csa_optB)
);

always_comb begin
  unique case(current_state_r)
    eSIG: begin 
      // For unsigned number,the MSB of booth encoding could +1, so opB should be added to higher bits under this situation.
      // For instance, opA is unsigned and opA = 8'b10000000, whose booth encoding is 1-2001. 
      // If opA is signed and opA=8'b10000000, the booth encoding is -2001
      csa_opA = {width_p{opA_is_unsigned}} & opB_r;
      csa_opB = '0;
    end
    eCAL: begin
      csa_opA = w_resA;
      csa_opB = w_resB;
    end
    default: begin
      csa_opA = '0;
      csa_opB = '0;
    end
  endcase
end

reg [iter_step_p-1:0] lowbits_remant_opA_r;
reg [iter_step_p-1:0] lowbits_remant_opB_r;
reg                   lowbits_carry_r;


always_ff @(posedge clk_i) begin
  if(reset_internal) begin
    csa_acc_opA_r <= '0;
    csa_acc_opB_r <= '0;
    lowbits_remant_opA_r <= '0;
    lowbits_remant_opB_r <= '0;
    lowbits_carry_r <= '0;
  end
  else unique case(current_state_r)
    eCAL: begin
      lowbits_remant_opA_r <= csa_optA[iter_step_p-1:0];
      csa_acc_opA_r <= csa_optA[2*width_p-1:iter_step_p];
      lowbits_remant_opB_r <= csa_optB[iter_step_p-1:0];
      csa_acc_opB_r <= csa_optB[2*width_p-1:iter_step_p];
      lowbits_carry_r <= cpa_res[iter_step_p];
    end
    eSIG:begin 
      csa_acc_opA_r <= csa_optA[width_p-1:0];
      csa_acc_opB_r <= csa_optB[width_p-1:0];
      lowbits_carry_r <= cpa_res[iter_step_p];
    end
    eCPA: begin
      csa_acc_opA_r <= cpa_res[width_p-1:0];
      csa_acc_opB_r <= '0;
    end
    default: begin
      
    end
  endcase
end

always_comb unique case(current_state_r)
  eIDLE: begin
    cpa_opA = ~opB_n;
    cpa_opB = width_p'(1);
    cpa_carry = lowbits_carry_r;
  end
  eCAL: begin
    cpa_opA = lowbits_remant_opA_r;
    cpa_opB = lowbits_remant_opB_r;
    cpa_carry = lowbits_carry_r;
  end
  eSIG: begin
    cpa_opA = lowbits_remant_opA_r;
    cpa_opB = lowbits_remant_opB_r;
    cpa_carry = lowbits_carry_r;
  end
  eCPA: begin
    cpa_opA = csa_acc_opA_r[width_p-1:0];
    cpa_opB = csa_acc_opB_r[width_p-1:0];
    cpa_carry = lowbits_carry_r;
  end
  default: begin
    cpa_opA = '0;
    cpa_opB = '0;
    cpa_carry = lowbits_carry_r;
  end
endcase

reg [width_p-1:0] result_low_r;
if(iter_step_p != width_p)
  always_ff @(posedge clk_i) begin
    if(reset_internal) begin
      result_low_r <= '0;
    end
    else unique case(current_state_r)
      eCAL: begin
        result_low_r <= {cpa_res[iter_step_p-1:0],result_low_r[width_p-1:iter_step_p]};
      end
      eSIG: begin
        result_low_r <= {cpa_res[iter_step_p-1:0],result_low_r[width_p-1:iter_step_p]};
      end
      default:begin

      end
    endcase
  end
else
  always_ff @(posedge clk_i) begin
    if(reset_internal) begin
      result_low_r <= '0;
    end
    else unique case(current_state_r)
      eCAL: begin
        result_low_r <= cpa_res[iter_step_p-1:0];
      end
      eSIG: begin
        result_low_r <= cpa_res[iter_step_p-1:0];
      end
      default:begin

      end
    endcase
  end
assign ready_o = current_state_r == eIDLE;
assign v_o = current_state_r == eDONE;

assign result_o = {csa_acc_opA_r[width_p-1:0],result_low_r};

endmodule

