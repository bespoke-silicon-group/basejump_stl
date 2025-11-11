`include "bsg_defines.sv"

// see testing/bsg_dataflow/bsg_pipeline_stall_collapse for example usage
//
// works in concert with bsg_dff_en_segmented to implement pipelined datapaths
// with flow control.
//
// skip_p parameter allows you to omit the pipeline register
//

module bsg_pipeline_stall_collapse #(
			     `BSG_INV_PARAM(stages_p)
		             , parameter logic [stages_p-1:0] skip_p = '0
	                     , parameter debug_p = 1'b0
			     )
   (input clk_i
    ,input reset_i
    ,input valid_i
    ,input global_stall_i
	,output ready_and_o

    ,input ready_and_i
    ,output [stages_p-1:0] en_o 
    ,output [stages_p-1:0] valid_o   // valid_o[0] is data coming out of pipeline
   );
   
   genvar 				   i,k;

   wire [stages_p-1:0] 			   v_r_lo;
   wire [stages_p-1:0] 			   v_r_scan_lo;
   wire [stages_p-1:0] 			   v_li = { valid_i, v_r_lo[stages_p-1:1] };

   wire [stages_p-1:0] 			   ready_and_adj;
   
   bsg_scan #(.width_p(stages_p)
	      ,.and_p(1)
	      ,.lo_to_hi_p(1)) // end of pipeline is at element 0
   scan
   (.i(v_r_lo)
    ,.o(v_r_scan_lo)
    );


`ifndef BSG_HIDE_FROM_SYNTHESIS   
if (debug_p)	
   always @(negedge clk_i)
     $display("v_r: %b v_r_scan_lo: %b",v_r_lo,v_r_scan_lo);
`endif
   
   assign valid_o = v_r_lo;
   assign ready_and_o = ready_and_adj[stages_p-1];
   
   for (i = 0; i < stages_p; i+=1)
     begin: s
	// enable register if we are shifting, or if there
	// was nothing in the register to begin with
	
		 assign ready_and_adj[i] = (ready_and_i | ~v_r_scan_lo[i]) & ~global_stall_i;
		
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
	 if (debug_p)		  
	     always @(negedge clk_i)
            $display("@i=%d shift_v=%d shift_data=%d global_stall=%b",i,shift_v,shift_data,global_stall_i);
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

