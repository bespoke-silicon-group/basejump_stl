`timescale 1ps/1ps
/*************************************************************
==================================================
bsg_mul_iterative.v
3/14/2019, sqlin16@fudan.edu.cn
===================================================

An 32 bits integer interative multiplier, capable of singed & unsigned division,
with configurable stide for each iteration.

States:

eIDNE:          Ready for input. 
eCAL:           Add the partial products using CSA. CPA is also used to calculate the lower bits of the result.
eADJ:           Adjust the high part by adding a -opA if opB is negative.
eCPA:           Recover the result by CPA.
eDONE:          Output the result

Parameters:

width_p:        Length of opreands
iter_step_p:    Stride of each iteration of adding.(How many partial products are added in one iteration)
full_output_p:  Type of results. A 64bit result will be generated with full_output_p = 1.
output_size_lp: Length of the results, which is defined as width_p*(full_output_p+1) by default.

TODO:
  1. Removing unnecessary state eADJ from the half version of multiplier.
  2. Using booth recode to eliminate prefix 1 from sign extension

************************************************************/
module bsg_mul_iterative #(
  parameter width_p = -1
  ,parameter iter_step_p = -1
  ,parameter full_output_p = 1
  ,parameter output_size_lp = width_p*(full_output_p+1)
)
(
  input clk_i
  ,input reset_i
  // shakehand signal
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

  localparam integer iter_count_lp = (width_p - 1)/iter_step_p + 1; // calculate how many iterations shoubd be done.
  localparam cal_state_length_lp = `BSG_SAFE_CLOG2(iter_count_lp);  // calculate the length of counter used for eCAL state.

  localparam actual_width_lp = iter_count_lp * iter_step_p;         // to align the width_p, which is equal to width_p providing width_p % iter_step_p == 0.
  
  initial assert(actual_width_lp == width_p) else $error("Alignment of stride is required for configurable iteration multiplier!");

  typedef enum [2:0] {eIDNE, eCAL, eADJ, eCPA, eDONE} state_e; // FSM states.
  state_e current_state_r, current_state_n; // curretn state and next state.

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
  generate 
    if(iter_step_p != actual_width_lp)
      always_comb begin
        unique case(current_state_r)
          eIDNE : begin
            if(self_is_ready) 
                current_state_n = eCAL; 
            else 
              current_state_n = eIDNE;
          end
          eCAL : begin
            if(cal_state_counter_r == '1)
                current_state_n = eADJ;
            else
                current_state_n = eCAL;
          end
          eADJ: begin
            current_state_n = eCPA;
          end
          eCPA : begin
            current_state_n = eDONE;
          end
          eDONE:  current_state_n = eDONE;
          default : current_state_n = eIDNE;
        endcase
      end
    else
      always_comb begin
        unique case(current_state_r)
          eIDNE : begin
            if(self_is_ready) 
                current_state_n = eCAL; 
            else 
              current_state_n = eIDNE;
          end
          eCAL : begin
            current_state_n = eADJ;
          end
          eADJ: begin
            current_state_n = eCPA;
          end
          eCPA : begin
            current_state_n = eDONE;
          end
          eDONE:  current_state_n = eDONE;
          default : current_state_n = eIDNE;
        endcase
      end
  endgenerate

  assign ready_o = current_state_r == eIDNE;
  // update curren state
  always_ff @(posedge clk_i) begin
    if(reset_internal) begin
      current_state_r <= eIDNE;
    end
    else begin
      current_state_r <= current_state_n;
    end
  end
  // registers to store operands
  logic [actual_width_lp - 1:0] opA_r; 
  logic [actual_width_lp - 1:0] opB_r;
  logic opA_neg_r; // used to record that opA is negative.
  logic opB_neg_r; // same with statement above

  wire [actual_width_lp:0] cpa_opt;

  reg [actual_width_lp - 1:0] sign_modification_r;

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
        eIDNE: begin
          if(self_is_ready) begin
            opA_r <= opA_i;
            opB_r <= opB_i;
            opA_neg_r <= opA_i[actual_width_lp-1] & opA_is_signed_i;
            opB_neg_r <= opB_i[actual_width_lp-1] & opB_is_signed_i;
          end
        end
        eCAL : begin
          if(cal_state_counter_r == '0)
            sign_modification_r <= cpa_opt;
          opB_r <= (opB_r >> iter_step_p);
        end
        default : begin
        end
      endcase
    end
  end
  // Setup carry propagate operation.
  logic [actual_width_lp-1:0] cpa_opA; // operand A of CPA
  logic [actual_width_lp-1:0] cpa_opB; // operand B of CPA
  assign cpa_opt = cpa_opA + cpa_opB;

  localparam csa_outout_size_lp = actual_width_lp + full_output_p * iter_step_p;

  // CSA network output.
  logic [csa_outout_size_lp:0] csa_sum;    // sum of last CSA
  logic [csa_outout_size_lp:0] csa_carry;  // carry of last CSA

  // CPA result remnant in last addition, which should be added in next turn.

  // Bits of result which can be determined in this turn are sent to CPA.
  reg [iter_step_p-1:0] csa_sum_lowpart; //= csa_sum[iter_step_p-1:0];
  reg [iter_step_p-1:0] csa_carry_lowpart; //= {csa_carry[iter_step_p-1:1],carry_from_cpa_in_eCAL_stage_r};
  always_ff @(posedge clk_i) begin
    if(reset_internal) begin
      csa_sum_lowpart <= '0;
      csa_carry_lowpart <= '0;
    end
    else if(current_state_r == eCAL) begin
      csa_sum_lowpart <= csa_sum[iter_step_p-1:0];
      csa_carry_lowpart <= {csa_carry[iter_step_p-1:1],cpa_opt[iter_step_p] & (cal_state_counter_r != '0)};
    end
  end

  // Registers for result
  reg [actual_width_lp-1:0] result_low_r;
  reg [actual_width_lp-1:0] result_remnant_sum_r; 
  reg [actual_width_lp-1:0] result_remnant_carry_r;

  // Output of wallace tree, which will be passed to a 4-2 CSA where they are added with result_remnant.
  wire [csa_outout_size_lp -1:0] wallace_tree_opt_1;
  wire [csa_outout_size_lp -1:0] wallace_tree_opt_2;

  // Determine cpa operands.
  always_comb begin
    unique case(current_state_r) 
      eIDNE: begin
        cpa_opA = '0;
        cpa_opB = '0;//opB_i & {actual_width_lp{opA_neg_n}};
      end
      eCAL : begin 
        cpa_opA = cal_state_counter_r == '0 ? opA_r & ({actual_width_lp{opB_neg_r}}) : csa_sum_lowpart;
        cpa_opB = cal_state_counter_r == '0 ? opB_r & ({actual_width_lp{opA_neg_r}}) : csa_carry_lowpart;
      end
      eADJ: begin
        cpa_opA = csa_sum_lowpart;
        cpa_opB = csa_carry_lowpart;
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

  generate begin: ADDER_TREE_BLOCK
    if(iter_step_p == 1) begin: NO_CSA
      bsg_adder_carry_save #(.width_p(actual_width_lp))
      csa(
        .opA_i(opA_r & {actual_width_lp{opB_r[0]}}) // sign extension to 64bit
        ,.opB_i(result_remnant_sum_r)
        ,.opC_i(result_remnant_carry_r)

        ,.res_o(csa_sum)
        ,.car_o(csa_carry[actual_width_lp:1])
      );
      assign csa_carry[0] = cpa_opt[iter_step_p];
      assign wallace_tree_opt_1 = '0;
      assign wallace_tree_opt_2 = '0;
    end
    else begin: WALLACE_TREE
      wire [iter_step_p-1:0][csa_outout_size_lp-1:0] ops;
      for(genvar i = 0; i < iter_step_p; ++i)
        assign ops[i] = {opA_r & {actual_width_lp{opB_r[i]}}} << i; // sign extension to 64bit
      
      wire [csa_outout_size_lp -1:0] res_A_li;
      wire [csa_outout_size_lp -1:0] res_B_li;
      // A full-sized wallace tree.
      bsg_adder_wallace_tree #(
        .width_p(csa_outout_size_lp)
        ,.iter_step_p(iter_step_p)
        ,.max_out_size_lp(csa_outout_size_lp)
      )
      tree(
        .op_i(ops)
        ,.res_A_o(res_A_li)
        ,.res_B_o(res_B_li)
      );
      assign wallace_tree_opt_1 = res_A_li;
      assign wallace_tree_opt_2 = res_B_li;
    end
  end
  endgenerate
  // Input of the final 4-2 CSA
  logic [csa_outout_size_lp -1:0] csa_opA;
  logic [csa_outout_size_lp -1:0] csa_opB;
  always_comb begin
    unique case(current_state_r)
      eCAL: begin
        csa_opA = wallace_tree_opt_1;
        csa_opB = wallace_tree_opt_2;
      end
      // A modification is need to the high part of the result as the MSB weight is negative when opB is a signed number.
      eADJ: begin 
        csa_opA = ~sign_modification_r;
        csa_opB = 1'b1;
      end
      default: begin
        csa_opA = '0;
        csa_opB = '0;
      end
    endcase
  end
  // 4-2 CSA

  bsg_adder_carry_save_4_2 #(
    .width_p(csa_outout_size_lp)
  )
  fa4_2(
    .opA_i(csa_opA)
    ,.opB_i(csa_opB)
    ,.opC_i(csa_outout_size_lp'(result_remnant_sum_r))
    ,.opD_i(csa_outout_size_lp'(result_remnant_carry_r))

    ,.outA_o(csa_sum)
    ,.outB_o(csa_carry)
  );
  // Update the result and remant result.
  generate 
    if(actual_width_lp != iter_step_p) begin: FULL
      always_ff @(posedge clk_i) begin
        if(reset_internal) begin
          result_low_r <= '0;
          result_remnant_carry_r <= '0;
          result_remnant_sum_r <= '0;
        end
        else begin
            unique case(current_state_r) 
              eCAL: begin
                result_low_r <= {cpa_opt[iter_step_p-1:0],result_low_r[actual_width_lp-1:iter_step_p]};
                result_remnant_sum_r <= csa_sum[csa_outout_size_lp-1:iter_step_p];
                result_remnant_carry_r <= csa_carry[csa_outout_size_lp-1:iter_step_p];
              end
              eADJ:begin
                result_low_r <= {cpa_opt[iter_step_p-1:0],result_low_r[actual_width_lp-1:iter_step_p]};
                result_remnant_sum_r <= csa_sum[actual_width_lp-1:0];
                result_remnant_carry_r <= {csa_carry[actual_width_lp-1:1], cpa_opt[iter_step_p]};
              end
              eCPA: begin
                result_remnant_sum_r <= cpa_opt;
              end
              default: begin

              end
            endcase
        end
      end
    end
    else begin
      always_ff @(posedge clk_i) begin
        if(reset_internal) begin
          result_low_r <= '0;
          result_remnant_carry_r <= '0;
          result_remnant_sum_r <= '0;
        end
        else begin
            unique case(current_state_r) 
              eCAL: begin
                result_remnant_sum_r <= csa_sum[csa_outout_size_lp-1:iter_step_p];
                result_remnant_carry_r <= csa_carry[csa_outout_size_lp-1:iter_step_p];
              end
              eADJ:begin
                result_low_r <= cpa_opt[iter_step_p-1:0];
                result_remnant_sum_r <= csa_sum[actual_width_lp-1:0];
                result_remnant_carry_r <= {csa_carry[actual_width_lp-1:1], cpa_opt[iter_step_p]};
              end
              eCPA: begin
                result_remnant_sum_r <= cpa_opt;
              end
              default: begin

              end
            endcase
        end
      end
    end
  endgenerate
  
  assign v_o = current_state_r == eDONE;

  generate 
    if(full_output_p)
      assign result_o = {result_remnant_sum_r[actual_width_lp-1:0], result_low_r};
    else
      assign result_o = result_low_r;
  endgenerate
  
endmodule