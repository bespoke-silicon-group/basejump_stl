
module bsg_detect_edge
 #(parameter falling_not_rising_p = 0)
  (input     clk_i

   , input   i
   , output  o
   );

  logic i_r;
  bsg_dff
   #(.width_p(1))
   i_reg
    (.clk_i(clk_i)
  
     ,.data_i(i)
     ,.data_o(i_r)
     );

   if (falling_not_rising_p == 1)
     begin : falling
        assign o = ~i &  i_r;
     end
   else
     begin : rising
        assign o =  i & ~i_r;
     end

endmodule

