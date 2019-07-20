/*************************************************************
==================================================
bsg_mul_iterative.v
3/14/2019, sqlin16@fudan.edu.cn
===================================================

An 32 bits integer iterative multiplier, capable of signed & unsigned division,
with configurable stride for each iteration.

Latency = 4 + (width_p / iter_step_p) cycles.
Throughput = 1/(5 + (width_p / iter_step_p)) (cycle^-1)

Typical configuration is width_p = 32, iter_step_p = 8/16.

States:

eIDLE:          Ready for input. 
eCAL:           Add the partial products using CSA. CPA is also used to calculate the lower bits of the result.
eCPA:           Recover the result by CPA.
eDONE:          Output the result

Parameters:

width_p:        Length of operands
iter_step_p:    Stride of each iteration of adding.(How many partial products are added in one iteration)
full_sized_p:  Type of results. A 64bit result will be generated with full_sized_p = 1.
output_size_lp: Length of the results, which is defined as width_p*(full_sized_p+1) by default.

TODO:
  1. Removing unnecessary state eADJ from the half version of multiplier.
  2. Using booth record to eliminate prefix 1 from sign extension

************************************************************/
module bsg_mul_iterative #(
  parameter integer width_p = "inv"
  ,parameter integer iter_step_p = "inv"
  ,parameter integer full_sized_p = 1
  ,localparam integer output_size_lp = full_sized_p ? 2 * width_p : width_p
  ,parameter bit debug_p = 0
)
(
  input clk_i
  ,input reset_i
  // handshake signal
  ,input v_i
  ,output ready_o
  // operands
  ,input [width_p-1:0] opA_i
  ,input opA_is_signed_i
  ,input [width_p-1:0] opB_i
  ,input opB_is_signed_i
  // result
  ,output [output_size_lp-1:0] result_o 
  ,output v_o
  ,input yumi_i
  
);

  localparam integer iter_count_lp = width_p / iter_step_p; // calculate how many iterations should be done.
  localparam cal_state_length_lp = `BSG_SAFE_CLOG2(iter_count_lp);  // calculate the length of counter used for eCAL state.

  initial assert(width_p == width_p) else $error("Alignment of stride is required for configurable iteration multiplier!");
  initial assert(width_p == 8 || width_p == 16 || width_p == 32) else $warning("Warning, condition with width_p = %d is untested!", width_p);

  typedef enum logic [2:0] {eIDLE, eCAL, eCPA, eDONE} state_e; // FSM states.
  state_e state_r, state_n; // current state and next state.
  // used for reset registers. combining the reset_i and yumi_i
  // counter used for jumping out of eCAL
  logic [cal_state_length_lp-1:0] cal_state_counter_r;
  // counter update
  always_ff @(posedge clk_i) begin
    if(reset_i) cal_state_counter_r <= '0;
    else if(state_r == eIDLE) cal_state_counter_r <= '0;
    else if(state_r == eCAL || state_r == eCPA) 
      cal_state_counter_r <= (cal_state_counter_r != '1) ? cal_state_counter_r + 1 : '0;
  end
  
  // FSM. And the full output version and half output version contain different states.
  always_comb begin
    unique case(state_r)
      eIDLE : begin
        if(v_i) 
            state_n = eCAL; 
        else 
          state_n = eIDLE;
      end
      eCAL : begin
        state_n = cal_state_counter_r == '1 ? eCPA : eCAL;
      end
      eCPA : begin
        state_n = cal_state_counter_r == '1 ? eDONE : eCPA;
      end
      eDONE: if(yumi_i) state_n = eIDLE; else state_n = eDONE;
      default : state_n = eIDLE;
    endcase
  end

  assign ready_o = state_r == eIDLE;
  // update current state
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      state_r <= eIDLE;
    end
    else begin
      state_r <= state_n;
    end
  end
  // registers to store operands
  logic [width_p - 1:0] opA_r; 
  logic [width_p - 1:0] opB_r;
  logic opA_neg_r; // used to record that opA is negative.
  logic opB_neg_r; // same with statement above

  wire opA_signed_n = opA_i[width_p-1] & opA_is_signed_i;
  wire opB_signed_n = opB_i[width_p-1] & opB_is_signed_i;

  // update input registers (opA, opB, opA_neg, opB_neg)
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      opA_r <= '0;
      opB_r <= '0;
      opA_neg_r <= 1'b0;
      opB_neg_r <= 1'b0;
    end
    else begin
      unique case(state_r)  // latch up!
        eIDLE: begin
          if(v_i) begin
            opA_r <= opA_i;
            opB_r <= opB_i;
            opA_neg_r <= opA_signed_n;
            opB_neg_r <= opB_signed_n;
          end
        end
        eCAL : begin
          opB_r <= (opB_r >> iter_step_p);
        end
        default : begin
        end
      endcase
    end
  end
  // Setup carry propagate operation.
  logic [iter_step_p-1:0] cpa_opA; // operand A of CPA
  logic [iter_step_p-1:0] cpa_opB; // operand B of CPA
  logic cpa_carry; // carry for CPA
  wire  [iter_step_p:0] cpa_opt = {1'b0, cpa_opA} + {1'b0, cpa_opB} + cpa_carry;

  logic [iter_step_p-1:0] result_resolved_bits;

  // Registers for result
  reg [width_p-1:0] result_low_r;
  reg [width_p:0] result_remnant_sum_r; 
  reg [width_p-1:0] result_remnant_carry_r;

  assign cpa_carry = result_remnant_sum_r[width_p];
  assign cpa_opA = result_remnant_sum_r[iter_step_p-1:0];
  assign cpa_opB = result_remnant_carry_r[iter_step_p-1:0];

  // Using a string of CSAs to generate result
  wire [iter_step_p:0][width_p:0] cascade_csa_res;
  wire [iter_step_p:0][width_p-1:0] cascade_csa_car;
  assign cascade_csa_res[0] = {result_remnant_sum_r[width_p-1:0],1'b0};
  assign cascade_csa_car[0] = result_remnant_carry_r;
  for(genvar i = 0; i < iter_step_p; ++i) begin: CSA_ARRAY
    if(i == iter_step_p - 1) begin
      wire [width_p-1:0] partial_sum_last_csa = (cal_state_counter_r == '1) ? ((opA_r ^ {width_p{opB_neg_r}}) & {width_p{opB_r[i]}}) : (opA_r & {width_p{opB_r[i]}});
      bsg_adder_carry_save #(
        .width_p(width_p)
      ) csa_adder (
        .opA_i(cascade_csa_res[i][width_p:1])
        ,.opB_i(cascade_csa_car[i])
        ,.opC_i(partial_sum_last_csa)
        ,.res_o(cascade_csa_res[i+1][width_p-1:0])
        ,.car_o(cascade_csa_car[i+1])
      );
      assign result_resolved_bits[i] = cascade_csa_res[i+1][0];
      assign cascade_csa_res[i+1][width_p] = ((~opB_r[i]) & opA_neg_r) ^ (opB_neg_r && cal_state_counter_r == '1);
    end
    else begin
      bsg_adder_carry_save #(
        .width_p(width_p)
      ) csa_adder (
        .opA_i(cascade_csa_res[i][width_p:1])
        ,.opB_i(cascade_csa_car[i])
        ,.opC_i(opA_r & {width_p{opB_r[i]}})
        ,.res_o(cascade_csa_res[i+1][width_p-1:0])
        ,.car_o(cascade_csa_car[i+1])
      );
      assign result_resolved_bits[i] = cascade_csa_res[i+1][0];
      assign cascade_csa_res[i+1][width_p] = (~opB_r[i]) & opA_neg_r;
    end
  end // CSA_ARRAY

  // Add update to final higher part of result

  logic [width_p-1:0] result_low_n;
  logic [width_p:0] result_remnant_sum_n;
  if (iter_step_p == width_p) begin
    assign result_low_n = result_resolved_bits;
    assign result_remnant_sum_n = cpa_opt[width_p-1:0];
  end
  else begin
    assign result_low_n = {result_resolved_bits[iter_step_p-1:0], result_low_r[width_p-1:iter_step_p]};
    assign result_remnant_sum_n = {cpa_opt, result_remnant_sum_r[width_p-1:iter_step_p]};
  end

  // Update the result and remnant result.
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      result_low_r <= '0;
      result_remnant_carry_r <= '0;
      result_remnant_sum_r <= '0;
    end
    else begin
      if(state_r == eIDLE && v_i) begin
        result_low_r <= '0;
        result_remnant_sum_r <= {opA_signed_n,(width_p)'(0)};
        result_remnant_carry_r <= {opB_signed_n, (width_p-1)'(0)};
      end
      else if(state_r == eCAL) begin
        result_low_r <= result_low_n;
        result_remnant_carry_r <= cascade_csa_car[iter_step_p];
        result_remnant_sum_r[width_p-1:0] <= cascade_csa_res[iter_step_p][width_p:1];
      end
      else if(state_r == eCPA) begin
        result_remnant_sum_r <= result_remnant_sum_n;
        result_remnant_carry_r <= result_remnant_carry_r >> iter_step_p;
      end 
    end 
  end
  
  assign v_o = state_r == eDONE;

  if(full_sized_p) begin: FULL_RESULT_O
    assign result_o = {result_remnant_sum_r[width_p-1:0], result_low_r};
  end //FULL_RESULT_O
  else begin: HALF_RESULT_O
    assign result_o = result_low_r;
  end //HALF_RESULT_O

  if(debug_p) begin
    always_ff @(posedge clk_i) begin
      $display("======================================================");
      $display("state_r:%s", state_r);
      $display("cal_state_counter_r:%b",cal_state_counter_r);
      $display("opA_r:%b", opA_r);
      $display("opB_r:%b", opB_r);
      $display("result_remnant_sum_r:%b", result_remnant_sum_r);
      $display("result_remnant_carry_r:%b", result_remnant_carry_r);
      $display("cpa_opt:%b", cpa_opt);
      $display("result_resolved_bits:%b", result_resolved_bits);
      $display("result_remnant_sum_n:%b", result_remnant_sum_n);
      for(logic [31:0] i = 0; i <= iter_step_p; ++i)
        $display("cascade_csa_res[%b]:%b",i, cascade_csa_res[i]);
      for(logic [31:0] i = 0; i <= iter_step_p; ++i)
        $display("cascade_csa_car[%b]:%b",i, cascade_csa_car[i]);
      $display("result_remnant_carry_r:%b",result_remnant_carry_r);
    end
  end
  
endmodule

