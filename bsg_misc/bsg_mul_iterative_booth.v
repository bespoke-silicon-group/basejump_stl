/*
===============================
bsg_mul_booth_iterative_booth.v
4/5/2019 sqlin16@fudan.edu.cn
===============================

This is an iterative booth encoded (radix-4) multiplier with configurable iteration stride.

Latency = 4 + (width_p / iter_step_p) cycles.
Throughput = 1/(5 + (width_p / iter_step_p)) (cycle^-1)


*/
// define the booth encoder
// sel[0]: whether the bits is not zero
// sel[1]: how many left shifts are need to do
// sel[2]: sign
module bsg_booth_encoder (
  input [2:0] source_bits_i
  ,output logic [2:0] code_o
);
always_comb begin
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
endmodule

module bsg_booth_selector #(
  parameter integer width_p = "inv"
  ,parameter bit initial_p = 0
)(
  input [width_p:0] pos_op_i // original operand.
  ,input [width_p:0] inv_op_i // inverted operand.
  ,input [2:0] code_i

  ,output [width_p+2+initial_p:0] partial_product_o
);

wire [width_p:0] pos_neg = code_i[2] ? inv_op_i : pos_op_i;
wire [width_p:0] zero_or_not = code_i[0] ? pos_neg : '0;
wire [width_p:0] pd = code_i[1] ? {zero_or_not[width_p-1:0], code_i[2]} : zero_or_not;

wire e = pd[width_p]; // E is used for sign extension.
if(!initial_p)
  assign partial_product_o = {1'b1, ~e, pd};
else
  assign partial_product_o = {~e, e, e, pd};
  
endmodule

// This module merges 3:2 compressor and 4:2 compressor. Using which wallace tree is determined by a simple parameter.
module bsg_wallace_tree_configuration #(
  parameter integer width_p = "inv"
  ,parameter integer capacity_p = "inv"
  ,parameter integer out_width_p = width_p
  ,parameter bit csa_3_2_p = 1 // if this parameter is set to 1, 3:2 compressor is enabled.
)(
  input [capacity_p+1:0][width_p-1:0] ops_i
  ,output [out_width_p-1:0] resA_o
  ,output [out_width_p-1:0] resB_o
);
  if(csa_3_2_p == 1) begin: WALLACE_TREE_3_2
    bsg_adder_wallace_tree_3_2 #(
      .width_p(width_p)
      ,.capacity_p(capacity_p+2)
      ,.out_width_p(out_width_p)
    ) tree (
      .ops_i(ops_i)
      ,.resA_o(resA_o)
      ,.resB_o(resB_o)
    );
  end
  else begin
    wire [out_width_p-1:0] tree_outA;
    wire [out_width_p-1:0] tree_outB;
    bsg_adder_wallace_tree #(
      .width_p(width_p)
      ,.iter_step_p(capacity_p)
      ,.max_out_size_lp(out_width_p)
    ) tree (
      .op_i(ops_i[capacity_p-1:0])
      ,.resA_o(tree_outA)
      ,.resB_o(tree_outB)
    );
    bsg_adder_carry_save_4_2 #(
      .width_p(out_width_p)
    ) acc (
      .opA_i(ops_i[capacity_p])
      ,.opB_i(ops_i[capacity_p+1])
      ,.opC_i(tree_outA)
      ,.opD_i(tree_outB)

      ,.A_o(resA_o)
      ,.B_o(resB_o)
    );
  end

endmodule


// this module generates the partial product, and at the same time compress the partial product with wallace tree.
module bsg_mul_booth_compressor #(
  parameter integer width_p = "inv"
  ,parameter integer stride_p = "inv"
  ,parameter bit csa_3_2_p = 0
  ,localparam integer csa_tree_width_lp = stride_p + 2 + width_p + 1 + 1
  ,parameter bit debug_p = 0
)(
  input [width_p:0] opA_i
  ,input [2:0][width_p/2-1:0] opB_i
  ,input [csa_tree_width_lp-1:0] csa_opA_i
  ,input [csa_tree_width_lp-1:0] csa_opB_i
  ,input last_sign_correction_i

  ,output [csa_tree_width_lp-1:0] A_o
  ,output [csa_tree_width_lp-1:0] B_o

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
    ,.inv_op_i(~opA_i)
    ,.code_i({opB_i[2][0], opB_i[1][0], opB_i[0][0]})
    ,.partial_product_o(partial_product_lo[width_p+2:0])
  );
  wire [csa_tree_width_lp-1:0] csa_op = {1'b0, partial_product_lo, (stride_p-1)'(0), last_sign_correction_i};
  wire [csa_tree_width_lp-1:0] csa_res_o;
  wire [csa_tree_width_lp-1:0] csa_car_o;
  bsg_adder_carry_save #(
    .width_p(csa_tree_width_lp)
  ) unique_csa (
    .opA_i(csa_opA_i[csa_tree_width_lp-1:stride_p])
    ,.opB_i(csa_opB_i[csa_tree_width_lp-1:stride_p])
    ,.opC_i(csa_op)
    ,.res_o(csa_res_o)
    ,.car_o(csa_car_o)
  );
  assign A_o = csa_res_o;
  assign B_o = {csa_car_o[csa_tree_width_lp-2:0], 1'b0};

  always_ff @(posedge clk_i) begin
    $display("Partial Sum:%b",partial_product_lo);
  end
end
else begin: WALLACE_TREE
  // Wallace Tree 
  wire [booth_step_lp-1:0][width_p+2:0] partial_product_lo;
  wire [booth_step_lp+1:0][csa_tree_width_lp-1:0] ops_i;
  for(genvar i = 0; i < booth_step_lp; ++i) begin
    bsg_booth_selector #(
      .width_p(width_p)
      ,.initial_p(0)
      ) booth_selector (
      .pos_op_i(opA_i)
      ,.inv_op_i(~opA_i)
      ,.code_i({opB_i[2][i], opB_i[1][i], opB_i[0][i]})
      ,.partial_product_o(partial_product_lo[i])
    );
    if (i == 0)
      assign ops_i[i] = {(stride_p-1)'(0), partial_product_lo[i], 1'b0, (last_sign_correction_i)};
    else 
      assign ops_i[i] = {(stride_p-1-2*i)'(0), partial_product_lo[i], 1'b0, (opB_i[2][i-1]), (2*i)'(0)};
  end

  assign ops_i[booth_step_lp] = {stride_p'(0) ,csa_opA_i[csa_tree_width_lp-1:stride_p]};
  assign ops_i[booth_step_lp+1] = {stride_p'(0) ,csa_opB_i[csa_tree_width_lp-1:stride_p]};

  wire [csa_tree_width_lp-1:0] tree_outA;
  wire [csa_tree_width_lp-1:0] tree_outB;

  bsg_wallace_tree_configuration #(
    .width_p(csa_tree_width_lp)
    ,.capacity_p(booth_step_lp)
    ,.out_width_p(csa_tree_width_lp)
    ,.csa_3_2_p(csa_3_2_p)
  ) tree (
    .ops_i(ops_i)
    ,.resA_o(tree_outA)
    ,.resB_o(tree_outB)
  );

  assign A_o = tree_outA[csa_tree_width_lp-1:0];
  assign B_o = tree_outB[csa_tree_width_lp-1:0];
end

endmodule

module bsg_mul_iterative_booth_unpipelined #(
  parameter integer width_p = 32
  ,parameter integer stride_p = 32
  ,parameter integer cpa_stride_p = 32
  ,parameter bit csa_3_2_p = 1
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
  localparam gather_level_lp = width_p / stride_p;

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
  reg [`BSG_SAFE_CLOG2(gather_level_lp)-1:0] cal_cnt_r;
  reg [`BSG_SAFE_CLOG2(cpa_level_lp)-1:0] cpa_cnt_r;

  assign calc_is_done = cal_cnt_r == (gather_level_lp-1);
  assign cpa_is_done = cpa_cnt_r == (cpa_level_lp-1);
  // Counter update
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      cal_cnt_r <= '0;
      cpa_cnt_r <= '0;
    end
    else if(state_r == eIdle && v_i) begin
      cal_cnt_r <= '0;
      cpa_cnt_r <= '0;
    end
    else if(state_r == eCal) begin
      cal_cnt_r <= cal_cnt_r + 1;
    end
    else if(state_r == eCPA) begin
      cpa_cnt_r <= cpa_cnt_r + 1;
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
  localparam csa_tree_width_lp = stride_p + 2 + width_p + 1 + 1;

  reg [csa_tree_width_lp-1:0] csa_opA_r;
  reg [csa_tree_width_lp-1:0] csa_opB_r;

  wire [csa_tree_width_lp-1:0] csa_opA_n;
  wire [csa_tree_width_lp-1:0] csa_opB_n;

  wire [width_p+3:0] csa_opA_init;

  bsg_booth_selector #(
    .width_p(width_p)
    ,.initial_p(1)
  ) first_selector (
    .pos_op_i(extend_opA_i)
    ,.inv_op_i(~extend_opA_i)
    ,.code_i({opB_n[2][0], opB_n[1][0], opB_n[0][0]})
    ,.partial_product_o(csa_opA_init)
  );

  wire [csa_tree_width_lp-1:0] aggregation_outA;
  wire [csa_tree_width_lp-1:0] aggregation_outB;
  // Setup aggregation units

  bsg_mul_booth_compressor #(
    .width_p(width_p)
    ,.stride_p(stride_p)
    ,.debug_p(debug_p)
    ,.csa_3_2_p(csa_3_2_p)
  ) compressor (
    .opA_i(opA_r)
    ,.opB_i(opB_r)
    ,.csa_opA_i(csa_opA_r)
    ,.csa_opB_i(csa_opB_r)
    ,.last_sign_correction_i(partial_sign_correction_r)

    ,.A_o(aggregation_outA)
    ,.B_o(aggregation_outB)
    ,.clk_i(clk_i)
  );

  // Partial Adder for tail 
  wire [stride_p:0] tail_cpa_opt = csa_opA_r[stride_p-1:0] + csa_opB_r[stride_p-1:0];
  assign csa_opA_n = aggregation_outA;
  assign csa_opB_n = {aggregation_outB[csa_tree_width_lp-1:1], tail_cpa_opt[stride_p]};
  
  reg [width_p-1:0] result_low_r;
  wire [width_p-1:0] result_low_n;
  reg [width_p-1:0] result_high_r;
  wire [width_p:0] result_high_initial_n;
  wire [width_p:0] result_high_n;
  reg last_cpa_carry_r;

  if(stride_p != width_p)
    assign result_low_n = {tail_cpa_opt[stride_p-1:0],result_low_r[width_p-1:stride_p]};
  else 
    assign result_low_n = tail_cpa_opt[stride_p-1:0];

  // A carry selected adder 
  wire [cpa_stride_p:0] cpa_res_0 = {1'b0, csa_opA_r[stride_p+:cpa_stride_p]} + {1'b0, csa_opB_r[stride_p+:cpa_stride_p]};
  wire [cpa_stride_p:0] cpa_res_1 = {1'b0, csa_opA_r[stride_p+:cpa_stride_p]} + {1'b0, csa_opB_r[stride_p+:cpa_stride_p]} + 1;

  if(cpa_stride_p == width_p)
    assign result_high_initial_n = tail_cpa_opt[stride_p] ? cpa_res_1 : cpa_res_0;
  else 
    assign result_high_initial_n = tail_cpa_opt[stride_p] ? {cpa_res_1[cpa_stride_p:0],result_high_r[width_p-1:cpa_stride_p]} : {cpa_res_0[cpa_stride_p:0],result_high_r[width_p-1:cpa_stride_p]};

  if(cpa_stride_p == width_p) 
    assign result_high_n = tail_cpa_opt[stride_p] ? cpa_res_1 : cpa_res_0;
  else 
    assign result_high_n = last_cpa_carry_r ? {cpa_res_1[cpa_stride_p:0],result_high_r[width_p-1:cpa_stride_p]} : {cpa_res_0[cpa_stride_p:0],result_high_r[width_p-1:cpa_stride_p]};

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      csa_opA_r <= '0;
      csa_opB_r <= '0;
      result_low_r <= '0;
      last_cpa_carry_r <= '0;
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
      if(cpa_cnt_r == '0) begin
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
  ,parameter bit csa_3_2_p = 1
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

localparam booth_level_lp = width_p / stride_p;
localparam cpa_level_lp = width_p / cpa_stride_p;

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

// Partial Sum 
// stride_p: for partial products which is most shifted. 
// width_p + 1 + 2: the size of partial product.
// 1: carry 
localparam csa_tree_width_lp = stride_p + 2 + width_p + 1 + 1;

reg [booth_level_lp:0][csa_tree_width_lp-1:0] csa_opA_r;
reg [booth_level_lp:0][csa_tree_width_lp-1:0] csa_opB_r;

wire [booth_level_lp:0][csa_tree_width_lp-1:0] csa_opA_n;
wire [booth_level_lp:0][csa_tree_width_lp-1:0] csa_opB_n;

wire [width_p+3:0] csa_opA_init;

bsg_booth_selector #(
  .width_p(width_p)
  ,.initial_p(1)
) first_selector (
  .pos_op_i(extend_opA_i)
  ,.inv_op_i(~extend_opA_i)
  ,.code_i({opB_n[2][0], opB_n[1][0], opB_n[0][0]})
  ,.partial_product_o(csa_opA_init)
);

assign csa_opA_n[0] = {csa_opA_init,stride_p'(0)};
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
    ,.csa_3_2_p(csa_3_2_p)
  ) compressor (
    .opA_i(opA_r[i])
    ,.opB_i(opB_local)
    ,.csa_opA_i(csa_opA_r[i])
    ,.csa_opB_i(csa_opB_r[i])
    ,.last_sign_correction_i(sign_modification_r[i])

    ,.A_o(wallace_tree_outA[i])
    ,.B_o(wallace_tree_outB[i])

    ,.clk_i(clk_i)
  );
end
// Bind wallace_tree_outA/B with csa_opA/B_n
for(genvar i = 0; i < booth_level_lp; ++i) begin: CSA_RESULT_BINDER
  assign csa_opA_n[i+1] = wallace_tree_outA[i];
  assign csa_opB_n[i+1] = wallace_tree_outB[i];
end

reg [booth_level_lp + cpa_level_lp-2:0][width_p:0] result_low_r;
wire [booth_level_lp-1:0][stride_p:0] local_cpa_out;

for(genvar i = 0; i < booth_level_lp; ++i) begin: LOCAL_CPA
  if(i == 0)
    assign local_cpa_out[i] = {1'b0, csa_opA_r[i+1][stride_p-1:0]} + {1'b0, csa_opB_r[i+1][stride_p-1:0]};
  else
    assign local_cpa_out[i] = {1'b0, csa_opA_r[i+1][stride_p-1:0]} + {1'b0, csa_opB_r[i+1][stride_p-1:0]} + result_low_r[i-1][width_p];
end

for(genvar i = 0; i < booth_level_lp + cpa_level_lp-1; ++i) begin: RESULT_LOW_STRING
  wire [width_p:0] result_low_n;

  if(stride_p == width_p)
    assign result_low_n = local_cpa_out[i];
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

wire [cpa_stride_p:0] first_stage_cpa_zero = {1'b0,csa_opA_r[booth_level_lp][stride_p+:cpa_stride_p]} + {1'b0, csa_opB_r[booth_level_lp][stride_p+:cpa_stride_p]};
wire [cpa_stride_p:0] first_stage_cpa_one = csa_opA_r[booth_level_lp][stride_p+:cpa_stride_p] + csa_opB_r[booth_level_lp][stride_p+:cpa_stride_p] + (cpa_stride_p+1)'(1);

wire [cpa_level_lp-1:0][width_p:0] result_high_n;
assign result_high_n[0] = local_cpa_out[booth_level_lp-1][stride_p] ? first_stage_cpa_one : first_stage_cpa_zero;

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
          remnant_opA_r[i] <= remnant_opA_r >> cpa_stride_p;
          remnant_opB_r[i] <= remnant_opA_r >> cpa_stride_p;
        end
      end
    end
    wire [cpa_stride_p:0] cpa_output = remnant_opA_r[cpa_stride_p-1:0] + remnant_opB_r[cpa_stride_p-1:0] + result_high_r[i][width_p];
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

if(debug_p) begin
  always_ff @(posedge clk_i) begin
    $display("============================");
    for(logic [10:0] i = 0; i < booth_level_lp; ++i) begin
      $display("opA_r[%b]:%b", i, opA_r[i]);
      $display("opB_r[0][%b]:%b", i, opB_r[0][i]);
      $display("opB_r[1][%b]:%b", i, opB_r[1][i]);
      $display("opB_r[2][%b]:%b", i, opB_r[2][i]);
    end
    for(logic [10:0] i = 0; i <= booth_level_lp; ++i) begin
      $display("csa_opA_r[%b]:%b", i, csa_opA_r[i]);
      $display("csa_opB_r[%b]:%b", i, csa_opB_r[i]);
      $display("result_low_r[%b]:%b", i, result_low_r[i]);
    end
    $display("v_r:%b", v_r);
    $display("v_r[booth_level_lp + cpa_level_lp]:%b", v_r[booth_level_lp +cpa_level_lp]);
    $display("first_stage_cpa_zero:%b", first_stage_cpa_zero);
    $display("first_stage_cpa_one:%b", first_stage_cpa_one);
    $display("local_cpa_out[booth_level_lp-1]:%b", local_cpa_out[booth_level_lp-1]);
  end
end

endmodule

// Top wrapper
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
  ) mul_pipelined (.*);
end


endmodule

