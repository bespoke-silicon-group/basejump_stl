//====================================================================
// test_bsg.v
// 11/14/2016, shawnless.xie@gmail.com
//====================================================================
// Code refactored based on Sam Larserk's work
//
//`define ITERS   24000000
`define ITERS 256
`define SIGN			// test signed divide
`define UNSIGN			// test unsigned divide
`define WIDTH 4

module test_bsg;

   reg div_req;
   reg signed_div;
   
   wire ready_o;
   wire done;
   
   reg reset;
   reg clk;

   integer i, f1, f2;

   reg  [`WIDTH-1:0] dividend;
   reg  [`WIDTH-1:0] divisor;
   wire [`WIDTH-1:0] quotient;
   wire [`WIDTH-1:0] remainder;
   
   reg  [`WIDTH-1:0] u_dividend;
   reg  [`WIDTH-1:0] u_divisor;   
   reg  [`WIDTH-1:0] u_quotient;
   reg  [`WIDTH-1:0] u_remainder;

   byte s_dividend;
   byte s_divisor;
   byte s_quotient;
   byte s_remainder;

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
      f1 = $fopen("s_output.txt","w");
      f2 = $fopen("u_output.txt","w");
      for (i=0; i<`ITERS; i=i+1) begin
	 $get_stim(dividend, divisor);

	 // do the signed case
	`ifdef SIGN
	 s_dividend = {{4{dividend[`WIDTH-1]}}, dividend[`WIDTH-1:0]};
	 s_divisor  = {{4{divisor[`WIDTH-1]}}, divisor[`WIDTH-1:0]};

	 signed_div = 1;
	 
	 wait (ready_o == 1);
	 div_req = 1; 
	 wait (ready_o == 0);
	 div_req = 0;
	 wait (done == 1);

	 s_quotient  = {{4{quotient[`WIDTH-1]}}, quotient[`WIDTH-1:0]};
	 s_remainder = {{4{remainder[`WIDTH-1]}}, remainder[`WIDTH-1:0]};
	 
	 $fwrite(f1,"%d ", s_dividend);
	 $fwrite(f1,"%d ", s_divisor);
	 $fwrite(f1,"%d ", s_quotient);
	 $fwrite(f1,"%d\n", s_remainder);
     
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
	 
	 $fwrite(f2,"%d ", u_dividend);
	 $fwrite(f2,"%d ", u_divisor);     
	 $fwrite(f2,"%d ", u_quotient);
	 $fwrite(f2,"%d\n", u_remainder);
	 
	`endif

      end
	   
      $fclose(f1);
      $fclose(f2); 
	   
      $done;
      #80 $finish;
   end
	      
endmodule
   
