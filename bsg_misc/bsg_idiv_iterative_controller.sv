//====================================================================
// bsg_idiv_iterative_controller.sv
// 11/14/2016, shawnless.xie@gmail.com
//====================================================================
//
// The controller of bsg_idiv_iterative module.
// Code refactored based on Sam Larser's work

`include "bsg_defines.sv"

module bsg_idiv_iterative_controller #(parameter width_p=32, parameter bits_per_iter_p = 1)
      (input               clk_i
      ,input               reset_i

      ,input               v_i
      ,output              ready_and_o

      ,input               zero_divisor_i
      ,input               signed_div_r_i
      ,input               adder1_result_is_neg_i
      ,input               adder2_result_is_neg_i
      ,input               opA_is_neg_i
      ,input               opC_is_neg_i

      ,output logic [1:0]  opA_sel_o
      ,output logic        opA_ld_o
      ,output logic        opA_inv_o
      ,output logic        opA_clr_l_o

      ,output logic [bits_per_iter_p + 1:0]  opB_sel_o
      ,output logic        opB_ld_o
      ,output logic        opB_inv_o
      ,output logic        opB_clr_l_o

      ,output logic [bits_per_iter_p + 1:0]  opC_sel_o
      ,output logic        opC_ld_o

      ,output logic        latch_signed_div_o
      ,output logic        adder1_cin_o

      ,output logic        v_o
      ,input               yumi_i
      );

   logic q_neg_r;
   logic r_neg_r;
   logic neg_ld;
   logic add1_neg_last_r, add2_neg_last_r;
   
   typedef enum logic[5:0] 
           {WAIT, NEG0, NEG1, SHIFT,
            CALC,
            REPAIR, REMAIN, 
            QUOT,DONE } idiv_ctrl_stat;
   idiv_ctrl_stat state, next_state;

   always @(posedge clk_i) begin
      add1_neg_last_r <= adder1_result_is_neg_i;
      add2_neg_last_r <= adder2_result_is_neg_i;
      
      if (neg_ld) begin
        // the quotient is negated if the signs of the operands differ
        q_neg_r <= (opA_is_neg_i ^ opC_is_neg_i) & signed_div_r_i;

        // the remainder is negated if the dividend is negative
        r_neg_r <= opC_is_neg_i & signed_div_r_i;
      end 
   end

  logic [`BSG_WIDTH(width_p/bits_per_iter_p)-1:0] calc_cnt;
  wire calc_up_li = (state == CALC) && (calc_cnt < width_p/bits_per_iter_p);
  wire calc_done  = (calc_cnt == width_p/bits_per_iter_p);
  bsg_counter_clear_up#(.max_val_p(width_p/bits_per_iter_p)
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
      opA_sel_o      = 2'b00;
      opA_ld_o       = 1'b0;

      if (bits_per_iter_p == 2)
        opA_inv_o    = !add2_neg_last_r;
      else
	opA_inv_o    = !add1_neg_last_r;
      
      opA_clr_l_o    = 1'b1;
	   
      if (bits_per_iter_p == 2)
        opB_sel_o      = 4'b0001;
      else
        opB_sel_o      = 3'b001;
      
      opB_ld_o       = 1'b0;
      opB_inv_o      = 1'b0;
      opB_clr_l_o    = 1'b1;
      opC_sel_o      = 3'b001;
      opC_ld_o       = 1'b0;
      
      if (bits_per_iter_p == 2)
        adder1_cin_o    = !add2_neg_last_r;
      else
        adder1_cin_o    = !add1_neg_last_r;
     
      neg_ld         = 1'b0;
      latch_signed_div_o   = 1'b0;
      next_state    = WAIT;
    
    case (state)

    WAIT: begin
       if (v_i) begin
          opA_ld_o     = 1'b1;
          opC_ld_o     = 1'b1;
          latch_signed_div_o = 1'b1;
          next_state   = NEG0;
          opA_sel_o    = 2'b10;
          
          if (bits_per_iter_p == 2) 
            opC_sel_o = 4'b1000;
          else
	    opC_sel_o = 3'b100;
       end
      
    end
    
    NEG0: begin
       next_state = (opC_is_neg_i & signed_div_r_i) ? NEG1 : SHIFT;
       opA_sel_o    = 2'b01;
       opA_inv_o    = 1'b1;
       opB_clr_l_o  = 1'b0;
       opB_ld_o     = 1'b1;
       opC_ld_o     = 1'b0;
       neg_ld       = 1'b1;
       adder1_cin_o  = 1'b1;
       opA_ld_o     = opA_is_neg_i & signed_div_r_i;

       if (bits_per_iter_p == 2)
	 opB_sel_o = 4'b1000;
       else
	 opB_sel_o = 3'b100;
    end

    NEG1: begin
       next_state = SHIFT;
       opA_clr_l_o  = 1'b0;
       opB_inv_o    = 1'b1;
       opB_ld_o     = 1'b0;
       opC_ld_o     = 1'b1;
       adder1_cin_o = 1'b1;
      
       if (bits_per_iter_p == 2)
	 opC_sel_o = 4'b0100;
       else
         opC_sel_o = 3'b010;
    end

    SHIFT: begin
       next_state   = CALC;
       opB_ld_o     = 1'b1;
       opC_ld_o     = 1'b1;
       opA_clr_l_o  = 1'b0;
       opB_clr_l_o  = 1'b0;
       adder1_cin_o  = 1'b0;
       
       if (bits_per_iter_p == 2) begin
	 opC_sel_o = 4'b0010;
         opB_sel_o = 4'b0010;
       end else begin
	 opC_sel_o = 3'b001;
         opB_sel_o = 3'b001;
       end
    end

    CALC: begin
       opB_ld_o     = 1'b1;
       opC_ld_o     = 1'b1;
       if (bits_per_iter_p == 2) begin
         opB_sel_o  = calc_done ? 4'b0100 : 4'b0001;
	 opC_sel_o  = calc_done ? 4'b0010 : 4'b0001;
         if (calc_cnt == 0) begin
	   opA_inv_o    = !add1_neg_last_r;
	   adder1_cin_o = !add1_neg_last_r;
         end
       end else
         opB_sel_o  = calc_done ? 3'b010 : 3'b001;
       
       if (calc_done) begin
          if (adder1_result_is_neg_i) next_state = REPAIR;
          else next_state = REMAIN;
       end else 
          next_state = CALC;
    end

    REPAIR: begin
       next_state = REMAIN;
       opA_inv_o    = 1'b0;
       opB_ld_o     = 1'b1;
       opC_ld_o     = 1'b0;
       adder1_cin_o    = 1'b0;
       
       if (bits_per_iter_p == 2)
         opB_sel_o = 4'b0100;
       else
	 opB_sel_o = 3'b010;
    end
    
    REMAIN: begin
	    next_state = (zero_divisor_i | !q_neg_r) ? DONE: QUOT;
       opA_sel_o    = 2'b01;
       opA_ld_o     = 1'b1;
       opA_clr_l_o  = 1'b0;
       opB_ld_o     = 1'b1;
       opC_ld_o     = 1'b0;
       opB_inv_o    = r_neg_r;
       adder1_cin_o    = r_neg_r;

       if (bits_per_iter_p == 2)
         opB_sel_o = 4'b1000;
       else
	 opB_sel_o = 3'b100;
    end    

    QUOT: begin
       next_state = DONE;
       opA_clr_l_o  = 1'b0;
       opB_inv_o    = 1'b1;
       opB_ld_o     = 1'b0;
       opC_ld_o     = 1'b1;
       adder1_cin_o  = 1'b1;

       if (bits_per_iter_p == 2)
	 opC_sel_o = 4'b0100;
       else
	 opC_sel_o = 3'b010;
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

  assign ready_and_o  =  ( state == WAIT );
  assign v_o      =  ( state == DONE );

endmodule // divide_control 
