`include "bsg_defines.sv"

// basic scoreboard implementation
//
// order of operations:
// scoreboard_r is before any allocation or de-allocation is done
// then allocation is done, then free is done
//
// allocating and then de-allocating the same id in the same cycle
// is okay.

module bsg_scoreboard_dealloc_alloc #(`BSG_INV_PARAM(els_p))
   (input clk_i
    , input reset_i
    , output [els_p-1:0] scoreboard_r_o

    , input [`BSG_SAFE_CLOG2(els_p)-1:0] alloc_id_i
    , output alloc_v_o
	, input alloc_yumi_i
    
    , input free_v_i
    , input [`BSG_SAFE_CLOG2(els_p)-1:0] free_id_i
    );

   wire [els_p-1:0] scoreboard_r;

   assign alloc_v_o = ~scoreboard_r[alloc_id_i];

    bsg_dff_reset_set_clear #(.width_p(els_p)
			      ,.clear_over_set_p(1)) ids
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

	 ,.set_i  ((els_p ' (alloc_yumi_i)) << alloc_id_i)

     ,.clear_i((els_p ' (free_v_i))  << free_id_i)
     ,.data_o(scoreboard_r)
     );

   assign scoreboard_r_o = scoreboard_r;

endmodule
   
