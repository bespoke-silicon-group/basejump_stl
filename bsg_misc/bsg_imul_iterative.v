//====================================================================
// bsg_imul_iterative.v
// 11/15/2016, shawnless.xie@gmail.com
//====================================================================
//
// An 32bit integer iterative multiplier, capable of signed & unsigned division
module bsg_imul_iterative  #( width_p = 32)
    (input                  reset_i
	,input                  clk_i

	,input                  v_i      //there is a request
    ,output                 ready_o  //idiv is idle 

    ,input [width_p-1: 0]   opA_i
	,input                  signed_opA_i
	,input [width_p-1: 0]   opB_i
	,input                  signed_opB_i

	,output                 v_o      //result is valid
	,output [width_p-1: 0]  result_o
    ,input                  ready_i
    );

    localparam lg_width_lp = `BSG_SAFE_CLOG2( width_p + 1);

///////////////////////////////////////////////////////////////////////////////
//   counter for the shift operation 
   logic[lg_width_lp-1:0]  shift_counter_r;

   wire        shift_counter_full = ( shift_counter_r == width_p ); 

///////////////////////////////////////////////////////////////////////////////
// The state machine
   typedef enum logic[2:0] {IDLE, NEG_A, NEG_B, CALC, NEG_R, DONE } imul_ctrl_stat;
   imul_ctrl_stat curr_state_r, next_state;

   // state machine register
   always_ff@( posedge clk_i ) begin
        if( reset_i )   curr_state_r <= IDLE;
        else            curr_state_r <= next_state;
   end

   //determing next state
   always_comb begin
        unique case(curr_state_r )
            IDLE: begin
                if( v_i )  next_state = NEG_A;
                else       next_state = IDLE;
            end
            
            NEG_A:         next_state = NEG_B;
            NEG_B:         next_state = CALC ;

            CALC: begin
                if( !shift_counter_full ) next_state = CALC;
                else                      next_state = NEG_R;
            end

            NEG_R:         next_state = DONE;

            DONE: begin
                if( ready_i ) next_state = IDLE;
                else          next_state = DONE;
            end

            default: next_state = IDLE;
        endcase
   end
       
///////////////////////////////////////////////////////////////////////////////
//   update the shift_counter_r
   always_ff@( posedge clk_i )  begin
        if ( reset_i ) shift_counter_r <= 'b0;   //reset 
        else if( curr_state_r != CALC  && next_state == CALC )
                       shift_counter_r <= 'b0;   //new request
        else if( curr_state_r == CALC)
                       shift_counter_r <= shift_counter_r + 1;
   end

///////////////////////////////////////////////////////////////////////////////
//   the computation logic
  logic [width_p-1:0]  opA_r, opB_r, result_r;
  logic [width_p-1:0]  adder_a, adder_b, adder_result;

  // -opA_r = ~opA_r + 1, reunsing the adder here
  assign adder_a = (curr_state_r == NEG_A) ? ~opA_r  :  
                   (curr_state_r == NEG_B) ? ~opB_r  :
                   (curr_state_r == NEG_R) ? ~result_r : result_r;

  wire adder_neg_op = (curr_state_r == NEG_A 
                    || curr_state_r == NEG_B 
                    || curr_state_r == NEG_R); 

  assign adder_b = adder_neg_op  ? { {(width_p-1){1'b0}}, 1'b1} 
                                 :  opA_r   ;

  assign adder_result = adder_a + adder_b;

///////////////////////////////////////////////////////////////////////////////
//   operands update logic
  wire latch_input = v_i & ready_o; 

  logic signed_opA_r, signed_opB_r, need_neg_result_r;

  wire  signed_opA = signed_opA_i & opA_i[width_p-1];
  wire  signed_opB = signed_opB_i & opB_i[width_p-1];

  always_ff@(posedge clk_i ) begin
    if( reset_i )                  signed_opA_r <= 1'b0;
    else if( latch_input )         signed_opA_r <= signed_opA; 
  end
   
  always_ff@(posedge clk_i ) begin
    if( reset_i )                  signed_opB_r <= 1'b0;
    else if( latch_input )         signed_opB_r <= signed_opB; 
  end

  always_ff@(posedge clk_i ) begin
    if( reset_i )                  need_neg_result_r <= 1'b0;
    else if( latch_input )         need_neg_result_r <= signed_opA ^ signed_opB ; 
  end

  always_ff@(posedge clk_i) begin
    if( reset_i )                   opA_r <= 'b0;
    else if( latch_input )          opA_r <= opA_i;
    else if(curr_state_r == CALC)   opA_r <= opA_r << 1 ; 
    else if(curr_state_r == NEG_A && signed_opA_r)  
                                    opA_r <= adder_result; //get the abs(opA)
  end 

  always_ff@(posedge clk_i) begin
    if( reset_i )                   opB_r <= 'b0;
    else if( latch_input )          opB_r <= opB_i;
    else if(curr_state_r == CALC)   opB_r <= opB_r >> 1 ; 
    else if(curr_state_r == NEG_B && signed_opB_r)   
                                    opB_r <= adder_result; //get the abs(opB) 
  end 

  always_ff@(posedge clk_i) begin
    if( reset_i )                   result_r <= 'b0;
    else if( latch_input )          result_r <= 'b0;
    else if(curr_state_r == NEG_R && need_neg_result_r)  
                                    result_r <= adder_result; //get the signed result 
    else if(curr_state_r == CALC && opB_r[0]) 
                                    result_r <= adder_result;
  end 


///////////////////////////////////////////////////////////////////////////////
//   the output logic

  assign ready_o    =  ( curr_state_r == IDLE );
  assign result_o   =    result_r;
  assign v_o        =  ( curr_state_r == DONE ); 
endmodule 

