`include "bsg_defines.sv"


module bsg_pipeline_stall_collapse #(
			     `BSG_INV_PARAM(stages_p)
		             , parameter logic [stages_p-1:0] skip_p = '0
			     )
   (input clk_i
    ,input reset_i
    ,input valid_i
    ,output ready_and_o

    ,output valid_o
    ,input ready_and_i
    ,output [stages_p-1:0] en_o 
    );
   
   genvar 				   i,k;

   wire [stages_p-1:0] 			   v_r_lo;
   wire [stages_p-1:0] 			   v_r_scan_lo;
   wire [stages_p:0] 			   v_li = { valid_i, v_r_lo[stages_p-1:1] };

   wire [stages_p-1:0] 			   ready_and_adj;
   
   bsg_scan #(.width_p(stages_p)
	      ,.and_p(1)
	      ,.lo_to_hi_p(1)) // end of pipeline is at element 0
   scan
   (.i(v_r_lo)
    ,.o(v_r_scan_lo)
    );


`ifndef BSG_HIDE_FROM_SYNTHESIS   
   always @(negedge clk_i)
     $display("v_r: %b v_r_scan_lo: %b",v_r_lo,v_r_scan_lo);
`endif
   
   assign valid_o = v_r_lo[0];
   assign ready_and_o = ready_and_adj[stages_p-1];
   
   for (i = 0; i < stages_p; i+=1)
     begin: s
	// enable register if we are shifting, or if there
	// was nothing in the register to begin with
	
	assign ready_and_adj[i] = ready_and_i | ~v_r_scan_lo[i];
		
	if (skip_p[i]) 
        begin : kip
	   assign v_r_lo[i] = v_li[i];
	end
	else
	  begin : tage
	     // enable if we are ready; we will either shift in
	     // a 0 if there is no data, or a 1 if there is data
	     wire shift_v = ready_and_adj[i];

	     // enable only if we are writing data into a register
	     wire shift_data = v_li[i] & ready_and_adj[i];	

`ifndef BSG_HIDE_FROM_SYNTHESIS   	     
	     always @(negedge clk_i)
	       $display("@i=%d shift_v=%d shift_data=%d",i,shift_v,shift_data);
`endif
	     bsg_dff_reset_en #(.width_p(1)) v_reg
	     (.clk_i(clk_i)
	      ,.reset_i(reset_i)
	      ,.en_i(shift_v)
	      ,.data_i(v_li[i])
	      ,.data_o(v_r_lo[i])
	      );

             assign en_o[i] = shift_data;
	  end
     end

endmodule


`BSG_ABSTRACT_MODULE(bsg_pipeline_stall_collapse)

