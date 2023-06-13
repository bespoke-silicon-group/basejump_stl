module test();
  
  parameter input_width_lp  = 4;
  parameter output_width_lp = 3;

  wire [input_width_lp-1:0]  a = 4'b1110;
  wire [input_width_lp-1:0]  b = 4'b0001;
  
  wire [output_width_lp-1:0] p_lo, g_lo;
  
  bsg_pg_tree #(.input_width_p  (input_width_lp)
                ,.output_width_p(output_width_lp)
                ,.nodes_p (3)
                ,.l_edge_p   ({0,2,6})
                ,.r_edge_p   ({1,3,7})
                ,.o_edge_p   ({6,7,8})
                ,.node_type_p({0,0,0})
                ,.row_p      ({0,0,1})
               ) bpc
  (.p_i (a | b)
   ,.g_i(a & b)
   ,.p_o(p_lo)
   ,.g_o(g_lo)
  );
  
  initial 
    begin
      #20;
      $display("%b %b p=%b g=%b",a,b,p_lo,g_lo);
    end	
endmodule
