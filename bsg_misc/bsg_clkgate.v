// This is an integrated clock cell using a negative latch and an AND gate
// This logic may be susceptible bug if en_i changes multiple times within a clk cyle

module bsg_clkgate  (input  clk_i
                    ,input  en_i
                    ,output gated_clock_o
                    );
  //wire en_latch;                  
  //assign en_latch = (reset_i) ?  1'b0 :
  //                    (~clk_i)  ?  en_i : en_latch;

  wire latched_en_lo;

  bsg_dlatch #(.width_p(1) )
    en_latch
      ( .en_i   ( ~clk_i )
      , .data_i ( en_i )
      , .data_o ( latched_en_lo  )
      );
  
  assign gated_clock_o = latched_en_lo & clk_i;

endmodule

