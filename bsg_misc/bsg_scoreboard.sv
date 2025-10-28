`include "bsg_defines.sv"

// basic scoreboard implementation
//
// order of operations:
// scoreboard_r is before any allocation or de-allocation is done
// then allocation is done, then free is done
//
// allocating and then de-allocating the same id in the same cycle
// is okay.
//
// this module separates the critical path of the alloc_yumi_o from the
// allocation critical path, and it does the casting on the shifts
// 

module bsg_scoreboard_dealloc_alloc #(`BSG_INV_PARAM(els_p))
   (input clk_i
    , input reset_i
    , output [els_p-1:0] scoreboard_r_o

    , input alloc_v_i
    , input [`BSG_SAFE_CLOG2(els_p)-1:0] alloc_id_i
    , output alloc_yumi_o
    
    , input free_v_i
    , input [`BSG_SAFE_CLOG2(els_p)-1:0] free_id_i
    );

   wire [els_p-1:0] scoreboard_r;

   assign alloc_yumi_o = alloc_v_i & ~scoreboard_r[alloc_id_i];

    bsg_dff_reset_set_clear #(.width_p(els_p)
			      ,.clear_over_set_p(1)) ids
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     // we blindly set the value, since if it is already allocated
     // we aren't over-writing anything
     ,.set_i  ((els_p ' (alloc_v_i)) << alloc_id_i)

     // in the off chance that the item was already allocated
     // and we are denied allocating it, the clear has precedence
     // over the accidental set we just did
     ,.clear_i((els_p ' (free_v_i))  << free_id_i)
     ,.data_o(scoreboard_r)
     );

   assign scoreboard_r_o = scoreboard_r;

endmodule
   
