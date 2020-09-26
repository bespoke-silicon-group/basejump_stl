// This module is a logic analyzer with sampling frequency of
// 2 times clk. It receives synchronized samples from 
// bsg_ddr_sampler module and also chosses between the input lines
// to determine which line to store the sampled values. 
//
// start_i signal triggers the sampling and it would stop sampling
// when its fifo becomes full. Next, the start signal would be 
// de-asserted and dequing can be performed until the fifo is empty.
//
// It uses a 2 in 1 out FIFO, since during sampling each clock 2 
// values are read but the signal would be send out 1 by 1. 

`include "bsg_defines.v"

module bsg_logic_analyzer #( parameter line_width_p = "inv"
                           , parameter LA_els_p     = "inv"
                           )
              ( input clk
              , input reset
              , input valid_en_i

              , input [line_width_p-1:0]                  posedge_value_i
              , input [line_width_p-1:0]                  negedge_value_i
              , input [`BSG_SAFE_CLOG2(line_width_p)-1:0] input_bit_selector_i
              
              , input                                     start_i
              , output                                    ready_o
              
              , output                                    logic_analyzer_data_o
              , output                                    v_o
              , input                                     deque_i

              );

// keeping state of enque
logic enque, enque_r;

always_ff @ (posedge clk)
  if (reset)
    enque_r <= 0;
  else
    enque_r <= enque;

// Enque starts by start_i signal and remains high until deque signal
// is asserted. It is assumed that start_i would not be asserted 
// while dequing due to logic analyzer behavior. When first deque 
// signal is asserted it will stop enquing. Since fifo uses a
// valid_and_read protocol, in case of fifo becoming full it would stop
// enqueing until deque is asserted, and as stated there would be no 
// more enquing on that time.
assign enque = (start_i | enque_r) & ready_o; 

// Select one bit of input signal for Logic Analyzer
// LSB is posedge and MSB is negedge
logic [1:0] LA_selected_line;
assign LA_selected_line[0] = posedge_value_i[input_bit_selector_i];
assign LA_selected_line[1] = negedge_value_i[input_bit_selector_i];


// Masking the valid bit
logic valid;
assign v_o = valid & valid_en_i;

// The protocol is ready_THEN_valid since we are checking the ready_o
// signal for generating the enque signal.
bsg_fifo_1r1w_narrowed 
            #( .width_p(2)
             , .els_p(LA_els_p)
             , .width_out_p(1)

             , .lsb_to_msb_p(1)     
             , .ready_THEN_valid_p(1)
             ) narrowed_fifo

             ( .clk_i(clk)
             , .reset_i(reset)
         
             , .data_i(LA_selected_line)
             , .v_i(enque)
             , .ready_o(ready_o)
         
             , .v_o(valid)
             , .data_o(logic_analyzer_data_o)
             , .yumi_i(deque_i)
         
             );

endmodule
