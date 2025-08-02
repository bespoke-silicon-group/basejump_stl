module dut (input clk_i
	    ,input reset_i
	    ,input v_i
	    ,output ready_and_o
	    ,input [1:0][31:0] data_i

	    ,output v_o
	    ,output [15:0] data_o
	    ,input ready_and_i
	    );

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

   // this is very irritating, but must be declared ascending, otherwise the count_prev
   // function does not work correctly.
   parameter int widths_p [0:2] = ' { int ' ($bits (stage_li.s1)),       // 0
                                      int ' ($bits (stage_li.s2)),       // 1
		                      int ' ($bits (stage_li.s3)) };     // 2

   initial
     begin
	$display("widths: %p widths[0] %h",widths_p,widths_p[0]);
     end
   
   
   bsg_pipeline_stall_collapse #(.stages_p(3)
				 ,.width_sum_p( $bits (pipeline_s))
				 ,.widths_p(widths_p)
				 ) pipe
     (.clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.valid_i(v_i)
      ,.data_i(stage_li)
      ,.ready_and_o(ready_and_o)

      ,.valid_o(v_o)
      ,.data_o(stage_lo)
      ,.ready_and_i(ready_and_i)
      );

   assign stage_li.s1.a = data_i[0];
   assign stage_li.s1.b = data_i[1];				 
   assign stage_li.s2.c = 32 ' (stage_lo.s1.a * stage_lo.s1.b);
   assign stage_li.s3.d = stage_lo.s2.c[31:16] + stage_lo.s2.c[15:0];

   assign data_o = stage_lo.s3.d;
   
endmodule
