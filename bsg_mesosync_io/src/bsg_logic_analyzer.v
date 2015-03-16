// Logic analyzer is a 2bit in 1bit out FIFO that latches the inputs
// beforehand, since two inputs are actually sampled on different clock
// edges. It takes "number of elements in FIFO" to be filled and twice
// to be emptied. 

module bsg_logic_analyzer 
                  #(parameter LA_els_p = -1
                   )
                   (  input clk
                    , input reset
                   
                    , input enque_i
                    
                    , input [1:0] data_i
                    , input deque_i

                    , output data_o
                    , output valid_o
                    );

  // Synchronizer for samples from both edges
  logic [1:0] synchronizer_out;
  always_ff @  (posedge clk)
    synchronizer_out <= data_i;
  
  // Internal signals
  logic LA_enque, ready, deque;
  logic [1:0] data;

  // If enque is enabled, it will enque until its full
  assign LA_enque = ~reset & enque_i & ready;

  bsg_fifo_1r1w_small #(.width_p(2)
                       ,.els_p(LA_els_p) 
                       ) LA_fifo
    
    ( .clk_i(clk)
    , .reset_i(reset)

    , .data_i(synchronizer_out)
    , .v_i(LA_enque)
    , .ready_o(ready)

    , .v_o(valid_o)
    , .data_o(data)
    , .yumi_i(deque)
    );


  /*
  // for testing with the count of free slots
  logic [$clog2(LA_els_p):0] count;
  bsg_fifo_1r1w_small_free_counter #(.width_p(2)
                                    ,.els_p(LA_els_p) 
                                    ) LA_fifo
    
    ( .clk_i(clk)
    , .reset_i(reset)

    , .data_i(synchronizer_out)
    , .v_i(LA_enque)
    , .ready_o(ready)

    , .v_o(valid_o)
    , .data_o(data)
    , .yumi_i(deque)

    , .count_o(count)
    );
  */

  // selecting from two FIFO outputs and sending one out at a time
  bsg_output_selector #( .width_in_p(2)
                       , .width_out_p(1)
                       , .lsb_to_msb_p(1)
                       ) LA_out_bit_selector
       ( .clk(clk)
       , .reset(reset)
  
       , .data_i(data)
       , .deque_o(deque)
  
       , .data_o(data_o)
       , .deque_i(deque_i)
       
       );
  
endmodule
