`include "bsg_defines.sv"

// this is a segmented DFF, it allows you to pass in a parameter array
// of widths and then it generates the DFF's accordingly. to get around
// synthesis issues, we take a tail recursive approach.

// it also takes a parameter skip, which says to omit the register

module bsg_dff_en_segmented #(`BSG_INV_PARAM(els_p)
			      ,parameter int widths_p[els_p-1:0] // = '{default: 1}
			      ,parameter int bit_index_p = 0
			      ,`BSG_INV_PARAM(width_sum_p)
			      ,parameter [els_p-1:0] skip_p = '0
			      )
   (
    input clk_i
    ,input [width_sum_p-1:0] data_i
    ,input [els_p-1:0] en_i
    ,output logic [width_sum_p-1:0] data_o
    );

   localparam local_width_p = widths_p[bit_index_p];

   if (skip_p[bit_index_p])
     begin: skip
	assign data_o[local_width_p-1:0] = data_i[local_width_p-1:0];
     end
   else
     begin: r
	bsg_dff_en #(.width_p(local_width_p)) dff
	  (.clk_i(clk_i)
	   ,.data_i(data_i[local_width_p-1:0])
	   ,.en_i(en_i[bit_index_p])
	   ,.data_o(data_o[local_width_p-1:0])
	   );
     end

   if (bit_index_p+1 < els_p)
     begin
	localparam rem_width_p = width_sum_p-local_width_p;
//	localparam int out_width_p[els_p-2:0] = widths_p[els_p-1:1];
	
	bsg_dff_en_segmented #(.els_p(els_p)
			       ,.widths_p(widths_p)
			       ,.width_sum_p(rem_width_p)
			       ,.bit_index_p(bit_index_p+1)
			       ,.skip_p(skip_p)
			       ) r
	  (.clk_i  (clk_i)
	   ,.data_i(data_i[width_sum_p-1:local_width_p])
	   ,.en_i  (en_i)
	   ,.data_o(data_o[width_sum_p-1:local_width_p])
	   );
     end

`ifndef BSG_HIDE_FROM_SYNTHESIS
if (0)
  always @(negedge clk_i)
     $display("i=%d widths=%p width=%d en=%b %h->%h",els_p,widths_p,local_width_p,en_i[0],data_i[local_width_p-1:0],data_o[local_width_p-1:0]);
`endif
   
endmodule

`BSG_ABSTRACT_MODULE(bsg_dff_en_segmented)
