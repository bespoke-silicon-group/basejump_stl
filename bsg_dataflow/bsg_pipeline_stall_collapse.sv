`include "bsg_defines.sv"

module bsg_pipeline_stall_collapse #(
			     `BSG_INV_PARAM(stages_p)
			     , parameter int widths_p[stages_p-1:0] = '{default: 1}
			     , parameter int max_width_p = widths_p.max()
		             , parameter logic [stages_p-1:0] skip_p = '0
			     )
   (input clk_i
    ,input reset_i
    ,input valid_i
    ,output ready_and_o

    ,output valid_o
    ,input ready_and_i
    ,input  [stages_p-1:0][max_width_p-1:0] data_i
    ,output [stages_p-1:0][max_width_p-1:0] data_o
    );

   genvar 				   i;

   wire [stages_p-1:0] 			   v_r_lo;
   wire [stages_p-1:0] 			   v_r_scan_lo;
   wire [stages_p:0] 			   v_li = { v_r_lo, valid_i };

   wire [stages_p-1:0] 			   ready_and_adj;
   
   bsg_scan #(.width_p(stages_p)
	      ,.and_p(1)
	      ,.lo_to_hi_p(0)) // informational only
   (.i(v_r_lo)
    ,.o(v_r_scan_lo)
    );
   
   assign valid_o = v_r_lo[stages_p-1];
   assign ready_and_o = ready_and_adj[0];
   
   for (i = 0; i < stages_p; i++)
     begin: s
	// enable register if we are shifting, or if there
	// was nothing in the register to begin with
	
	//wire ready_and_adj[i] = ready_and_i | ~v_r_lo[i];
	assign ready_and_adj[i] = ready_and_i | ~v_r_scan_lo[i];

	// enable if we are ready; we will either shift in
	// a 0 if there is no data, or a 1 if there is data
	wire shift_v = ready_and_adj[i];

	// enable only if we are writing data into a register
	wire shift_data = v_li[i] & ready_and_adj[i];	

	if (skip_p[i]) 
        begin : kip
	   assign v_r_lo[i] = v_li[i];
	   assign data_o[i] = data_i[i];
	end
	else
	  begin : tage
	     bsg_dff_reset_en #(.width_p(1))
	     (.clk_i(clk_i)
	      ,.reset_i(reset_i)
	      ,.en_i(shift_v)
	      ,.data_i(v_li[i])
	      ,.data_o(v_r_lo[i])
	      );
		  
	     // note: if v_r_lo[i] is invalid, data is don't care
	     bsg_dff_en #(.width_p(widths_p[i]))
	     (.clk_i(clk_i)
	      ,.reset_i(reset_i)

	      ,.en_i   (shift_data)
	      ,.data_i (data_i[i][widths_p[i]-1:0])
	      ,.data_o (data_o[i][widths_p[i]-1:0])
	      );
	  end
     end

endmodule


`BSG_ABSTRACT_MODULE(bsg_pipeline_stall_collapse)

