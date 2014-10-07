// MBT 7/24/2014
//
// This is a launch/synchronization complex.
// The launch flop prevents combinational glitching.
// The two sync flops reduce probability of metastability.
// See MBT's note on async design and CDC.
//
// The three flops should be don't touched in synopsys
// and abutted in physical design to reduce chances of metastability.
//
// Use of reset is optional; it can be used to hold a known value during reset
// if for instance, the value is coming off chip.
//

module bsg_launch_sync_sync #(parameter width_p="inv"
			      , parameter use_negedge_for_launch_p = 0)
   (input iclk_i
    , input iclk_reset_i
    , input oclk_i
    , input  [width_p-1:0] iclk_data_i
    , output [width_p-1:0] iclk_data_o // after launch flop
    , output [width_p-1:0] oclk_data_o // after sync flops
    );

   logic [width_p-1:0] bsg_launch_flop_r;

   assign iclk_data_o = bsg_launch_flop_r;

   // fixme can we factor this better?
generate
   if (use_negedge_for_launch_p)
     always @(negedge iclk_i)
       begin
	  if (iclk_reset_i)
	    bsg_launch_flop_r <= { width_p {1'b0} };
	  else
	    bsg_launch_flop_r <= iclk_data_i;
       end
   else
     always @(posedge iclk_i)
       begin
	  if (iclk_reset_i)
	    bsg_launch_flop_r <= { width_p {1'b0} };
	  else
	    bsg_launch_flop_r <= iclk_data_i;
       end
endgenerate

   bsg_sync_sync #(.width_p(width_p)) bss
     (.oclk_i(oclk_i)
      ,.iclk_data_i(bsg_launch_flop_r)
      ,.oclk_data_o(oclk_data_o)
      );

endmodule
