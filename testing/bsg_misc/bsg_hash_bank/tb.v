`include "bsg_defines.v"
module tb(input clk);

  localparam width_p = 6;
  localparam banks_p = 7;
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
  
  always @(posedge clk)
    begin
      in_r <= in_r + 1;           
    end	
  
  always @(negedge clk)
    begin
      // $display ("%b -> %b %b -> %b", in_r, bucket_lo, index_lo,lo);
      if (lo != in_r[width_p-1:0])
        $display("MISMATCH: %b -> %b %b -> %b",in_r[width_p-1:0],bank_lo,index_lo,lo);	
      else
        $display("match: %b -> %b %b -> %b",in_r[width_p-1:0],bank_lo, index_lo, lo);
  
      if (in_r[width_p])
        $finish();
    end	
endmodule	
