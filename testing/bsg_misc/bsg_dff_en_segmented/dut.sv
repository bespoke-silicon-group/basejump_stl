module dut (input clk_i
	    ,input reset_i
	    ,input v_i
	    ,input [1:0][31:0] data_i

	    ,output v_o
	    ,output [15:0] data_o
	    );

   // design your datapath by specifying a structure which contains the intermediate
   // registers.
   
   typedef struct packed {
      struct 	  packed {
                          logic [31:0] a;
                          logic [31:0] b;
                         } s1;
      struct 	 packed {
                          logic [31:0] c;
                        } s2;
      struct     packed {
                          logic [15:0] d;
                        } s3;
   } pipeline_s;
   
   pipeline_s stage_li, stage_lo;
   
   parameter int widths_p [2:0] = { int ' ($bits (stage_li.s1)),       // 2
                                    int ' ($bits (stage_li.s2)), // 1
		                    int ' ($bits (stage_li.s3)) };     // 0

`ifndef BSG_HIDE_FROM_SYNTHESIS
   initial
     begin
	$display("widths: %p widths[0] %h",widths_p,widths_p[0]);
     end
`endif   

   bsg_dff_en_segmented #(.els_p(3)
			 ,.widths_p(widths_p)
			 ,.width_sum_p($bits(pipeline_s))
			 ) pipe
     (.clk_i(clk_i)

      // note that stage 1 is at the top of the struct, so the valid bit has to be
      // at the top as well!

      ,.en_i({ v_i, 2'b11})
      ,.data_i(stage_li)
      ,.data_o(stage_lo)
      );

   // left hand side should all be stage_li, right hand side should all be stage_lo
   assign stage_li.s1.a = data_i[0];
   assign stage_li.s1.b = data_i[1];				 
   assign stage_li.s2.c = 32 ' (stage_lo.s1.a * stage_lo.s1.b);
   assign stage_li.s3.d = stage_lo.s2.c[31:16] + stage_lo.s2.c[15:0];

   assign data_o = stage_lo.s3.d;
   
endmodule
