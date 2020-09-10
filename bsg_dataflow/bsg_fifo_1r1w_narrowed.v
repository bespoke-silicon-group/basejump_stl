// This module is a small fifo which has a bsg_channel_narrow
// on its output, that would send out each data in several steps
// based on the input and output width. width_p is the FIFO data
// width and width_out_p is the output width. els_p is the number
// of elements in fifo and lsb_to_msb_p determined the directions
// of sending the data. ready_THEN_valid_p determined input
// handshake protocol.

`include "bsg_defines.v"

module bsg_fifo_1r1w_narrowed 
                   #( parameter width_p            = -1
                    , parameter els_p              = -1 
                    , parameter width_out_p        = -1

                    , parameter lsb_to_msb_p       = 1
                    , parameter ready_THEN_valid_p = 0
                    )
                    ( input                    clk_i
                    , input                    reset_i
                
                    , input [width_p-1:0]      data_i
                    , input                    v_i
                    , output                   ready_o
                
                    , output                   v_o
                    , output [width_out_p-1:0] data_o
                    , input                    yumi_i
                
                    );

  // Internal signals
  logic [width_p-1:0] data;
  logic               yumi;


  // FIFO of els_p elements of width width_p
  bsg_fifo_1r1w_small #(.width_p(width_p)
                       ,.els_p(els_p) 
                       ,.ready_THEN_valid_p(ready_THEN_valid_p)
                       ) main_fifo
    
    ( .clk_i(clk_i)
    , .reset_i(reset_i)

    , .data_i(data_i)
    , .v_i(v_i)
    , .ready_o(ready_o)

    , .v_o(v_o)
    , .data_o(data)
    , .yumi_i(yumi)
    );


  // selecting from two FIFO outputs and sending one out at a time
  bsg_channel_narrow #( .width_in_p(width_p)
                      , .width_out_p(width_out_p)
                      , .lsb_to_msb_p(lsb_to_msb_p)
                      ) output_narrower
       ( .clk_i(clk_i)
       , .reset_i(reset_i)
  
       , .data_i(data)
       , .deque_o(yumi)
  
       , .data_o(data_o)
       , .deque_i(yumi_i)
       
       );
  
endmodule
