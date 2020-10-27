//====================================================================
// bsg_idiv_iterative_controller.v
// 11/14/2016, shawnless.xie@gmail.com
//====================================================================
//
// The controller of bsg_idiv_iterative module.
// Code refactored based on Sam Larser's work

`include "bsg_defines.v"

module bsg_idiv_iterative_controller #(parameter width_p=32)
      (input               clk_i
      ,input               reset_i

      ,input               v_i
      ,output              ready_o

      ,input               zero_divisor_i
      ,input               signed_div_r_i
      ,input               adder_result_is_neg_i
      ,input               opA_is_neg_i
      ,input               opC_is_neg_i

      ,output logic        opA_sel_o
      ,output logic        opA_ld_o
      ,output logic        opA_inv_o
      ,output logic        opA_clr_l_o

      ,output logic [2:0]  opB_sel_o
      ,output logic        opB_ld_o
      ,output logic        opB_inv_o
      ,output logic        opB_clr_l_o

      ,output logic [2:0]  opC_sel_o
      ,output logic        opC_ld_o

      ,output logic        latch_inputs_o
      ,output logic        adder_cin_o

      ,output logic        v_o
      ,input               yumi_i
      );

   reg q_neg;
   reg r_neg;
   reg neg_ld;
   reg add_neg_last;
   
   typedef enum logic[5:0] 
           {WAIT, START, NEG0, NEG1, SHIFT,
            CALC,
            REPAIR, REMAIN, 
            QUOT,DONE } idiv_ctrl_stat;
   idiv_ctrl_stat state, next_state;

   always @(posedge clk_i) begin
      add_neg_last <= adder_result_is_neg_i;

      if (neg_ld) begin
        // the quotient is negated if the signs of the operands differ
        q_neg <= (opA_is_neg_i ^ opC_is_neg_i) & signed_div_r_i;

        // the remainder is negated if the dividend is negative
        r_neg <= opC_is_neg_i & signed_div_r_i;
      end 
   end

  logic [`BSG_SAFE_CLOG2(width_p+1)-1:0] calc_cnt;
  wire calc_up_li = (state == CALC) && (calc_cnt < width_p);
  wire calc_done  = (calc_cnt == width_p);
  bsg_counter_clear_up#(.max_val_p(width_p)
                       ,.init_val_p(0)
                       ,.disable_overflow_warning_p(1)) calc_counter
      (.clk_i(clk_i)
      ,.reset_i(reset_i)

      // We rely on natural overflow
      ,.clear_i(calc_done)
      ,.up_i(calc_up_li)

      ,.count_o(calc_cnt)
      );

// synopsys sync_set_reset  "reset_i"
   always @(posedge clk_i) begin
      if (reset_i)  state <= WAIT;
      else          state <= next_state;
   end

   always_comb begin
      opA_sel_o      = 1'b0;
      opA_ld_o       = 1'b0;
      opA_inv_o      = !add_neg_last;
      opA_clr_l_o    = 1'b1;
      opB_sel_o      = 3'b001;
      opB_ld_o       = 1'b1;
      opB_inv_o      = 1'b0;
      opB_clr_l_o    = 1'b1;
      opC_sel_o      = 3'b001;
      opC_ld_o       = 1'b1;
      adder_cin_o    = !add_neg_last;
      neg_ld         = 1'b0;
      latch_inputs_o = 1'b0;
      next_state    = WAIT;

    case (state)

    WAIT: begin
       if (v_i) next_state = START;
       latch_inputs_o = 1'b1;
    end

    START: begin
       next_state = NEG0;
       opA_ld_o     = 1'b1;
       opC_ld_o     = 1'b1;
       opA_sel_o    = 1'b1;
       opC_sel_o    = 3'b100;
       opB_ld_o     = 1'b0;
    end
    
    NEG0: begin
       next_state = NEG1;
       opA_inv_o    = 1'b1;
       opB_clr_l_o  = 1'b0;
       opB_sel_o    = 3'b100;
       opC_ld_o     = 1'b0;
       neg_ld       = 1'b1;
       adder_cin_o  = 1'b1;
       opA_ld_o     = opA_is_neg_i & signed_div_r_i;
    end

    NEG1: begin
       next_state = SHIFT;
       opA_clr_l_o  = 1'b0;
       opB_inv_o    = 1'b1;
       opB_ld_o     = 1'b0;
       opC_sel_o    = 3'b010;
       adder_cin_o  = 1'b1;
       opC_ld_o     = opC_is_neg_i & signed_div_r_i;
    end

    SHIFT: begin
       next_state   = CALC;
       opA_clr_l_o  = 1'b0;
       opB_clr_l_o  = 1'b0;
       adder_cin_o  = 1'b0;
    end

    CALC: begin
       opB_sel_o  = calc_done ? 3'b010 : 3'b001;
       next_state = calc_done ? REPAIR : CALC;
    end

    REPAIR: begin
       next_state = REMAIN;
       opA_inv_o    = 1'b0;
       opB_sel_o    = 3'b010;
       opC_ld_o     = 1'b0;
       adder_cin_o    = 1'b0;
       opB_ld_o     = add_neg_last;
    end
    
    REMAIN: begin
       next_state = zero_divisor_i ? DONE: QUOT;
       opA_ld_o     = 1'b1;
       opA_clr_l_o  = 1'b0;
       opB_sel_o    = 3'b100;
       opC_ld_o     = 1'b0;
       opB_inv_o    = r_neg;
       adder_cin_o    = r_neg;
    end    

    QUOT: begin
       if( yumi_i ) next_state = WAIT;
       else         next_state = DONE;
       opA_clr_l_o  = 1'b0;
       opB_inv_o    = 1'b1;
       opB_ld_o     = 1'b0;
       opC_sel_o    = 3'b010;
       adder_cin_o  = 1'b1;
       opC_ld_o     = q_neg;
    end
    
    DONE:begin
        if( yumi_i ) next_state = WAIT;
        else         next_state = DONE;

        opA_ld_o    = 1'b0;
        opB_ld_o    = 1'b0;
        opC_ld_o    = 1'b0;
    end
         
    endcase
   end

  assign ready_o  =  ( state == WAIT );
  assign v_o      =  ( state == DONE );

endmodule // divide_control 
