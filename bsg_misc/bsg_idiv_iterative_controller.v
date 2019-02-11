//====================================================================
// bsg_idiv_iterative_controller.v
// 11/14/2016, shawnless.xie@gmail.com
//====================================================================
//
// The controller of bsg_idiv_iterative module.
// Code refactored based on Sam Larser's work

module bsg_idiv_iterative_controller (
	   input               clk_i
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
           {WAIT,   START,  NEG0,   NEG1,   SHIFT,  CALC0,  CALC1,  CALC2,
            CALC3,  CALC4,  CALC5,  CALC6,  CALC7,  CALC8,  CALC9,  CALC10,
            CALC11, CALC12, CALC13, CALC14, CALC15, CALC16, CALC17, CALC18,
            CALC19, CALC20, CALC21, CALC22, CALC23, CALC24, CALC25, CALC26,
            CALC27, CALC28, CALC29, CALC30, CALC31, CALC32, REPAIR, REMAIN, 
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
      //yumi_o         = 1'b0;
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
	  // yumi_o    = 1'b1;
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
	   next_state   = CALC0;
	   opA_clr_l_o  = 1'b0;
	   opB_clr_l_o  = 1'b0;
	   adder_cin_o  = 1'b0;
	end

	CALC0: next_state = CALC1;
	CALC1: next_state = CALC2;       
	CALC2: next_state = CALC3;       
	CALC3: next_state = CALC4;       
	CALC4: next_state = CALC5;       
	CALC5: next_state = CALC6;       
	CALC6: next_state = CALC7;       
	CALC7: next_state = CALC8;       
	CALC8: next_state = CALC9;       
	CALC9: next_state = CALC10;       
	CALC10: next_state = CALC11;       
	CALC11: next_state = CALC12;       
	CALC12: next_state = CALC13;       
	CALC13: next_state = CALC14;       
	CALC14: next_state = CALC15;       
	CALC15: next_state = CALC16;       
	CALC16: next_state = CALC17;       
	CALC17: next_state = CALC18;       
	CALC18: next_state = CALC19;       
	CALC19: next_state = CALC20;       
	CALC20: next_state = CALC21;       
	CALC21: next_state = CALC22;       
	CALC22: next_state = CALC23;       
	CALC23: next_state = CALC24;       
	CALC24: next_state = CALC25;       
	CALC25: next_state = CALC26;       
	CALC26: next_state = CALC27;       
	CALC27: next_state = CALC28;       
	CALC28: next_state = CALC29;       
	CALC29: next_state = CALC30;       
	CALC30: next_state = CALC31;       
	CALC31: next_state = CALC32;
	
	CALC32: begin
	   next_state = REPAIR;
	   opB_sel_o    = 3'b010;
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
