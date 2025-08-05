module dut (input clk_i
	    ,input reset_i
	    ,input v_i
	    ,output ready_and_o
	    ,input [1:0][31:0] data_i

	    ,output v_o
	    ,output [15:0] data_o
	    ,input ready_and_i
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
   

   // you can tweak level of pipelining by specify which pipeline stages you want to skip registers
   
   parameter stage_skip_p = '0;

   pipeline_s stage_li, stage_lo;


   // keep in mind that the human readable order above means that the bits
   // in the struct are actually stored with last stage in low bits
   // and first stage in high bits.

   parameter int widths_p [2:0] = { int ' ($bits (stage_li.s1)),       // 2
                                      int ' ($bits (stage_li.s2)),       // 1
		                      int ' ($bits (stage_li.s3)) };     // 0

`ifndef BSG_HIDE_FROM_SYNTHESIS
   initial
     begin
	$display("widths: %p widths[0] %h",widths_p,widths_p[0]);
     end
`endif   

   wire [2:0] en_lo;
   
   bsg_pipeline_stall_collapse #(.stages_p(3)
				 ,.skip_p(stage_skip_p)
				 ) pipe_ctl
     (.clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.valid_i(v_i)
      ,.ready_and_o(ready_and_o)

      ,.valid_o(v_o)
      ,.ready_and_i(ready_and_i)

      // control lines to segmented dff
      ,.en_o(en_lo)
      );

   bsg_dff_en_segmented #(.els_p(3)
			  ,.widths_p(widths_p)
			  ,.width_sum_p($bits (pipeline_s))
			  ,.skip_p(stage_skip_p)
			  ) pipe_data
     (.clk_i(clk_i)
      ,.en_i(en_lo)
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
