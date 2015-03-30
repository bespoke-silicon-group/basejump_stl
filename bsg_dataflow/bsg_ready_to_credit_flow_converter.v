// This module converts between the valid-ready (input) and 
// valid-credit (output) handshakes, by keeping the count of 
// available credits
module bsg_ready_to_credit_flow_converter #( parameter credit_initial_p = -1
                                          , parameter credit_max_val_p = -1
                                       
                                          //local parameter 
                                          , parameter ptr_width_lp = 
                                              `BSG_SAFE_CLOG2(credit_max_val_p)+1
                                          )                           
                            
    ( input  clk_i
    , input  reset_i

    , input  v_i
    , output ready_o

    , output v_o
    , input  credit_i

    );
    
// credit_counter signal
logic [ptr_width_lp-1:0] credit_cnt;

// conversion between valid-credit and valid-credit protocols
// in case of reset, credit_cnt is not zero, so the ready
// and valid signals
assign ready_o = (credit_cnt!=0);
assign v_o     = v_i & ready_o;

// counter for credits. When each data is sent it goes down
// by 1 and when it receives a credit acknowledge it goes 
// up. If other side of handshake has more buffer it can
// send some credit acknowledges at first to raise the limit
bsg_counter_up_down #( .max_val_p(credit_max_val_p)  
                     , .init_val_p(credit_initial_p) 
                     ) credit_counter

    ( .clk_i(clk_i)
    , .reset_i(reset_i)

    , .up_i(credit_i)
    , .down_i(v_o)

    , .count_o(credit_cnt)
    );

endmodule 
