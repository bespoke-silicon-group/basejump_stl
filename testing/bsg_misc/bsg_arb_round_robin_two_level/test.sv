module test;
  
  logic reset_li, clk, yumi_li;
   logic [2:0] req_li, gnt_lo;
   logic [2:0] req_li_r;
 
  bsg_arb_round_robin_two_level 
  #(.width_p(1)) barr2
  (.reset_i()
   ,.clk_i(clk)
   ,.reqs_i({ 1'b0, 1'b1 })
   ,.grants_o()
   ,.granted_high_o()
   ,.yumi_i()
  );

   wire       granted_high_lo;
   
  bsg_arb_round_robin_two_level
  #(.width_p(3)) barr
  (.reset_i(reset_li)
   ,.clk_i(clk)
   ,.reqs_i({ req_li_r, 3'b111 ^ req_li_r })
   ,.grants_o(gnt_lo)
   ,.granted_high_o(granted_high_lo)
   ,.yumi_i(yumi_li)
  );

   always @(negedge clk)
     $display("reset = %b, clk=%b, req_li=%b, gnt_lo=%b, granted_high=%b, yumi_li=%b, thermo_code_low=%b, thermo_code_high=%b",reset_li,clk,barr.reqs_i,gnt_lo,granted_high_lo,yumi_li,barr.low.yumi_i ? barr.low.fi2.thermocode_n : barr.low.fi2.thermocode_r, barr.hi.yumi_i ? barr.hi.fi2.thermocode_n : barr.hi.fi2.thermocode_r);

   always @(posedge clk)
     req_li_r <= req_li;

   initial
     begin
	clk = 0;
	while (1)
	  #10 clk = ~ clk;
     end	

   assign yumi_li = | gnt_lo;
   
  initial begin
     reset_li = 1;
     req_li = 3'b00;
     @(negedge clk);
     reset_li = 0;
     @(negedge clk);
     req_li = 3'b001;    
     @(negedge clk);
     req_li = 3'b001;
     @(negedge clk);
     req_li = 3'b111;
     @(negedge clk);
     req_li = 3'b010;
     @(negedge clk);
     req_li = 3'b111;
     @(negedge clk);
     req_li = 3'b100;     
     @(negedge clk);

     $finish;
  end
    
endmodule
