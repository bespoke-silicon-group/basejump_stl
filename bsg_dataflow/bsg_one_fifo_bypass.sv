`include "bsg_defines.sv"

// bsg_one_fifo_bypass
//
// bypassing version of bsg_one_fifo
//
// the module will start out by bypassing incoming data to the output.
// should yumi_i=0, it will store an element internally and present it on the
// interface. thus there are only so many bubbles as there are yumi_i=0 cycles,
// which matches a bsg_two_fifo.
//
// the purpose of this module is different from bsg_one_fifo in that it does not
// break combinational paths from data_i/v_i to data_o/v_o (it does break the back pressure path)
//
// one primary use is to provide isolation from modules that have non-locking round robin
// interfaces like bsg_round_robin_n_to_1.sv, where the data_o may change if there is no
// yumi_i on a given cycle.
//
// (aside: in theory this module could be used to create a collapsing multi-element FIFO
// although this has not been tested or validated as useful.)

module bsg_one_fifo_bypass #(parameter `BSG_INV_PARAM(width_p)
                      )
   (input clk_i
    , input reset_i

    // input side
    , output              ready_and_o // early
    , input [width_p-1:0] data_i      // late
    , input               v_i         // early or late

    // output side
    , output              v_o         // early if v_i is early, otherwise late
    , output[width_p-1:0] data_o      // early if data_o is early, otherwise late 
    , input               yumi_i      // late
    );
  
  logic             full_r;

  // we only guarantee to accept the data
  // if we are not full
  assign ready_and_o = ~full_r;
  assign v_o     =  full_r | v_i;
  
  bsg_dff_reset #(.width_p(1)) dff_full
  (.clk_i
   ,.reset_i
   ,.data_i(v_o & ~yumi_i)
   ,.data_o(full_r)
  );

  logic [width_p-1:0] data_lo;
  
  bsg_dff_en #(.width_p(width_p), .harden_p(0)) dff
  (.clk_i
   ,.data_i
   // latch data only if the register is empty
   // new data is coming in and we are not bypassing it
   ,.en_i(v_i & ~full_r & ~yumi_i)
   ,.data_o(data_lo)
  );

  assign data_o = full_r ? data_lo: data_i;
  
endmodule

`BSG_ABSTRACT_MODULE(bsg_one_fifo_bypass)
