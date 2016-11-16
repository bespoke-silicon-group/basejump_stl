//====================================================================
// test_bsg.v
// 11/15/2016, shawnless.xie@gmail.com
//====================================================================
//
`define NUM     4
`define WIDTH   4
`define SIGN
`define UNSIGN

module test_bsg; 
   reg reset;
   reg clk;

   integer i;
   
   logic v_i, ready_o, v_o;
   logic signed_opA,signed_opB;

   logic [`WIDTH-1:0]  result_o;

   logic [`WIDTH-1:0]           opA_i,     opB_i,   expect_result; 
   logic signed [`WIDTH-1:0]  s_expect_result;

   logic [`WIDTH-1:0]  opA [0:`NUM-1] = {4'b0000, 4'b0001, 4'b1010, 4'b1111};
   logic [`WIDTH-1:0]  opB [0:`NUM-1] = {4'b1000, 4'b0011, 4'b0011, 4'b1111};

bsg_imul_iterative #(.width_p(4)) dut (
     .reset_i  ( reset)
    ,.clk_i    ( clk  )

    ,.v_i      ( v_i  )//there is a request
    ,.ready_o  ( ready_o)//idiv is idle 

    ,.opA_i    ( opA_i )
    ,.opB_i    ( opB_i )
    ,.signed_opA_i( signed_opA )
    ,.signed_opB_i( signed_opB )

    ,.v_o      ( v_o   )//result is valid
    ,.result_o ( result_o )
    ,.ready_i  ( 1'b1   )
    );

   initial clk = 0;
   initial reset = 1;
   initial #15 reset = 0;
   always  #10 clk = ~clk;
   
   initial #25 begin
     for (i=0; i<`NUM; i=i+1) begin
	 // do the signed case
	`ifdef SIGN
     wait (ready_o == 1); 
	 opA_i  = opA[i];
	 opB_i  = opB[i];
     signed_opA = 1'b1;
     signed_opB = 1'b1;

	 v_i    = 1;
	 wait (ready_o == 0);
	 v_i    = 0;
	 wait (v_o     == 1);
    
    
     s_expect_result = $signed(opA_i) * $signed(opB_i);	 
	 if ( result_o  !=  s_expect_result ) begin
	    $display("----------- ERROR in signed mul -----------");
	    $display("opA:     0x%x  (%d)",  opA_i, $signed(opA_i));
	    $display("opB:     0x%x  (%d)",  opB_i, $signed(opB_i) );
	    $display("result:  0x%x  (%d),expect 0x%x", result_o, result_o, s_expect_result);
	 end

	`endif
	 
	 // do the unsigned case
	`ifdef UNSIGN
     wait (ready_o == 1); 
	 opA_i  = opA[i];
	 opB_i  = opB[i];
     signed_opA = 1'b0;
     signed_opB = 1'b0;

	 v_i    = 1;
	 wait (ready_o == 0);
	 v_i    = 0;
	 wait (v_o     == 1);
    
     expect_result = opA_i * opB_i;	 
	 if ( result_o  !=  expect_result ) begin
	    $display("----------- ERROR in unsigned mul -----------");
	    $display("opA:     0x%x  (%d)",   opA_i, opA_i);
	    $display("opB:     0x%x  (%d)",  opB_i, opB_i );
	    $display("result:  0x%x  (%d),expect 0x%x", result_o, result_o, expect_result);
	 end
	`endif

      end
	
      #80 $finish;
   end
	      
endmodule
 
