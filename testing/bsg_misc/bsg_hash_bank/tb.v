`include "bsg_defines.v"

module test_case #(parameter width_p, parameter banks_p) (input clk_i, input go_i, output finish_o);
   

  reg [width_p-1:0] lo;
  reg [width_p:0] in_r;
  wire [$clog2((2**width_p+banks_p-1)/banks_p)-1:0] index_lo;
  wire [`BSG_SAFE_CLOG2(banks_p)-1:0] bank_lo;
  
//  bsg_nonsynth_clock_gen #(.cycle_time_p(5)) clkgen (.o(clk));
  
   
  bsg_hash_bank #(.banks_p(banks_p), .width_p(width_p)) 
             hashme (/* .clk,*/
                     .i( in_r[width_p-1:0] ),
					 
//                     .i({in_r[1:0],in_r[5:2]}), 
                     .bank_o(bank_lo), 
                     .index_o(index_lo)
                    );
  
    
  bsg_hash_bank_reverse #(.banks_p(banks_p), .width_p(width_p)) 
                          unhashme (/* .clk,*/
                                    .o( lo ),
					 
                                    //                     .i({in_r[1:0],in_r[5:2]}),  
                                    .bank_i(bank_lo), 
                     .index_i(index_lo)
                    );

  initial in_r = 0;

  reg finish_r;
   
  initial finish_r = 0;
   
  always @(posedge clk_i)
    begin
      if (!finish_r & go_i)
	begin
	   in_r <= in_r + 1;           
	   finish_r <= in_r[width_p];
	end
    end	

  assign finish_o = finish_r;
   
  always @(negedge clk_i)
    begin
      // $display ("%b -> %b %b -> %b", in_r, bucket_lo, index_lo,lo);
      if (lo != in_r[width_p-1:0])
        $display("(%3d,%3d) MISMATCH: %b -> %b %b -> %b",width_p,banks_p,in_r[width_p-1:0],bank_lo, index_lo, lo);	
      else
	if (!finish_r & go_i)
        $display("(%3d,%3d) match:    %b -> %b %b -> %b",width_p,banks_p,in_r[width_p-1:0],bank_lo, index_lo, lo);
  
    end	
   
endmodule // test_case

module tb(input clk_i);

   localparam tests_p = 10;
   
   wire [tests_p-1:0] finish_lo;

   test_case #(6,1)  tc61  (.clk_i,.finish_o(finish_lo[0]),.go_i(1));
   test_case #(6,2)  tc62  (.clk_i,.finish_o(finish_lo[1]),.go_i(finish_lo[0]));
   test_case #(6,3)  tc63  (.clk_i,.finish_o(finish_lo[2]),.go_i(finish_lo[1]));
   test_case #(6,4)  tc64  (.clk_i,.finish_o(finish_lo[3]),.go_i(finish_lo[2]));   
   test_case #(6,6)  tc66  (.clk_i,.finish_o(finish_lo[4]),.go_i(finish_lo[3]));
   test_case #(6,7)  tc67  (.clk_i,.finish_o(finish_lo[5]),.go_i(finish_lo[4]));
   test_case #(8,7)  tc87  (.clk_i,.finish_o(finish_lo[6]),.go_i(finish_lo[5]));
   test_case #(6,8)  tc68  (.clk_i,.finish_o(finish_lo[7]),.go_i(finish_lo[6]));
   test_case #(6,12) tc612 (.clk_i,.finish_o(finish_lo[8]),.go_i(finish_lo[7]));   
   test_case #(8,15) tc815 (.clk_i,.finish_o(finish_lo[9]),.go_i(finish_lo[8]));

   always @(*)
   if (&finish_lo)
     $finish();
   

endmodule	
