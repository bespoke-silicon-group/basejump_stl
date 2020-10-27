// this is intended for round robining
// on the input to a pair of fifos.

`include "bsg_defines.v"

module bsg_round_robin_2_to_2 #(parameter width_p = -1
				)
   (input clk_i
    , input reset_i
    , input [width_p*2-1:0] data_i
    , input [1:0] v_i
    , output [1:0] ready_o

    , output [width_p*2-1:0] data_o
    , output [1:0] v_o
    , input [1:0] ready_i
    );

   logic head_r;

   always_ff @(posedge clk_i)
     if (reset_i)
       head_r <= 0;
     else
       // or ^ {head_r, v_o & ready_i};
       head_r <= ^ {head_r, v_i & ready_o};

   assign data_o  = head_r ? { data_i[0+:width_p], data_i[width_p+:width_p] } : data_i;
   assign v_o = head_r ? { v_i[0], v_i[1] } : v_i;
   assign ready_o = head_r ? { ready_i[0], ready_i[1] } : ready_i;

endmodule // bsg_round_robin_2_to_2

