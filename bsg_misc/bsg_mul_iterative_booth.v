/*
===============================
bsg_mul_booth_iterative_booth.v
4/5/2019 sqlin16@fudan.edu.cn
===============================

This is an iterative booth encoded (radix-4) multiplier with configurable iteration stride.

You determine determine the parameter according to this PPA regression: (90nm, width_p=32)
https://docs.google.com/spreadsheets/d/153VAgxY73i40jKyiOYy6s0p_SKkJzZHyb9c1GWvO83A/edit#gid=0

Latency = 32 / stride_p + 32 / cpa_stride_p

*/

module bsg_mul_iterative_booth  #(
  parameter integer width_p = 32
  ,parameter integer stride_p = 32
  ,parameter integer cpa_stride_p = 32
  ,parameter bit pipelined_p = 0
  ,parameter bit debug_p = 0
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

if(pipelined_p) begin
  bsg_mul_iterative_booth_pipelined #(
    .width_p(width_p)
    ,.stride_p(stride_p)
    ,.cpa_stride_p(cpa_stride_p)
    ,.debug_p(debug_p)
  ) mul_pipelined (.*);
  assign ready_o = 1'b1;
end
else begin
  bsg_mul_iterative_booth_unpipelined #(
    .width_p(width_p)
    ,.stride_p(stride_p)
    ,.cpa_stride_p(cpa_stride_p)
    ,.debug_p(debug_p)
  ) mul_unpipelined (.*);
end

`ifdef COCOTB_SIM
  initial begin
    $dumpfile("test.vcd");
    $dumpvars();
  end
`endif
endmodule

// define the booth encoder
// sel[0]: whether the bits is not zero
// sel[1]: how many left shifts are need to do
// sel[2]: sign
module bsg_booth_encoder (
  input [2:0] source_bits_i
  ,output logic [2:0] code_o
);

wire all_zero = source_bits_i == '0;
wire all_one = source_bits_i == '1;
assign code_o[0] = ~all_zero && ~all_one;
assign code_o[2] = ~all_one && source_bits_i[2];
assign code_o[1] = source_bits_i == 3'b011 || source_bits_i == 3'b100;

/*always_comb begin
  unique case(source_bits_i)
    3'b000: code_o = 3'b000;//eZERO
    3'b001: code_o = 3'b001;//ePOS_1
    3'b010: code_o = 3'b001;//ePOS_1
    3'b011: code_o = 3'b011;//ePOS_2
    3'b100: code_o = 3'b111;//eNEG_2
    3'b101: code_o = 3'b101;//eNEG_1
    3'b110: code_o = 3'b101;//eNEG_1
    3'b111: code_o = 3'b000;//eZERO
  endcase
end
*/
endmodule

module bsg_booth_selector #(
  parameter integer width_p = "inv"
  ,parameter bit initial_p = 0
)(
  input [width_p:0] pos_op_i // original operand.
  ,input [2:0] code_i

  ,output [width_p+2+initial_p:0] partial_product_o
);

wire [width_p:0] zero_or_not = {(width_p+1){code_i[0]}} & pos_op_i;
wire [width_p:0] sht = code_i[1] ? {zero_or_not[width_p-1:0], 1'b0} : zero_or_not;
wire [width_p:0] pd = {(width_p+1){code_i[2]}} ^ sht;


wire e = pos_op_i[width_p] ? pd[width_p] : code_i[2]; // E is used for sign extension.
if(!initial_p)
  assign partial_product_o = {1'b1, ~e, pd};
else
  assign partial_product_o = {~e, e, e, pd};
  
endmodule

// this module generates the partial product, and at the same time compress the partial product with wallace tree.
module bsg_mul_booth_compressor #(
  parameter integer width_p = "inv"
  ,parameter integer stride_p = "inv"
  ,parameter bit debug_p = 0
  ,localparam integer output_size_lp = (width_p + stride_p + 4) > 2*width_p ? 2*width_p : (width_p + stride_p + 4)
)(
  input [width_p:0] opA_i
  ,input [2:0][width_p/2-1:0] opB_i
  ,input [width_p+3:0] csa_opA_i
  ,input [width_p+3:0] csa_opB_i
  ,input last_sign_correction_i

  ,output [output_size_lp-1:0] A_o
  ,output [output_size_lp-1:0] B_o

  ,input clk_i // for debug
);
localparam booth_step_lp = stride_p / 2;
if (booth_step_lp == 1) begin: NO_WALLACE_TREE
  wire [width_p+2:0] partial_product_lo;
  bsg_booth_selector #(
    .width_p(width_p)
    ,.initial_p(0)
  ) unique_selector (
    .pos_op_i(opA_i)
    ,.code_i({opB_i[2][0], opB_i[1][0], opB_i[0][0]})
    ,.partial_product_o(partial_product_lo[width_p+2:0])
  );
  wire [output_size_lp-1:0] csa_op;
  if(width_p + stride_p + 4 < 2*width_p) begin
    assign csa_op = {1'b0, partial_product_lo, (stride_p-1)'(0), last_sign_correction_i};
  end
  else begin
    assign csa_op = {partial_product_lo[width_p-1:0], (stride_p-1)'(0), last_sign_correction_i};
  end
  wire [output_size_lp-1:0] csa_res_o;
  wire [output_size_lp-1:0] csa_car_o;
  bsg_adder_carry_save #(
    .width_p(output_size_lp)
  ) unique_csa (
    .opA_i(csa_opA_i)
    ,.opB_i(csa_opB_i)
    ,.opC_i(csa_op)
    ,.res_o(csa_res_o)
    ,.car_o(csa_car_o)
  );
  assign A_o = csa_res_o;
  assign B_o = {csa_car_o[output_size_lp-2:0], 1'b0};
  if(debug_p) always_ff @(posedge clk_i) begin
      //$display("Partial Sum:%b",partial_product_lo);
  end
end
else begin: WALLACE_TREE
  // Wallace Tree 
  wire [booth_step_lp-1:0][width_p+2:0] partial_product_lo;
  wire [booth_step_lp-1:0] sign_correction;
  wire [1:0][width_p+3:0] base_reg;
  for(genvar i = 0; i < booth_step_lp; ++i) begin: BOOTH_SELECTOR
    bsg_booth_selector #(
      .width_p(width_p)
      ,.initial_p(0)
      ) booth_selector (
      .pos_op_i(opA_i)
      ,.code_i({opB_i[2][i], opB_i[1][i], opB_i[0][i]})
      ,.partial_product_o(partial_product_lo[i])
    );
    
    if (i == 0)
      assign sign_correction[i] = last_sign_correction_i;
    else 
      assign sign_correction[i] = opB_i[2][i-1];
  end

  assign base_reg[0] = csa_opA_i;
  assign base_reg[1] = csa_opB_i;

  bsg_multiplier_compressor #(
    .width_p(width_p)
    ,.stride_p(stride_p)
  ) cps (
    .base_i(base_reg)
    ,.psum_i(partial_product_lo)
    ,.sign_modification_i(sign_correction)
    ,.outA_o(A_o)
    ,.outB_o(B_o)
  );
  if(debug_p) begin
    always_ff @(posedge clk_i) begin
      $display("=======================");
      for(int i = 0; i < booth_step_lp; ++i)
        $display("partial_product_lo[%d]:%b", i, partial_product_lo[i]);
      $display("A_o:%b", A_o);
      $display("B_o:%b", B_o);
      $display("csa_opA_i:%b", csa_opA_i);
      $display("csa_opB_i:%b", csa_opB_i);
    end
  end
end

endmodule

module bsg_mul_iterative_booth_unpipelined #(
  parameter integer width_p = 32
  ,parameter integer stride_p = 32
  ,parameter integer cpa_stride_p = 32
  ,parameter bit debug_p = 0
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

  localparam cpa_level_lp = width_p / cpa_stride_p;
  localparam booth_step_lp = stride_p / 2;

  localparam gather_level_lp = width_p % stride_p ? width_p / stride_p + 1 : width_p / stride_p;
  localparam last_shift_count_lp = width_p % stride_p ? width_p % stride_p : stride_p;

  typedef enum logic [1:0] {eIdle, eCal, eCPA, eDone} state_e;

  state_e state_r;

  wire calc_is_done;
  wire cpa_is_done;

  // FSM
  always_ff @(posedge clk_i) begin
    if(reset_i) state_r <= eIdle;
    else unique case(state_r)
      eIdle: if(v_i) state_r <= eCal;
      eCal: if(calc_is_done) state_r <= eCPA;
      eCPA: if(cpa_is_done) state_r <= eDone;
      eDone: if(yumi_i) state_r <= eIdle;
    endcase
  end
  // Counter for eCal and eCPA. 
  localparam state_cnt_size_lp = cpa_level_lp + gather_level_lp;
  reg [`BSG_SAFE_CLOG2(state_cnt_size_lp)-1:0] state_cnt_r;

  assign calc_is_done = state_cnt_r == (gather_level_lp-1);
  assign cpa_is_done = state_cnt_r == (state_cnt_size_lp-1);
  // Counter update
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      state_cnt_r <= '0;
    end
    else if(state_r == eIdle && v_i) begin
      state_cnt_r <= '0;
    end
    else if(state_r == eCal) begin
      state_cnt_r <= state_cnt_r + 1;
    end
    else if(state_r == eCPA) begin
      state_cnt_r <= state_cnt_r + 1;
    end
  end

  reg [width_p:0] opA_r;
  reg [2:0] [width_p/2-1:0] opB_r;
  reg partial_sign_correction_r;
  wire [2:0] [width_p/2:0] opB_n;

  wire opB_signed = signed_i & opB_i[width_p-1];
  wire [width_p+2:0] extend_opB_i = {opB_signed, opB_signed, opB_i, 1'b0};
  wire [width_p:0] extend_opA_i = {opA_i[width_p-1] & signed_i, opA_i};

  // Booth encoder
  for(genvar i = 0; i <= width_p/2; ++i) begin
    bsg_booth_encoder encoder(
      .source_bits_i(extend_opB_i[2*i+:3])
      ,.code_o({opB_n[2][i], opB_n[1][i], opB_n[0][i]})
    );
  end

  wire [2:0][width_p/2-1:0] opB_update_n;

  if(stride_p != width_p) begin
    for(genvar i = 0; i < 3; ++i)
      assign opB_update_n[i] = {booth_step_lp'(0),opB_r[i][width_p/2-1:booth_step_lp]};
  end
  else begin
    for(genvar i = 0; i < 3; ++i)
      assign opB_update_n[i] = booth_step_lp'(0);
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      opA_r <= '0;
      opB_r <= '0;
      partial_sign_correction_r <= '0;
    end
    else if(state_r == eIdle && v_i) begin
      opA_r <= extend_opA_i;
      opB_r[0] <= opB_n[0][width_p/2:1];
      opB_r[1] <= opB_n[1][width_p/2:1];
      opB_r[2] <= opB_n[2][width_p/2:1];
      partial_sign_correction_r <= opB_n[2][0];
    end
    else if(state_r == eCal) begin
      opB_r <= opB_update_n;
      partial_sign_correction_r <= opB_r[2][booth_step_lp-1];
    end
  end

  // Partial Sum 
  // stride_p: for partial products which is most shifted. 
  // width_p + 1 + 2: the size of partial product.
  // 1: carry 
  localparam csa_reg_width_lp = stride_p + 4 + width_p;

  reg [csa_reg_width_lp-1:0] csa_opA_r;
  reg [csa_reg_width_lp-1:0] csa_opB_r;

  wire [csa_reg_width_lp-1:0] csa_opA_n;
  wire [csa_reg_width_lp-1:0] csa_opB_n;

  wire [width_p+3:0] csa_opA_init;

  bsg_booth_selector #(
    .width_p(width_p)
    ,.initial_p(1)
  ) first_selector (
    .pos_op_i(extend_opA_i)
    ,.code_i({opB_n[2][0], opB_n[1][0], opB_n[0][0]})
    ,.partial_product_o(csa_opA_init)
  );

  localparam csa_tree_width_lp = csa_reg_width_lp > 2*width_p ? 2*width_p : csa_reg_width_lp;

  wire [csa_tree_width_lp-1:0] aggregation_outA;
  wire [csa_tree_width_lp-1:0] aggregation_outB;
  // Setup aggregation units

  bsg_mul_booth_compressor #(
    .width_p(width_p)
    ,.stride_p(stride_p)
    ,.debug_p(debug_p)
  ) compressor (
    .opA_i(opA_r)
    ,.opB_i(opB_r)
    ,.csa_opA_i(csa_opA_r[csa_reg_width_lp-1:stride_p])
    ,.csa_opB_i(csa_opB_r[csa_reg_width_lp-1:stride_p])
    ,.last_sign_correction_i(partial_sign_correction_r)

    ,.A_o(aggregation_outA)
    ,.B_o(aggregation_outB)
    ,.clk_i(clk_i)
  );

  // Partial Adder for tail 
  wire [stride_p-1:0] tail_cpa_opA;
  wire [stride_p-1:0] tail_cpa_opB;
  wire [stride_p:0] tail_cpa_opt = tail_cpa_opA + tail_cpa_opB; 
  assign tail_cpa_opA = state_cnt_r == gather_level_lp ? csa_opA_r[last_shift_count_lp-1:0] : csa_opA_r[stride_p-1:0];
  assign tail_cpa_opB = state_cnt_r == gather_level_lp ? csa_opB_r[last_shift_count_lp-1:0] : csa_opB_r[stride_p-1:0];
  assign csa_opA_n = aggregation_outA;
  assign csa_opB_n = {aggregation_outB[csa_tree_width_lp-1:1], tail_cpa_opt[stride_p]};
  
  reg [width_p-1:0] result_low_r;
  wire [width_p-1:0] result_low_n;
  reg [width_p-1:0] result_high_r;
  wire [width_p:0] result_high_initial_n;
  wire [width_p:0] result_high_n;
  reg last_cpa_carry_r;

  if(stride_p != width_p)
    assign result_low_n = state_cnt_r == gather_level_lp ? 
                    {tail_cpa_opt[last_shift_count_lp-1:0], result_low_r[width_p-1:last_shift_count_lp]} :
                     {tail_cpa_opt[stride_p-1:0],result_low_r[width_p-1:stride_p]};
  else 
    assign result_low_n = tail_cpa_opt[stride_p-1:0];

  // A carry selected adder 
  wire [cpa_stride_p:0] cpa_res_0 = {1'b0, csa_opA_r[last_shift_count_lp+:cpa_stride_p]} + {1'b0, csa_opB_r[last_shift_count_lp+:cpa_stride_p]};
  wire [cpa_stride_p:0] cpa_res_1 = {1'b0, csa_opA_r[last_shift_count_lp+:cpa_stride_p]} + {1'b0, csa_opB_r[last_shift_count_lp+:cpa_stride_p]} + 1;

  if(cpa_stride_p == width_p)
    assign result_high_initial_n = tail_cpa_opt[last_shift_count_lp] ? cpa_res_1 : cpa_res_0;
  else 
    assign result_high_initial_n = tail_cpa_opt[last_shift_count_lp] ? {cpa_res_1[cpa_stride_p:0],result_high_r[width_p-1:cpa_stride_p]} : {cpa_res_0[cpa_stride_p:0],result_high_r[width_p-1:cpa_stride_p]};

  if(cpa_stride_p == width_p) 
    assign result_high_n = tail_cpa_opt[last_shift_count_lp] ? cpa_res_1 : cpa_res_0;
  else 
    assign result_high_n = last_cpa_carry_r ? {cpa_res_1[cpa_stride_p:0],result_high_r[width_p-1:cpa_stride_p]} : {cpa_res_0[cpa_stride_p:0],result_high_r[width_p-1:cpa_stride_p]};

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      csa_opA_r <= '0;
      csa_opB_r <= '0;
      result_low_r <= '0;
      last_cpa_carry_r <= '0;
      result_high_r <= '0;
    end
    else if(state_r == eIdle && v_i) begin
      csa_opA_r <= {csa_opA_init, stride_p'(0)};
      csa_opB_r <= '0;
      result_low_r <= '0;
      last_cpa_carry_r <= '0;
    end
    else if(state_r == eCal) begin
      csa_opA_r <= csa_opA_n;
      csa_opB_r <= csa_opB_n;
      result_low_r <= result_low_n;
      last_cpa_carry_r <= '0;
    end
    else if(state_r == eCPA) begin
      if(state_cnt_r == gather_level_lp) begin
        result_low_r <= result_low_n;
        result_high_r <= result_high_initial_n[width_p-1:0];
        last_cpa_carry_r <= result_high_initial_n[width_p];
      end
      else begin
        result_high_r <= result_high_n[width_p-1:0];
        last_cpa_carry_r <= result_high_n[width_p];
      end
      csa_opA_r <= csa_opA_r >> cpa_stride_p;
      csa_opB_r <= csa_opB_r >> cpa_stride_p;
    end
  end

  assign result_o = {result_high_r, result_low_r};
  assign v_o = state_r == eDone;
  assign ready_o = state_r == eIdle;

endmodule

module bsg_mul_iterative_booth_pipelined #(
  parameter integer width_p = "inv"
  ,parameter integer stride_p = "inv"
  ,parameter integer cpa_stride_p = width_p
  ,parameter bit debug_p = 0
)(
  input clk_i
  ,input reset_i

  ,input [width_p-1:0] opA_i
  ,input [width_p-1:0] opB_i
  ,input signed_i
  ,input v_i

  ,output v_o
  ,output [2*width_p-1:0] result_o 
);

localparam booth_level_lp = width_p % stride_p ? width_p / stride_p + 1 : width_p / stride_p;
localparam cpa_level_lp = width_p / cpa_stride_p;
localparam last_shift_count_lp = width_p % stride_p ? width_p % stride_p : stride_p;

reg [booth_level_lp + cpa_level_lp:0] v_r; // Valid signal

for(genvar i = 0; i <= booth_level_lp + cpa_level_lp; i++) begin: VALID_SFR
  if(i == 0) begin
    always_ff @(posedge clk_i) begin
      if(reset_i) v_r[i] <= '0;
      else v_r[i] <= v_i;
    end
  end
  else begin
    always_ff @(posedge clk_i) begin
      if(reset_i) v_r[i] <= '0;
      else v_r[i] <= v_r[i-1];
    end
  end
end

assign v_o = v_r[booth_level_lp + cpa_level_lp];

reg [booth_level_lp-1:0][width_p:0] opA_r;
// merging signed and unsigned condition for opA_i
wire opB_signed = signed_i & opB_i[width_p-1];
wire [width_p+2:0] extend_opB_i = {opB_signed, opB_signed, opB_i, 1'b0};
wire [width_p:0] extend_opA_i = {opA_i[width_p-1] & signed_i, opA_i};

for(genvar i = 0; i < booth_level_lp; i++) begin
  if(i == 0) begin
    always_ff @(posedge clk_i) begin
      if(reset_i | !v_i) opA_r[i] <= '0;
      else opA_r[i] <= extend_opA_i;
    end
  end
  else begin
    always_ff @(posedge clk_i) begin
      if(reset_i) opA_r[i] <= '0;
      else opA_r[i] <= opA_r[i-1];
    end
  end
end

reg [2:0][booth_level_lp-1:0][width_p/2-1:0] opB_r; 
wire [2:0][width_p/2:0] opB_n;

// Booth encoder
for(genvar i = 0; i <= width_p/2; ++i) begin: BOOTH_ENCODER
  bsg_booth_encoder encoder(
    .source_bits_i(extend_opB_i[2*i+:3])
    ,.code_o({opB_n[2][i], opB_n[1][i], opB_n[0][i]})
  );
end

localparam booth_step_lp = stride_p / 2;

for(genvar i = 0; i < booth_level_lp; ++i) begin: OPB_SFR
  if(i == 0) begin
    always_ff @(posedge clk_i) begin
      if(reset_i | !v_i) begin
        opB_r[0][i] <= '0;
        opB_r[1][i] <= '0;
        opB_r[2][i] <= '0;
      end
      else begin
        opB_r[0][i] <= opB_n[0][width_p/2:1];
        opB_r[1][i] <= opB_n[1][width_p/2:1];
        opB_r[2][i] <= opB_n[2][width_p/2:1];
      end
    end
  end
  else begin
    always_ff @(posedge clk_i) begin
      if(reset_i) begin
        opB_r[0][i] <= '0;
        opB_r[1][i] <= '0;
        opB_r[2][i] <= '0;
      end
      else begin
        opB_r[0][i] <= opB_r[0][i-1] >> booth_step_lp; 
        opB_r[1][i] <= opB_r[1][i-1] >> booth_step_lp;
        opB_r[2][i] <= opB_r[2][i-1] >> booth_step_lp;
      end
    end
  end
end

localparam csa_reg_width_lp = stride_p + width_p + 4;

reg [booth_level_lp:0][csa_reg_width_lp-1:0] csa_opA_r;
reg [booth_level_lp:0][csa_reg_width_lp-1:0] csa_opB_r;

wire [booth_level_lp:0][csa_reg_width_lp-1:0] csa_opA_n;
wire [booth_level_lp:0][csa_reg_width_lp-1:0] csa_opB_n;

wire [width_p+3:0] csa_opA_init;

bsg_booth_selector #(
  .width_p(width_p)
  ,.initial_p(1)
) first_selector (
  .pos_op_i(extend_opA_i)
  ,.code_i({opB_n[2][0], opB_n[1][0], opB_n[0][0]})
  ,.partial_product_o(csa_opA_init)
);

assign csa_opA_n[0] = {csa_opA_init, stride_p'(0)};
assign csa_opB_n[0] = '0;

for(genvar i = 0; i <= booth_level_lp; ++i) begin: CSA_SUM_SFR
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      csa_opA_r[i] <= '0;
      csa_opB_r[i] <= '0;
    end
    else begin
      if(i == 0 && !v_i) begin
        csa_opA_r[i] <= '0;
        csa_opB_r[i] <= '0;
      end
      else begin
        csa_opA_r[i] <= csa_opA_n[i];
        csa_opB_r[i] <= csa_opB_n[i];
      end
    end
  end
end

reg [booth_level_lp-1:0] sign_modification_r;

for(genvar i = 0; i < booth_level_lp; ++i) begin
  if(i == 0) begin
    always_ff @(posedge clk_i) begin
      if(reset_i | !v_i) begin
        sign_modification_r[i] <= '0;
      end
      else begin
        sign_modification_r[i] <= opB_n[2][0];
      end
    end
  end
  else begin
    always_ff @(posedge clk_i) begin
      if(reset_i) begin
        sign_modification_r[i] <= '0;
      end
      else begin
        sign_modification_r[i] <= opB_r[2][i-1][booth_step_lp-1];
      end
    end
  end
end

localparam csa_tree_width_lp = csa_reg_width_lp > 2*width_p ? 2*width_p : csa_reg_width_lp;

wire [booth_level_lp-1:0][csa_tree_width_lp-1:0] wallace_tree_outA;
wire [booth_level_lp-1:0][csa_tree_width_lp-1:0] wallace_tree_outB;



// Wallace Tree 
for(genvar i = 0; i < booth_level_lp; ++i) begin: WALLACE_TREE
  wire [2:0][width_p/2-1:0] opB_local;
  for(genvar j = 0; j < 3; ++j)
    assign opB_local[j] = opB_r[j][i];
  
  bsg_mul_booth_compressor #(
    .width_p(width_p)
    ,.stride_p(stride_p)
    ,.debug_p(debug_p)
  ) compressor (
    .opA_i(opA_r[i])
    ,.opB_i(opB_local)
    ,.csa_opA_i(csa_opA_r[i][csa_reg_width_lp-1:stride_p])
    ,.csa_opB_i(csa_opB_r[i][csa_reg_width_lp-1:stride_p])
    ,.last_sign_correction_i(sign_modification_r[i])

    ,.A_o(wallace_tree_outA[i])
    ,.B_o(wallace_tree_outB[i])

    ,.clk_i(clk_i)
  );
end
// Bind wallace_tree_outA/B with csa_opA/B_n
for(genvar i = 0; i < booth_level_lp; ++i) begin: CSA_RESULT_BINDER
  if(stride_p == width_p) begin
    assign csa_opA_n[i+1] = {4'b0, wallace_tree_outA[i]};
    assign csa_opB_n[i+1] = {4'b0, wallace_tree_outB[i]};
  end
  else begin
    assign csa_opA_n[i+1] = wallace_tree_outA[i];
    assign csa_opB_n[i+1] = wallace_tree_outB[i];
  end
end

reg [booth_level_lp + cpa_level_lp-2:0][width_p:0] result_low_r;
wire [booth_level_lp-1:0][stride_p:0] local_cpa_out;

for(genvar i = 0; i < booth_level_lp; ++i) begin: LOCAL_CPA
  if(i == 0)
    assign local_cpa_out[i] = {1'b0, csa_opA_r[i+1][stride_p-1:0]} + {1'b0, csa_opB_r[i+1][stride_p-1:0]};
  else if(i == booth_level_lp-1)
    assign local_cpa_out[i] = csa_opA_r[i+1][last_shift_count_lp-1:0] + csa_opB_r[i+1][last_shift_count_lp-1:0];
  else
    assign local_cpa_out[i] = {1'b0, csa_opA_r[i+1][stride_p-1:0]} + {1'b0, csa_opB_r[i+1][stride_p-1:0]} + result_low_r[i-1][width_p];
end

for(genvar i = 0; i < booth_level_lp + cpa_level_lp-1; ++i) begin: RESULT_LOW_STRING
  wire [width_p:0] result_low_n;

  if(stride_p == width_p)
    assign result_low_n = local_cpa_out[i];
  else if(i == 0)
    assign result_low_n = {local_cpa_out[i], (width_p-stride_p)'(0)};
  else if(i == booth_level_lp-1)
    assign result_low_n = {local_cpa_out[i][last_shift_count_lp:0], result_low_r[i-1][width_p-1:last_shift_count_lp]};
  else if(i < booth_level_lp)
    assign result_low_n = {local_cpa_out[i], result_low_r[i-1][width_p-1:stride_p]};
  else
    assign result_low_n = result_low_r[i-1];

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      result_low_r[i] <= '0;
    end
    else begin
      result_low_r[i] <= result_low_n;
    end
  end
end

// High 32bits

reg [cpa_level_lp-1:0][width_p:0] result_high_r;

// We use a carry-selected adder in the first stage of CPA because hope to avoid an extra stage waiting for the carry from local CPA. 

wire [cpa_stride_p:0] first_stage_cpa_zero = {1'b0,csa_opA_r[booth_level_lp][last_shift_count_lp+:cpa_stride_p]} + {1'b0, csa_opB_r[booth_level_lp][last_shift_count_lp+:cpa_stride_p]};
wire [cpa_stride_p:0] first_stage_cpa_one = {1'b0 , csa_opA_r[booth_level_lp][last_shift_count_lp+:cpa_stride_p]} + {1'b0, csa_opB_r[booth_level_lp][last_shift_count_lp+:cpa_stride_p]} + (cpa_stride_p+1)'(1);

wire [cpa_level_lp-1:0][width_p:0] result_high_n;
if(cpa_stride_p == width_p)
  assign result_high_n[0] = local_cpa_out[booth_level_lp-1][last_shift_count_lp] ? first_stage_cpa_one : first_stage_cpa_zero;
else
  assign result_high_n[0] = local_cpa_out[booth_level_lp-1][last_shift_count_lp] ? {first_stage_cpa_one, (width_p-cpa_stride_p)'(0)} : {first_stage_cpa_zero, (width_p-cpa_stride_p)'(0)};

if(cpa_stride_p != width_p) begin: CPA_PIPELINE
  reg [cpa_level_lp-2:0][width_p-cpa_stride_p-1:0] remnant_opA_r;
  reg [cpa_level_lp-2:0][width_p-cpa_stride_p-1:0] remnant_opB_r; 
  for(genvar i = 0; i < cpa_level_lp-1; ++i) begin
    if(i == 0) begin
      always_ff @(posedge clk_i) begin
        if(reset_i) begin
          remnant_opA_r[i] <= '0;
          remnant_opB_r[i] <= '0;
        end
        else begin
          remnant_opA_r[i] <= csa_opA_r[booth_level_lp][csa_tree_width_lp-5:stride_p+cpa_stride_p];
          remnant_opB_r[i] <= csa_opB_r[booth_level_lp][csa_tree_width_lp-5:stride_p+cpa_stride_p];
        end
      end
    end
    else begin
      always_ff @(posedge clk_i) begin
        if(reset_i) begin
          remnant_opA_r[i] <= '0;
          remnant_opB_r[i] <= '0;
        end
        else begin
          remnant_opA_r[i] <= remnant_opA_r[i-1] >> cpa_stride_p;
          remnant_opB_r[i] <= remnant_opB_r[i-1] >> cpa_stride_p;
        end
      end
    end
    wire [cpa_stride_p:0] cpa_output = {1'b0, remnant_opA_r[i][cpa_stride_p-1:0]} + {1'b0, remnant_opB_r[i][cpa_stride_p-1:0]} + result_high_r[i][width_p];
    assign result_high_n[i+1] = {cpa_output,result_high_r[i][width_p-1:cpa_stride_p]};
  end
end

for(genvar i = 0; i < cpa_level_lp; i++) begin: HIGH_RESULT
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      result_high_r[i] <= '0;
    end
    else begin
      result_high_r[i] <= result_high_n[i];
    end
  end
end

assign result_o = {result_high_r[cpa_level_lp-1][width_p-1:0],result_low_r[booth_level_lp + cpa_level_lp-2][width_p-1:0]};

endmodule


