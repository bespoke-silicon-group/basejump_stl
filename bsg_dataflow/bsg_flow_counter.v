// bsg_flow_counter, would be attached to a module or set of
// modules which have ready-and-valid or ready-then-valid
// (base on the ready_THEN_valid_p parameter) input protocol
// and valid-then-yumi protocol for the output. Based on the 
// count_free_p it will count the number of free elements or
// number of existing elements in the connected module.

`include "bsg_defines.v"

module bsg_flow_counter #(parameter els_p              = -1
                        , parameter count_free_p       = 0
                        , parameter ready_THEN_valid_p = 0
                        
                        //localpara
                        , parameter ptr_width_lp = 
                          `BSG_WIDTH(els_p)
                         )                           
    
    ( input                     clk_i
    , input                     reset_i

    , input                     v_i
    , input                     ready_i
    , input                     yumi_i

    , output [ptr_width_lp-1:0] count_o
    );

// internal signals
logic enque;

// In valid-ready protocol both ends assert their signal at the 
// beginning of the cycle, and if the sender end finds that receiver
// was not ready it would send it again. So in the receiver side
// valid means enque if it could accept it
if (ready_THEN_valid_p) begin: gen_blk_protocol_select
  assign enque = v_i;
end else begin: gen_blk_protocol_select
  assign enque = v_i & ready_i;
end

generate
  if (count_free_p) begin: gen_blk_0
    // An up-down counter is used for counting free slots.
    // it starts with number of elements and that is also 
    // the max value it can reach. 
    bsg_counter_up_down #( .max_val_p(els_p)  
                         , .init_val_p(els_p) 
                         , .max_step_p(1)
                         ) counter
    
        ( .clk_i(clk_i)
        , .reset_i(reset_i)
    
        , .up_i(yumi_i)
        , .down_i(enque)
    
        , .count_o(count_o)
        );
   end else begin: gen_blk_0
    bsg_counter_up_down #( .max_val_p(els_p)  
                         , .init_val_p(0) 
                         , .max_step_p(1)
                         ) counter
    
        ( .clk_i(clk_i)
        , .reset_i(reset_i)
    
        , .up_i(enque)
        , .down_i(yumi_i)
    
        , .count_o(count_o)
        );
  end
endgenerate

endmodule
