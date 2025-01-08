`include "bsg_defines.sv"
`include "bsg_idiv_unsigned_recip.svh"

module idiv_tester #(parameter numer_width_p
		     , denom_width_p
		     )
   (
    input clk_i
    );

   logic [numer_width_p-1:0] li,lo;
   bit   [numer_width_p-1:0] numer_li, result_lo;
   bit   [denom_width_p-1:0] denom_li;

   logic [`bsg_idiv_unsigned_recip_multiply_width(numer_width_p)-1:0]   mul_li;
   logic [`bsg_idiv_unsigned_recip_shift_width(denom_width_p)-1:0]    shift_li;
   
   bsg_idiv_unsigned_recip #(.numer_width_p(numer_width_p)
				      ,.denom_width_p(denom_width_p)
				      ) div
     (.cfg_multiply_i(mul_li)
      ,.cfg_shift_i(shift_li)
      ,.i(numer_li)
      ,.o(result_lo)
      );

   assign mul_li   = `bsg_idiv_unsigned_recip_multiply(denom_li,numer_width_p,denom_width_p);
   assign shift_li = `bsg_idiv_unsigned_recip_shift(denom_li);
   
   always @(negedge clk_i)
     begin
	std::randomize(numer_li);
	std::randomize(denom_li);
     end
   
   always @(posedge clk_i)
     if (numer_li / denom_li != result_lo)
       $fatal("FAIL: mismatch nwidth=%h dwidth=%h %h / %h = %h vs %h (mul = %h, shift = %h)\n",numer_width_p, denom_width_p, numer_li,denom_li,numer_li/denom_li,result_lo,mul_li,shift_li);
//     else
//       $display("match nwidth=%h dwidth=%h %h / %h = %h vs %h (mul = %h, shift = %h)\n",numer_width_p, denom_width_p, numer_li,denom_li,numer_li/denom_li,result_lo,mul_li,shift_li);
  
endmodule

module test_bsg
  ();

   logic [31:0] counter;
      
initial
  begin
     $display("starting...");
     counter = 0;
  end

   wire clk_lo;
   
   always @(negedge clk_lo)
     begin
	counter = counter + 1;
	if (counter > (1 << 20))
	  $finish("DONE");
     end
   


   bsg_nonsynth_clock_gen #(.cycle_time_p(10)
			    ) cfg
     (.o(clk_lo)
      );

   genvar i,j;

   for (i = 8; i < 40; i+=8)
     for (j = 8; j < 40; j+=8)
       idiv_tester #(.numer_width_p(i)
		     ,.denom_width_p(j)
		     ) idt (clk_lo);

endmodule
     
   
   
