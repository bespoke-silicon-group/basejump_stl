`include "definitions.v"

module bsg_logic_analyzer 
                  #(parameter log_LA_fifo_depth_p = 9
                   )
                   (  input clk
                    , input reset
                   
                    , input [1:0] data_i
                    , input start_i
                    , input deque_i

                    , output data_o
                    , output empty_o
                    , output full_o
                    , output valid_o
                    );

// Synchronizer for samples from both edges
logic [1:0] synchronizer_out;
always_ff @  (posedge clk)
  synchronizer_out <= data_i;

logic LA_enque;
// After start signal is asserted it will enque until its full
assign LA_enque = ~reset & start_i & ~full_o;

// Logic Analyzer FIFO
two_in_one_out_fifo #(.LG_DEPTH(log_LA_fifo_depth_p)
                      ) LA_fifo
  (.clk(clk)
   ,.din(synchronizer_out)
   ,.enque(LA_enque)
   ,.deque(deque_i)	
   ,.clear(reset)
   ,.dout(data_o)
   ,.empty(empty_o)
   ,.full(full_o)
   ,.valid(valid_o)
   );


endmodule
