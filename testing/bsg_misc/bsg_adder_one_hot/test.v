module test;

  wire clk_lo;
  logic reset;
  
  bsg_nonsynth_clock_gen #(.cycle_time_p(100)) clkgen (.o(clk_lo));
    
  logic [31:0] ctr;
  
  always @(posedge clk_lo)
    if (reset)
      ctr <= '0;
  else	
      ctr <= ctr + 1'b1;
  
  initial begin
    @(negedge clk_lo)
    reset = 0;
    @(negedge clk_lo)
    reset = 1; 
    @(negedge clk_lo)
    reset = 0;    
  end	
  
  localparam output_width_lp = 4*2-1;
  
  wire [output_width_lp-1:0] res;
  
  bsg_adder_one_hot #(.width_p(4),.output_width_p(output_width_lp),.modulo_p(0))
  foo (.a_i(1 << ctr[1:0]), .b_i(1 << ctr[3:2]), .o(res));
  
  always @(negedge clk_lo)
    begin
      $display("%b %b -> %b\n", 1 << ctr[1:0], 1 << ctr[3:2], res);
      if (ctr == 5'b10000)
        $finish();
    end	
  
endmodule
