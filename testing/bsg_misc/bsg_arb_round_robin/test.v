module test;
  
  logic reset_li, clk, yumi_li;
  logic [1:0] req_li, gnt_lo;
 
  bsg_arb_round_robin 
  #(.width_p(1)) barr2
  (.reset_i()
   ,.clk_i(clk)
   ,.reqs_i(1'b1)
   ,.grants_o()
   ,.yumi_i()
  );
  
  bsg_arb_round_robin 
  #(.width_p(2)) barr
  (.reset_i(reset_li)
   ,.clk_i(clk)
   ,.reqs_i(req_li)
   ,.grants_o(gnt_lo)
   ,.yumi_i(yumi_li)
  );
  
  initial begin
    $monitor("reset = %b, clk=%b, req_li=%b, gnt_lo=%b, yumi_li=%b, thermo_code=%b",reset_li,clk,req_li,gnt_lo,yumi_li,barr.fi2.thermocode_r);
    #10 reset_li = 1;
    #10 yumi_li = 0;
    #10 req_li = 2'b00;
    #10 clk = 1;
    #10 reset_li = 0;
    #10 clk = 0;
	  #10 req_li = 2'b01;    
    #10 clk = 1;
    #10 yumi_li = 1;
    #10 clk = 1;
    #10 yumi_li = 0;

    #10 clk = 0;
    #10 req_li = 2'b01;    
    #10 yumi_li = 1;    
    #10 clk = 1;

    #10 clk = 0;
    #10 req_li = 2'b10;    
    #10 yumi_li = 1;    
    #10 clk = 1;
    
    #10 clk = 0;
    #10 req_li = 2'b11;    
    #10 yumi_li = 1;    
    #10 clk = 1;    

    #10 clk = 0;
    #10 req_li = 2'b11;    
    #10 yumi_li = 1;    
    #10 clk = 1;        

    #10 clk = 0;
    #10 req_li = 2'b11;    
    #10 yumi_li = 1;    
    #10 clk = 1;            
    
    
    #10 clk = 0;
    #10 req_li = 2'b00;    
    #10 yumi_li = 0;    
    #10 clk = 1;       
    
  end
    
endmodule
