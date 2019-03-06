// This is an integrated clock cell using a negative latch and an AND gate
// This logic may be susceptible bug if en_i changes multiple times within a clk cyle

module bsg_clkgate  (input  clk_i
                    ,input  reset_i
                    ,input  en_i
                    ,output gated_clock_o
                    );
  wire en_latch;                  
  assign en_latch = (reset_i) ?  1'b0 :
                      (~clk_i)  ?  en_i : en_latch;
  
  assign gated_clock_o = en_latch & clk_i;

endmodule

//implementation two: 
/* module bsg_clkgate  (input  clk_i
                    ,input  reset_i
                    ,input  en_i
                    ,output gated_clock_o
                    );
  wire en_latch                  
  always @ (reset_i | clk_i | en_i)
    begin
      if (reset_i)
        en_latch = 1'b0;
      else if (~clk_i)
        en_latch = en_i;
    end
  assign gated_clock_o = gated_en_o & en_latch;
endmodule

//implementation three:
module bsg_clkgate  (input en_i
                    ,input clk_i
                    ,input reset_i
                    ,output gated_clk_o
                    );
					
	wire x1, x2, Q, Q_bar;
	assign x1 = ~en_i & ~clk_i;
	assign x2 = en_i & ~clk_i;
	assign Q = ~(x1 | Q_bar);
	assign Q_bar = ~(x2 | Q);
	
	assign gated_clk_o = (reset_i) ? 1'b0 : (Q & clk_i);

endmodule*/