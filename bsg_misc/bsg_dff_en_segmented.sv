`include "bsg_defines.sv"

// this is a segmented DFF, it allows you to pass in a parameter array
// of widths and then it generates the DFF's accordingly. to get around
// synthesis issues, we take a tail recursive approach.

module bsg_dff_en_segmented #(`BSG_INV_PARAM(els_p)
			      ,parameter int widths_p[els_p-1:0] = '{default: 1}
			      ,`BSG_INV_PARAM(width_sum_p)
			      )
   (
    input clk_i
    ,input [width_sum_p-1:0] data_i
    ,input [els_p-1:0] en_i
    ,output logic [width_sum_p-1:0] data_o
    );

   localparam local_width_p = widths_p[0];

   bsg_dff_en #(.width_p(local_width_p)) dff
     (.clk_i(clk_i)
      ,.data_i(data_i[local_width_p-1:0])
      ,.en_i(en_i[0])
      ,.data_o(data_o[local_width_p-1:0])
      );

   if (els_p > 1)
     begin
	localparam rem_width_p = width_sum_p-local_width_p;
   
	bsg_dff_en_segmented #(.els_p(els_p-1)
			       ,.widths_p(widths_p[els_p-1:1])
			       ,.width_sum_p(rem_width_p)
			       ) r
	  (.clk_i  (clk_i)
	   ,.data_i(data_i[width_sum_p-1:local_width_p])
	   ,.en_i  (en_i[els_p-1:1])
	   ,.data_o(data_o[width_sum_p-1:local_width_p])
	   );
     end

`ifndef BSG_HIDE_FROM_SYNTHESIS
   always @(negedge clk_i)
     $display("i=%d widths=%p width=%d en=%b %h->%h",els_p,widths_p,local_width_p,en_i[0],data_i[local_width_p-1:0],data_o[local_width_p-1:0]);
`endif
   
endmodule

`BSG_ABSTRACT_MODULE(bsg_dff_en_segmented)
