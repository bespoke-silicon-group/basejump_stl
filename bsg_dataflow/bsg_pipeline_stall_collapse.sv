`include "bsg_defines.sv"


// --------------------------------------------------------------------
//  count_prev(a, idx)
//  • a      : parameter or localparam int array (const-ref, no copy)
//  • idx    : element index (0-based) for which you want Σ a[0..idx-1]
//  • Returns: elaboration-time constant int
// --------------------------------------------------------------------
function automatic int count_prev
  (input int a[], input int idx, input int els);

   int result = 0;

   // for unfathomable reasons, this loop has to be reversed relative
   // to what would otherwise be expected.
   
   for (int k = els-1; k > idx; k--)
     result = result + a[k];
   
   count_prev = result;
   
endfunction // for


module bsg_pipeline_stall_collapse #(
			     `BSG_INV_PARAM(stages_p)
		             // order is a little annoying, but has to be reversed for the count_prev function to work
			     , parameter int widths_p[0:stages_p-1] = '{default: 1}
		             , `BSG_INV_PARAM(width_sum_p)
		             , parameter logic [stages_p-1:0] skip_p = '0
			     )
   (input clk_i
    ,input reset_i
    ,input valid_i
    ,output ready_and_o

    ,output valid_o
    ,input ready_and_i
    ,input  [width_sum_p-1:0] data_i
    ,output [width_sum_p-1:0] data_o
    );

//   initial
//   $display("%h %h %h %h @",widths_p[0], widths_p[1], count_prev(widths_p,0), count_prev(widths_p,1));
   
   genvar 				   i,k;

   wire [stages_p-1:0] 			   v_r_lo;
   wire [stages_p-1:0] 			   v_r_scan_lo;
   wire [stages_p:0] 			   v_li = { v_r_lo, valid_i };

   wire [stages_p-1:0] 			   ready_and_adj;
   
   bsg_scan #(.width_p(stages_p)
	      ,.and_p(1)
	      ,.lo_to_hi_p(0)) // informational only
   scan
   (.i(v_r_lo)
    ,.o(v_r_scan_lo)
    );

   always @(negedge clk_i)
     $display("v_r: %b",v_r_lo);
   
   assign valid_o = v_r_lo[stages_p-1];
   assign ready_and_o = ready_and_adj[0];

   for (i = 0; i < stages_p; i+=1)
     begin: s
	// enable register if we are shifting, or if there
	// was nothing in the register to begin with
	
	//wire ready_and_adj[i] = ready_and_i | ~v_r_lo[i];
	assign ready_and_adj[i] = ready_and_i | ~v_r_scan_lo[i];

        localparam start_lp = count_prev(widths_p,i,stages_p);	
        localparam width_lp = widths_p[i];
   
	if (skip_p[i]) 
        begin : kip
	   assign v_r_lo[i] = v_li[i];
	   assign data_o[start_lp+:width_lp] = data_i[start_lp+:width_lp];
	end
	else
	  begin : tage
	     always @(negedge clk_i)
	       $display("@i=%d shift_v=%d shift_data=%d width=%d data=%h",i,shift_v,shift_data,widths_p[i],data_o[start_lp+:width_lp]);

	     // enable if we are ready; we will either shift in
	     // a 0 if there is no data, or a 1 if there is data
	     wire shift_v = ready_and_adj[i];

	     // enable only if we are writing data into a register
	     wire shift_data = v_li[i] & ready_and_adj[i];	

	     bsg_dff_reset_en #(.width_p(1)) v_reg
	     (.clk_i(clk_i)
	      ,.reset_i(reset_i)
	      ,.en_i(shift_v)
	      ,.data_i(v_li[i])
	      ,.data_o(v_r_lo[i])
	      );

//	     always @(negedge clk_i)
//	       $display("i: %d  start_lp: %d  width: %d",i, start_lp,widths_p[i]);
	     
	     // note: if v_r_lo[i] is invalid, data is don't care
	     bsg_dff_en #(.width_p(width_lp)) d_reg
	     (.clk_i(clk_i)
	      ,.en_i   (shift_data)
	      ,.data_i (data_i[start_lp+:width_lp])
	      ,.data_o (data_o[start_lp+:width_lp])
	      );
	  end
     end

endmodule


`BSG_ABSTRACT_MODULE(bsg_pipeline_stall_collapse)

