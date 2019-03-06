// This is an integrated clock cell using a negative latch and an AND gate
// This logic may be susceptible bug if en_i changes multiple times within a clk cyle

module bsg_clkgate_optional  (input  clk_i
                             ,input  en_i
                             ,input  bypass_i
                             ,output gated_clock_o
                             );
  
  CGLPPSX2 cg (.SE(bypass_i)
              ,.EN(en_i)
              ,.CLK(clk_i)
              ,.GCLK(gated_clock_o));

endmodule

