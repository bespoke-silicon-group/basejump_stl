//====================================================================
// test_bsg.v
// 11/14/2016, shawnless.xie@gmail.com
//====================================================================
// Code refactored based on Sam Larserk's work
//
//`define ITERS   24000000
`define ITERS 10000
`define SIGN			// test signed divide
`define UNSIGN			// test unsigned divide
`define WIDTH 64

module test_bsg;

   reg div_req;
   reg signed_div;
   
   wire ready_o;
   wire done;
   
   reg reset;
   reg clk;

   integer i;

   reg  [`WIDTH-1:0] dividend;
   reg  [`WIDTH-1:0] divisor;
   wire [`WIDTH-1:0] quotient;
   wire [`WIDTH-1:0] remainder;
   
   reg  [`WIDTH-1:0] u_dividend;
   reg  [`WIDTH-1:0] u_divisor;   
   reg  [`WIDTH-1:0] u_quotient;
   reg  [`WIDTH-1:0] u_remainder;

   longint s_dividend;
   longint s_divisor;
   longint s_quotient;
   longint s_remainder;

   bsg_idiv_iterative #(.width_p(`WIDTH)) dut (
           .dividend_i(dividend),
	       .divisor_i(divisor),
	       .v_i(div_req),
	       .signed_div_i(signed_div),
	       .quotient_o(quotient),
	       .remainder_o(remainder),
           .ready_o( ready_o ),
	       .v_o(done),
           .yumi_i( done  ),
	       .reset_i(reset),
	       .clk_i(clk));


   initial clk = 0;
   initial reset = 1;
   initial #15 reset = 0;
   always  #10 clk = ~clk;
   
   initial #25 begin
      $init();
      for (i=0; i<`ITERS; i=i+1) begin
	 $get_stim(dividend, divisor);

	 // do the signed case
	`ifdef SIGN
	 s_dividend = dividend;
	 s_divisor  = divisor;

	 signed_div = 1;
	 
	 wait (ready_o == 1);
	 div_req = 1; 
	 wait (ready_o == 0);
	 div_req = 0;
	 wait (done == 1);

	 s_quotient  = quotient;
	 s_remainder = remainder;	 
     //FIXME : when s_dividend == 32'h8000_0000 and s_divisor == 32'hffff_ffff
     //        the VCS crashs, may be the result overflowed !
     if( s_dividend != (1 << `WIDTH) && s_divisor != '1)  begin
	    if ((s_quotient  != s_dividend / s_divisor) ||
	        (s_remainder != s_dividend % s_divisor)) begin
	       $display("----------- ERROR in signed divide -----------");
	       $display("dividend:  0x%x  (%d)",   s_dividend, s_dividend);
	       $display("divisor:   0x%x  (%d)",   s_divisor,  s_divisor);
	       $display("quotient:  0x%x  (%d), except 0x%0x",   s_quotient, s_quotient, s_dividend/s_divisor);
           $display("remainder: 0x%x  (%d), except 0x%0x\n", s_remainder,s_remainder,s_dividend%s_divisor);
         end
    end
	`endif
	 
	 // do the unsigned case
	`ifdef UNSIGN
	 u_dividend = dividend;
	 u_divisor  = divisor;

	 signed_div = 0;

	 wait (ready_o == 1);
	 div_req = 1;
	 wait (ready_o == 0);
	 div_req = 0;
	 wait (done == 1);
	 
	 u_quotient  = quotient;
	 u_remainder = remainder;
	 if ((u_quotient  != u_dividend / u_divisor) ||
	     (u_remainder != u_dividend % u_divisor)) begin
	    $display("----------- ERROR in unsigned divide -----------");
	    $display("dividend:  0x%x  (%d)",   u_dividend, u_dividend);
	    $display("divisor:   0x%x  (%d)",   u_divisor,  u_divisor);
	    $display("quotient:  0x%x  (%d),expect 0x%x",   u_quotient, u_quotient, u_dividend/u_divisor);
        $display("remainder: 0x%x  (%d),expect 0x%x\n", u_remainder,u_remainder,u_dividend%u_divisor);
	 end
	`endif

      end
	
      $done;
      #80 $finish;
   end
	      
endmodule
   
