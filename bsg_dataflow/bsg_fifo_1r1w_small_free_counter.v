// bsg_fifo with 1 read and 1 write, using register file
// dedicated for smaller fifos. It also provides the number of 
// free slots in the FIFO
// input handshake protocol is valid-ready and output protocol 
// is valid-yumi 
module bsg_fifo_1r1w_small_free_counter #( parameter width_p      = -1
                                         , parameter els_p        = -1
                                   
                                         //localpara
                                         , parameter ptr_width_lp = 
                                           `BSG_SAFE_CLOG2(els_p)+1
                                         )                           
    
    ( input                     clk_i
    , input                     reset_i

    , input [width_p-1:0]       data_i
    , input                     v_i
    , output                    ready_o

    , output                    v_o
    , output [width_p-1:0]      data_o
    , input                     yumi_i

    , output [ptr_width_lp-1:0] count_o
    );

// internal signals
logic enque;

// In valid-ready protocol both ends assert their signal at the 
// beginning of the cycle, and if the sender end finds that receiver
// was not ready it would send it again. So in the receiver side
// valid means enque if it could accept it
assign enque = v_i & ready_o;

// Every port is connected directly to fifo without the counter
// counter is made separately
bsg_fifo_1r1w_small #( .width_p(width_p)
                     , .els_p(els_p) 
                     ) fifo_without_counter

                     ( .clk_i(clk_i)
                     , .reset_i(reset_i)

                     , .data_i(data_i)
                     , .v_i(v_i)
                     , .ready_o(ready_o)

                     , .v_o(v_o)
                     , .data_o(data_o)
                     , .yumi_i(yumi_i)

                     );

// An up-down counter is used for counting free slots.
// it starts with number of elements in the fifo and that
// is also the max value it can reach. Counter must not
// have extra bits more than FIFO size
bsg_counter_up_down #( .max_val_p(els_p)  
                     , .init_val_p(els_p) 
                     ) free_slot_counter

    ( .clk_i(clk_i)
    , .reset_i(reset_i)

    , .up_i(yumi_i)
    , .down_i(enque)

    , .count_o(count_o)
    );

endmodule
