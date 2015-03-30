// This module is a logic analyzer with sampling frequency of
// 2 times clk. It receives synchronized samples from 
// bsg_ddr_sampler module and also chosses between the input lines
// to determine which line to store the sampled values. 
//
// It uses a 2 in 1 out FIFO, since during sampling each clock 2 
// values are read but the signal would be send out 1 by 1. 

module bsg_logic_analyzer #( parameter line_width_p = -1
                           , parameter LA_els_p     = -1 
                           )
              ( input clk
              , input reset

              , input [line_width_p-1:0]         posedge_value_i
              , input [line_width_p-1:0]         negedge_value_i
              , input [$clog2(line_width_p)-1:0] input_bit_selector_i
              
              , input                            enque_i
              , output                           ready_o
              
              , output                           logic_analyzer_data_o
              , output                           v_o
              , input                            deque_i

              );



// Select one bit of input signal for Logic Analyzer
// LSB is posedge and MSB is negedge
logic [1:0] LA_selected_line;
assign LA_selected_line[0] = posedge_value_i[input_bit_selector_i];
assign LA_selected_line[1] = negedge_value_i[input_bit_selector_i];

bsg_fifo_1r1w_narrowed 
            #( .width_p(2)
             , .els_p(LA_els_p)
             , .width_out_p(1)

             , .lsb_to_msb_p(1)     
             , .ready_THEN_valid_p(0)
             ) narrowed_fifo

             ( .clk_i(clk)
             , .reset_i(reset)
         
             , .data_i(LA_selected_line)
             , .v_i(enque_i)
             , .ready_o(ready_o)
         
             , .v_o(v_o)
             , .data_o(logic_analyzer_data_o)
             , .yumi_i(deque_i)
         
             );

endmodule
