`include "bsg_defines.sv"
`include "bsg_idiv_unsigned_recip.svh"

module imod_tester #(parameter numer_width_p
		     , denom_max_width_p
		     , denom_min_width_p // highorder bit must be at denom_min_width_p or higher
		     , debug_p=1
		     )
   (
    input clk_i
    );

   bit   [numer_width_p-1:0] numer_li;
   bit   [denom_max_width_p-1:0] denom_li, result_lo;
   
   bsg_imod_range #(.numer_width_p(numer_width_p)
		    ,.denom_max_width_p(denom_max_width_p)
		    ,.denom_min_width_p(denom_min_width_p)
		    ) imod
     (.numer_i(numer_li)
      ,.denom_i(denom_li)
      ,.o(result_lo)
      );
   
   always @(negedge clk_i)
     begin
	std::randomize(numer_li);
	std::randomize(denom_li);

	if (denom_min_width_p != '0)
	  begin 
	     while (denom_li[denom_max_width_p-1:denom_min_width_p-1] == '0)
	       std::randomize(denom_li);
	  end
     end
   
   always @(posedge clk_i)
     if (numer_li % denom_li != result_lo)
       $fatal("%m FAIL: mismatch nwidth=%h dwidth=(%h %h), %h %% %h = %h vs %h\n",numer_width_p, denom_min_width_p, denom_max_width_p,
	      numer_li,denom_li,numer_li%denom_li,result_lo);
     else
       if (debug_p)
       $display("%m PASS: match nwidth=%h dwidth=(%h %h), %h %% %h = %h vs %h\n",numer_width_p, denom_min_width_p, denom_max_width_p,
		numer_li,denom_li,numer_li%denom_li,result_lo);

   genvar i;

   if (debug_p==2)
   for (i = 0; i < denom_max_width_p-denom_min_width_p+1+1; i++)
     always @(posedge clk_i)
       $display("%m %d %b - %b = %b (%b)",i,imod.remainder[i],imod.denom_i,imod.difference[i],imod.too_small[i]);
  
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

   genvar i,j,k;

   for (i = 8; i < 9; i+=8)
     for (j = 2; j < 9; j+=1)
       for (k = 0; k <= j; k++)       
	 imod_tester #(.numer_width_p(i)
		       ,.denom_max_width_p(j)
		       ,.denom_min_width_p(k)
		       ) idt (clk_lo);

endmodule
     
   
   
