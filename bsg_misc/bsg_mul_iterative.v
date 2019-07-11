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

  typedef enum [2:0] {eIDLE, eCAL, eCPA, eDONE} state_e; // FSM states.
  state_e current_state_r, current_state_n; // current state and next state.

  wire self_is_ready = ready_o & v_i; 
  // used for reset registers. combining the reset_i and yumi_i
  wire reset_internal = reset_i | (yumi_i & current_state_r == eDONE); 
  // counter used for jumping out of eCAL
  logic [cal_state_length_lp-1:0] cal_state_counter_r;
  // counter update
  always_ff @(posedge clk_i) begin
    if(reset_internal) cal_state_counter_r <= '0;
    else cal_state_counter_r <= (current_state_r == eCAL) ? cal_state_counter_r + 1 : cal_state_counter_r;
  end
  
  // FSM. And the full output version and half output version contain different states.
  always_comb begin
    unique case(current_state_r)
      eIDLE : begin
        if(self_is_ready) 
            current_state_n = eCAL; 
        else 
          current_state_n = eIDLE;
      end
      eCAL : begin
        current_state_n = cal_state_counter_r == '1 ? eCPA : eCAL;
      end
      eCPA : begin
        current_state_n = eDONE;
      end
      eDONE:  current_state_n = eDONE;
      default : current_state_n = eIDLE;
    endcase
  end

  assign ready_o = current_state_r == eIDLE;
  // update current state
  always_ff @(posedge clk_i) begin
    if(reset_internal) begin
      current_state_r <= eIDLE;
    end
    else begin
      current_state_r <= current_state_n;
    end
  end
  // registers to store operands
  logic [width_p - 1:0] opA_r; 
  logic [width_p - 1:0] opB_r;
  logic opA_neg_r; // used to record that opA is negative.
  logic opB_neg_r; // same with statement above

  wire [width_p:0] cpa_opt;

  reg [width_p - 1:0] sign_modification_r;

  // update input registers (opA, opB, opA_neg, opB_neg)
  always_ff @(posedge clk_i) begin
    if(reset_internal) begin
      opA_r <= '0;
      opB_r <= '0;
      opA_neg_r <= 1'b0;
      opB_neg_r <= 1'b0;
      sign_modification_r <= '0;
    end
    else begin
      unique case(current_state_r)  // latch up!
        eIDLE: begin
          if(self_is_ready) begin
            opA_r <= opA_i;
            opB_r <= opB_i;
            opA_neg_r <= opA_i[width_p-1] & opA_is_signed_i;
            opB_neg_r <= opB_i[width_p-1] & opB_is_signed_i;
          end
        end
        eCAL : begin
          sign_modification_r <= cpa_opt;
          opB_r <= (opB_r >> iter_step_p);
        end
        default : begin
        end
      endcase
    end
  end
  // Setup carry propagate operation.
  logic [width_p-1:0] cpa_opA; // operand A of CPA
  logic [width_p-1:0] cpa_opB; // operand B of CPA
  assign cpa_opt = cpa_opA + cpa_opB;

  logic [iter_step_p-1:0] result_resolved_bits;

  // Registers for result
  reg [width_p-1:0] result_low_r;
  reg [width_p-1:0] result_remnant_sum_r; 
  reg [width_p-1:0] result_remnant_carry_r;

  // Determine cpa operands.
  always_comb begin
    unique case(current_state_r) 
      eIDLE: begin
        cpa_opA = '0;
        cpa_opB = '0;
      end
      eCAL : begin 
        cpa_opA = opA_r & ({width_p{opB_neg_r}});
        cpa_opB = opB_r & ({width_p{opA_neg_r}});
      end
      eCPA: begin
        cpa_opA = result_remnant_sum_r;
        cpa_opB = result_remnant_carry_r;
      end
      default: begin
        cpa_opA = '0;
        cpa_opB = '0;
      end
    endcase
  end

  // Using a string of CSAs to generate result
  wire [iter_step_p:0][width_p-1:0] cascade_csa_res;
  wire [iter_step_p:0][width_p-1:0] cascade_csa_car;
  assign cascade_csa_res[0] = result_remnant_sum_r;
  assign cascade_csa_car[0] = result_remnant_carry_r;
  for(genvar i = 0; i < iter_step_p; ++i) begin: CSA_ARRAY
    bsg_adder_carry_save #(
      .width_p(width_p)
    ) csa_adder (
      .opA_i({1'b0, cascade_csa_res[i][width_p-1:1]})
      ,.opB_i(cascade_csa_car[i])
      ,.opC_i(opA_r & {width_p{opB_r[i]}})
      ,.res_o(cascade_csa_res[i+1])
      ,.car_o(cascade_csa_car[i+1])
    );
    assign result_resolved_bits[i] = cascade_csa_res[i+1][0];
  end // CSA_ARRAY

  // Add update to final higher part of result

  logic [width_p-1:0] final_csa_car;
  logic [width_p-1:0] final_csa_res;

  bsg_adder_carry_save #(
    .width_p(width_p)
  ) csa_adder_final (
    .opA_i({1'b0, cascade_csa_res[iter_step_p][width_p-1:1]})
    ,.opB_i(cascade_csa_car[iter_step_p])
    ,.opC_i(~sign_modification_r)
    ,.res_o(final_csa_res)
    ,.car_o(final_csa_car)
  );

  logic [width_p-1:0] result_low_n;
  if (iter_step_p == width_p)
    assign result_low_n = result_resolved_bits;
  else
    assign result_low_n = {result_resolved_bits[iter_step_p-1:0], result_low_r[width_p-1:iter_step_p]};

  // Update the result and remnant result.
  always_ff @(posedge clk_i) begin
    if(reset_internal) begin
      result_low_r <= '0;
      result_remnant_carry_r <= '0;
      result_remnant_sum_r <= '0;
    end
    else begin
        if(current_state_r == eCAL) begin
          result_low_r <= result_low_n;
          if(cal_state_counter_r == '1) begin
            // The last iteration
            result_remnant_carry_r <= {final_csa_car[width_p-2:0],1'b1};
            result_remnant_sum_r <= final_csa_res;
          end
          else begin
            result_remnant_carry_r <= cascade_csa_car[iter_step_p];
            result_remnant_sum_r <= cascade_csa_res[iter_step_p];
          end
        end
        else if(current_state_r == eCPA) begin
          result_remnant_sum_r <= cpa_opt;
        end 
    end 
  end
  
  assign v_o = current_state_r == eDONE;

  if(full_sized_p) begin: FULL_RESULT_O
    assign result_o = {result_remnant_sum_r[width_p-1:0], result_low_r};
  end //FULL_RESULT_O
  else begin: HALF_RESULT_O
    assign result_o = result_low_r;
  end //HALF_RESULT_O
  
endmodule

