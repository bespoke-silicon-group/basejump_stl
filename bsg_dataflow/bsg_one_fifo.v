// one element fifo
//
// use to pipeline links and convert interfaces
// from valid/ready to valid->yumi.
// (similar circumstances to bsg_two_fifo)
//
// This fifo can do at most
// 1 word/per 2 cycles bandwidth
// even at the shortest time scales.
//
// However, in some scenarios
// you know that you will not be pushing data
// through the FIFO at that rate, so you can
// save area by using this module.
//

`include "bsg_defines.v"

module bsg_one_fifo #(parameter width_p="inv"
                      )
   (input clk_i
    , input reset_i

    // input side
    , output              ready_o // early
    , input [width_p-1:0] data_i  // late
    , input               v_i     // late

    // output side
    , output              v_o     // early
    , output[width_p-1:0] data_o  // early
    , input               yumi_i  // late
    );
  
  logic             full_r;
  
  assign ready_o = ~full_r;
  assign v_o     =  full_r;
  
  bsg_dff_reset #(.width_p(1)) dff_full
  (.clk_i
   ,.reset_i
   ,.data_i(full_r ? ~yumi_i: v_i)
   ,.data_o(full_r)
  );
  
  bsg_dff_en #(.width_p(width_p), .harden_p(0)) dff
  (.clk_i
   ,.data_i
   // although technically it is okay to just look at v_o
   // this will cause unnecessary toggling of flip flops
   ,.en_i(v_i & ready_o)
   ,.data_o
  );

endmodule
