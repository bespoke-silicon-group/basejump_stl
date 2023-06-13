//====================================================================
// test_bsg.sv
// 11/14/2016, shawnless.xie@gmail.com
//====================================================================
// Code refactored based on Sam Larserk's work
//
//

`ifndef WIDTH
`define WIDTH 4
`endif

`ifndef BITS_PER_ITER
`define BITS_PER_ITER 2
`endif

`ifndef ITERS
`define ITERS 2 ** (`WIDTH * 2)
// `define ITERS 10000
`endif

module test_bsg;

   reg div_req;
   reg signed_div;
   
   wire ready_and_o;
   wire done;
   
   reg reset;
   reg clk;

   integer i, f1, f2, f3, f4;

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

   bsg_idiv_iterative #(.width_p(`WIDTH), .bits_per_iter_p(`BITS_PER_ITER)) dut (
           .dividend_i(dividend),
	       .divisor_i(divisor),
	       .v_i(div_req),
	       .signed_div_i(signed_div),
	       .quotient_o(quotient),
	       .remainder_o(remainder),
	   .ready_and_o( ready_and_o ),
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
      f3 = $fopen("s.txt","w");
      f4 = $fopen("u.txt","w");
            
      for (i=0; i<`ITERS; i=i+1) begin
	 $get_stim(dividend, divisor);

	 // do the signed case
	`ifdef SIGN
	 s_dividend = {{(64 - `WIDTH){dividend[`WIDTH-1]}}, dividend[`WIDTH-1:0]};
	 s_divisor  = {{(64 - `WIDTH){divisor[`WIDTH-1]}}, divisor[`WIDTH-1:0]};

	 signed_div = 1;
	 
	 wait (ready_and_o == 1);
	 div_req = 1; 
	 wait (ready_and_o == 0);
	 div_req = 0;
	 wait (done == 1);

	 s_quotient  = {{(64 - `WIDTH){quotient[`WIDTH-1]}}, quotient[`WIDTH-1:0]};
	 s_remainder = {{(64 - `WIDTH){remainder[`WIDTH-1]}}, remainder[`WIDTH-1:0]};
	 
	 $fwrite(f1,"%d %d %d %d\n", s_dividend, s_divisor, s_quotient, s_remainder);
         $fwrite(f3,"%d %d\n", s_dividend, s_divisor);
	 
	`endif
	 
	 // do the unsigned case
	`ifdef UNSIGN
	 u_dividend = dividend;
	 u_divisor  = divisor;

	 signed_div = 0;

	 wait (ready_and_o == 1);
	 div_req = 1;
	 wait (ready_and_o == 0);
	 div_req = 0;
	 wait (done == 1);
	 
	 u_quotient  = quotient;
	 u_remainder = remainder;
	 
	 $fwrite(f2,"%d %d %d %d\n", u_dividend, u_divisor, u_quotient, u_remainder);
	 $fwrite(f4,"%d %d\n", u_dividend, u_divisor);
	 
	`endif

      end
	   
      $fclose(f1);
      $fclose(f2);
      $fclose(f3);
      $fclose(f4); 
	   
      $done;
      #80 $finish;
   end
	      
endmodule
   
