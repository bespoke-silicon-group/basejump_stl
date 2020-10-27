// This module works as an extender accross the chip. It
// has valid/ready protocol on both sides. 

`include "bsg_defines.v"

module bsg_relay_fifo #(parameter width_p="inv")
    ( input clk_i
    , input reset_i

    // input side
    , output              ready_o 
    , input [width_p-1:0] data_i 
    , input               v_i     

    // output side
    , output              v_o   
    , output[width_p-1:0] data_o
    , input               ready_i 
    );

logic yumi;

assign yumi = ready_i & v_o;

bsg_two_fifo #(.width_p(width_p)) two_fifo
    ( .clk_i(clk_i)
    , .reset_i(reset_i)

    // input side
    , .ready_o(ready_o)
    , .data_i(data_i)
    , .v_i(v_i)    

    // output side
    , .v_o(v_o)
    , .data_o(data_o) 
    , .yumi_i(yumi)
    );

endmodule
