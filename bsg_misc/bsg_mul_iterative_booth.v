/*
===============================
bsg_mul_booth_iter.v
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

wire e = code_i[2] ^ pos_op_i[width_p]; // E is used for sign correction.
if(!initial_p)
  assign partial_product_o = {1'b1, ~e, pd};
else
  assign partial_product_o = {~e, e, e, pd};
  
endmodule

module bsg_mul_iterative_booth #(
  parameter integer width_p = 32
  ,parameter integer stride_p = 16
  ,parameter integer cpa_stride_p = width_p / 2
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
      opB_r[0] <= {booth_step_lp'(0),opB_r[0][width_p/2-1:booth_step_lp]};
      opB_r[1] <= {booth_step_lp'(0),opB_r[1][width_p/2-1:booth_step_lp]};
      opB_r[2] <= {booth_step_lp'(0),opB_r[2][width_p/2-1:booth_step_lp]};
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
  if (booth_step_lp == 1) begin: NO_WALLACE_TREE
    wire [width_p+2:0] partial_product_lo;
    bsg_booth_selector #(
      .width_p(width_p)
      ,.initial_p(0)
    ) unique_selector (
      .pos_op_i(opA_r)
      ,.inv_op_i(~opA_r)
      ,.code_i({opB_r[2][0], opB_r[1][0], opB_r[0][0]})
      ,.partial_product_o(partial_product_lo[width_p+2:0])
    );
    wire [csa_tree_width_lp-1:0] csa_op = {1'b0, partial_product_lo, (stride_p-1)'(0), partial_sign_correction_r};
    wire [csa_tree_width_lp-1:0] csa_res_o;
    wire [csa_tree_width_lp-1:0] csa_car_o;
    bsg_adder_carry_save #(
      .width_p(csa_tree_width_lp)
    ) unique_csa (
      .opA_i(csa_opA_r[csa_tree_width_lp-1:stride_p])
      ,.opB_i(csa_opB_r[csa_tree_width_lp-1:stride_p])
      ,.opC_i(csa_op)
      ,.res_o(csa_res_o)
      ,.car_o(csa_car_o)
    );
    assign aggregation_outA = csa_res_o;
    assign aggregation_outB = {csa_car_o[csa_tree_width_lp-2:0], 1'b0};
  end
  else begin: WALLACE_TREE
    // Wallace Tree 
    wire [booth_step_lp-1:0][width_p+2:0] partial_product_lo;
    wire [booth_step_lp-1:0][csa_tree_width_lp-1:0] ops_i;
    for(genvar i = 0; i < booth_step_lp; ++i) begin
      bsg_booth_selector #(
        .width_p(width_p)
        ,.initial_p(0)
        ) booth_selector (
        .pos_op_i(opA_r)
        ,.inv_op_i(~opA_r)
        ,.code_i({opB_r[2][i], opB_r[1][i], opB_r[0][i]})
        ,.partial_product_o(partial_product_lo[i])
      );
      if (i == 0)
        assign ops_i[i] = {(stride_p-1)'(0), partial_product_lo[i], 1'b0, partial_sign_correction_r};
      else 
        assign ops_i[i] = {(stride_p-1-2*i)'(0), partial_product_lo[i], 1'b0, opB_r[2][i-1], (2*i)'(0)};
    end

    wire [csa_tree_width_lp-1:0] tree_outA;
    wire [csa_tree_width_lp-1:0] tree_outB;
    bsg_adder_wallace_tree #(
      .width_p(csa_tree_width_lp)
      ,.iter_step_p(booth_step_lp)
      ,.max_out_size_lp(csa_tree_width_lp)
    ) tree (
      .op_i(ops_i)
      ,.resA_o(tree_outA)
      ,.resB_o(tree_outB)
    );

    bsg_adder_carry_save_4_2 #(
      .width_p(csa_tree_width_lp)
    ) acc (
      .opA_i(csa_opA_r[csa_tree_width_lp-1:stride_p])
      ,.opB_i(csa_opB_r[csa_tree_width_lp-1:stride_p])
      ,.opC_i(tree_outA)
      ,.opD_i(tree_outB)

      ,.A_o(aggregation_outA)
      ,.B_o(aggregation_outB)
    );

    if(debug_p) begin
      always_ff @(posedge clk_i) begin
        $display("===================================");
        $display("state_r:%s", state_r.name());
        $display("csa_opA_r:%b", csa_opA_r);
        $display("csa_opB_r:%b", csa_opB_r);
        $display("opA_r:%b", opA_r);
        for(int i = 0; i < 3; ++i)
          $display("opB_n[%d]:%b",i, opB_n[i]);
        for(int i = 0; i < 3; ++i)
          $display("opB_r[%d]:%b",i, opB_r[i]);
        for(logic [31:0] i = 0; i < booth_step_lp; ++i) begin
          $display("ops_i[%d]:%b",i,ops_i[i]);
        end
      end
    end
  end

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

  if(debug_p) begin
    always_ff @(posedge clk_i) begin
      /*
      $display("================================");
      $display("state_r:%s", state_r.name());
      $display("extend_opB_i:%b", extend_opB_i);
      //for(int i = 0; i < 3; ++i)
      //  $display("opB_n[%d]:%b",i, opB_n[i]);
      //for(int i = 0; i < 3; ++i)
      //  $display("opB_r[%d]:%b",i, opB_r[i]);
      $display("csa_opA_r:%b", csa_opA_r);
      $display("csa_opB_r:%b", csa_opB_r);
      $display("last_cpa_carry_r:%b", last_cpa_carry_r);
      $display("cpa_res_0:%b", cpa_res_0);
      $display("cpa_res_1:%b", cpa_res_1);
      $display("result_high_initial_n:%b", result_high_initial_n);
      $display("result_high_n:        %b", result_high_n);
      */
    end

  end


endmodule

