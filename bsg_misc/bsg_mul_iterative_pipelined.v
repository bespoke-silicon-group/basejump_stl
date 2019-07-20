// -------------------------------------------------------
// bsg_mul_iterative_pipelined.v
// sqlin16@fudan.edu.cn 07/06/2019
// -------------------------------------------------------
// This is a pipelined multiplier with configurable stride for each level, which in essential is a unrolling of bsg_mul_iterative.
// -------------------------------------------------------

module bsg_mul_iterative_pipelined #(
  parameter integer width_p = "inv"
  ,parameter integer iter_step_p = "inv"
  ,parameter bit debug_p = 0
)(
  input clk_i
  ,input reset_i

  ,input [width_p-1:0] opA_i
  ,input [width_p-1:0] opB_i
  ,input signed_i
  ,input v_i

  ,output [2*width_p-1:0] res_o
  ,output v_o
);

localparam integer level_lp = width_p / iter_step_p;

reg [level_lp-1:0][width_p-1:0] opA_r;
reg [level_lp-1:0][width_p-1:0] opB_r;

reg [level_lp:0] opA_sign_r;
reg [level_lp:0] opB_sign_r;

reg [2*level_lp:0] v_i_r;


// Update entrance operands register
always_ff @(posedge clk_i) begin
  if(reset_i) begin
    opA_r[0] <= '0;
    opB_r[0] <= '0;
    opA_sign_r[0] <= '0;
    opB_sign_r[0] <= '0;
    v_i_r[0] <= v_i;
  end
  else begin
    if(v_i) begin
      opA_r[0] <= opA_i;
      opB_r[0] <= opB_i;
      opA_sign_r[0] <= signed_i & opA_i[width_p-1];
      opB_sign_r[0] <= signed_i & opB_i[width_p-1];
      v_i_r[0] <= v_i;
    end
    else begin
      opA_r[0] <= '0;
      opB_r[0] <= '0;
      opA_sign_r[0] <= '0;
      opB_sign_r[0] <= '0;
      v_i_r[0] <= '0;
    end
  end
end

// Update other level operands register
for(genvar i = 1; i < level_lp; ++i) begin: OPERANDS_REGISTER
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      opA_r[i] <= '0;
      opB_r[i] <= '0;
      opA_sign_r[i] <= '0;
      opB_sign_r[i] <= '0;
    end
    else begin
      opA_r[i] <= opA_r[i-1];
      opB_r[i] <= opB_r[i-1] >> iter_step_p;
      opA_sign_r[i] <= opA_sign_r[i-1];
      opB_sign_r[i] <= opB_sign_r[i-1];
    end
  end
end

always_ff @(posedge clk_i) begin
  if(reset_i) begin
    opA_sign_r[level_lp] <= '0;
    opB_sign_r[level_lp] <= '0;
  end
  else begin
    opA_sign_r[level_lp] <= opA_sign_r[level_lp-1];
    opB_sign_r[level_lp] <= opB_sign_r[level_lp-1];
  end
end

for(genvar i = 1; i <= 2*level_lp; ++i) begin: V_I_R
  always_ff @(posedge clk_i) begin
    if(reset_i) v_i_r[i] <= '0;
    else v_i_r[i] <= v_i_r[i-1];
  end
end

reg [level_lp-1:0][width_p:0] csa_res_r;
reg [level_lp-1:0][width_p-1:0] csa_car_r;
reg [level_lp-1:0][width_p-1:0] lower_bits_r;

for(genvar i = 0; i < level_lp; ++i) begin: CSA
  wire [iter_step_p:0][width_p:0] cascade_csa_res;
  wire [iter_step_p:0][width_p-1:0] cascade_csa_car;

  if(i == 0) begin
    assign cascade_csa_res[0] = '0;
    assign cascade_csa_car[0] = {opB_sign_r[0], (width_p-1)'(0)};
  end
  else begin
    assign cascade_csa_res[0] = csa_res_r[i-1];
    assign cascade_csa_car[0] = csa_car_r[i-1];
  end

  wire [iter_step_p-1:0] lower_bits_resolved;
  wire [width_p-1:0] lower_bits_n;

  for(genvar j = 0; j < iter_step_p; ++j) begin: CSA_FLEX
    if(j == (iter_step_p - 1) && i == (level_lp - 1)) begin:CSA_FLEX_LAST
      bsg_adder_carry_save #(
        .width_p(width_p)
      ) csa_adder (
        .opA_i(cascade_csa_res[j][width_p:1])
        ,.opB_i(cascade_csa_car[j])
        ,.opC_i((opA_r[i] ^ {width_p{opB_sign_r[i]}}) & {width_p{opB_r[i][j]}})
        ,.res_o(cascade_csa_res[j+1][width_p-1:0])
        ,.car_o(cascade_csa_car[j+1])
      );
      assign cascade_csa_res[j+1][width_p] = ((~opB_r[i][j]) & opA_sign_r[i]) ^ opB_sign_r[i]; // Sign extended of -opA
    end
    else begin:CSA_FLEX_GENERAL
      bsg_adder_carry_save #(
        .width_p(width_p)
      ) csa_adder (
        .opA_i(cascade_csa_res[j][width_p:1])
        ,.opB_i(cascade_csa_car[j])
        ,.opC_i(opA_r[i] & {width_p{opB_r[i][j]}})
        ,.res_o(cascade_csa_res[j+1][width_p-1:0])
        ,.car_o(cascade_csa_car[j+1])
      );
      assign cascade_csa_res[j+1][width_p] = (~opB_r[i][j]) & opA_sign_r[i];
    end
    assign lower_bits_resolved[j] = cascade_csa_res[j+1][0];
  end

  if(iter_step_p == width_p) 
    assign lower_bits_n = lower_bits_resolved;
  else if(i == 0)
    assign lower_bits_n = {lower_bits_resolved, (width_p-iter_step_p)'(0)};
  else 
    assign lower_bits_n = {lower_bits_resolved, lower_bits_r[i-1][width_p-1:iter_step_p]};

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      csa_res_r[i] <= '0;
      csa_car_r[i] <= '0;
      lower_bits_r[i] <= '0;
    end
    else begin
      csa_res_r[i] <= cascade_csa_res[iter_step_p];
      csa_car_r[i] <= cascade_csa_car[iter_step_p];
      lower_bits_r[i] <= lower_bits_n;
    end
  end
end

wire [level_lp-1:0][width_p-1:0] high_csa_car;
assign high_csa_car[0] = (width_p)'(csa_car_r[level_lp-1][width_p-1:0]);
wire [level_lp-1:0][width_p-1:0] high_csa_res;
assign high_csa_res[0] = (width_p)'(csa_res_r[level_lp-1][width_p:1]);

for(genvar i = 0; i < level_lp-1; ++i) begin: CSA_OUTPUT_SFR

  localparam register_size_lp = width_p-(i+1)*iter_step_p;

  reg [register_size_lp-1:0] high_csa_car_r;
  assign high_csa_car[i+1] = (width_p)'(high_csa_car_r);
  reg [register_size_lp-1:0] high_csa_res_r;
  assign high_csa_res[i+1] = (width_p)'(high_csa_res_r);

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      high_csa_car_r <= '0;
      high_csa_res_r <= '0;
    end
    else begin
      high_csa_car_r <= high_csa_car[i][iter_step_p+:register_size_lp];
      high_csa_res_r <= high_csa_res[i][iter_step_p+:register_size_lp];
    end
  end
end

reg [level_lp-1:0][width_p:0] high_result_r;
reg [level_lp-1:0][width_p-1:0] lower_bits_sfr_r;

for(genvar i = 0; i < level_lp; ++i) begin: LOWER_BITS_SFR
  always_ff @(posedge clk_i) begin
    if(reset_i) lower_bits_sfr_r[i] <= '0;
    else if(i == 0) lower_bits_sfr_r[i] <= lower_bits_r[level_lp-1];
    else lower_bits_sfr_r[i] <= lower_bits_sfr_r[i-1];
  end
end

for(genvar i = 0; i < level_lp; ++i) begin: RESULT_HIGH_PART
  wire [iter_step_p:0] high_result_partial;
  if(i == 0)
    assign high_result_partial =  high_csa_car[0][iter_step_p-1:0] + high_csa_res[0][iter_step_p-1:0] + opA_sign_r[level_lp];
  else 
    assign high_result_partial = {1'b0, high_csa_car[i][iter_step_p-1:0]} +  {1'b0, high_csa_res[i][iter_step_p-1:0]} + high_result_r[i-1][width_p];

  wire [width_p:0] high_result_n;
  if(iter_step_p == width_p)
    assign high_result_n = high_result_partial;
  else if(i == 0)
    assign high_result_n = {high_result_partial, (width_p-iter_step_p)'(0)};
  else
    assign high_result_n = {high_result_partial, high_result_r[i-1][width_p-1:iter_step_p]};

  always_ff @(posedge clk_i) begin
    if(reset_i) high_result_r[i] <= '0;
    else high_result_r[i] <= high_result_n;
  end
end

assign res_o = {high_result_r[level_lp-1][width_p-1:0], lower_bits_sfr_r[level_lp-1]};
assign v_o = v_i_r[2*level_lp];

if(debug_p) begin
  always_ff @(posedge clk_i) begin
    $display("==========================================================");
    $display("============ First Level ============");
    $display("opA_sign_r:%b", opA_sign_r[0]);
    $display("opB_sign_r:%b", opB_sign_r[0]);
    $display("v_i_r:%b", v_i_r[0]);
    $display("opA_r:%b", opA_r[0]);
    $display("opB_r:%b", opB_r[0]);
    for(logic [31:0] i = 0; i < level_lp; ++i) begin
      $display("============ Level %d ============", i);
      $display("csa_res_r:%b", csa_res_r[i]);
      $display("csa_car_r:%b", csa_car_r[i]);
      $display("lower_bits_r:%b", lower_bits_r[i]);
      $display("v_i_r:%b", v_i_r[i+1]);
      if(i > 0) begin
        $display("opA_r:%b", opA_r[i-1]);
        $display("opB_r:%b", opB_r[i-1]);
      end
    end
    for(logic [31:0] i = 0; i < level_lp; ++i) begin
      $display("=============Accumulator Level %d =============", i);
      $display("high_result_r:%b",high_result_r[i]);
      $display("lower_bits_sfr_r:%b",lower_bits_sfr_r[i]);
      $display("v_i_r:%b", v_i_r[i+1+level_lp]);
      $display("high_csa_car:%b",high_csa_car[i]);
      $display("high_csa_res:%b",high_csa_res[i]);

    end
    $display("\n\n\n\n");
  end
end

endmodule

