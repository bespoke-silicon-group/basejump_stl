// This module is both input and output part of the mesosynchronous IO
// in a single module. It receives data from pins and also configurations
// of the link, and provides the data to the chip. More details can be 
// found in each sub_module and also bsg_mesosync_link
//
`ifndef DEFINITIONS_V
`include "definitions.v"
`endif

module bsg_mesosync_link_barebones
                   #( parameter width_p = -1
                    , parameter LA_els_p = -1
                    )
                    ( input                          clk
                    , input                          reset
                    
                    // Signals with their acknowledge
                    , input  [width_p-1:0]           pins_i

                    , output logic [width_p-1:0]     chip_o
                    , output logic                   valid_o
                    
                    , input  [width_p-1:0]           chip_i
                    , output logic                   ready_o

                    , output logic [width_p-1:0]     pins_o

                    // Configuration inputs
                    , input  clk_divider_s           clk_divider_i
                    , input  bit_cfg_s [width_p-1:0] bit_cfg_i
                    , input  mode_cfg_s              mode_cfg_i
                    , input  [$clog2(width_p)-1:0]   input_bit_selector_ch1_i
                    , input  [$clog2(width_p)-1:0]   output_bit_selector_ch1_i
                    , input  [$clog2(width_p)-1:0]   input_bit_selector_ch2_i
                    , input  [$clog2(width_p)-1:0]   output_bit_selector_ch2_i
                    );
                   
// internal signals
logic [1:0] logic_analyzer_data;
logic ready_to_LA, LA_valid;

bsg_mesosync_input
           #( .width_p(width_p)
            , .LA_els_p(LA_els_p)
            ) mesosync_input
            ( .clk(clk)
            , .reset(reset)
            
        
            // Sinals with their acknowledge
            , .pins_i(pins_i)

            , .chip_o(chip_o)
            , .valid_o(valid_o)
            
            // Logic analyzer signals for mesosync_output module
            , .logic_analyzer_data_o(logic_analyzer_data)
            , .LA_valid_o(LA_valid)
            , .ready_to_LA_i(ready_to_LA)

            // Configuration inputs
            , .input_clk_divider_i(clk_divider_i.input_clk_divider)
            , .bit_cfg_i(bit_cfg_i)
            , .input_mode_i(mode_cfg_i.input_mode)
            , .LA_enque_i(mode_cfg_i.LA_enque)
            , .input_bit_selector_ch1_i(input_bit_selector_ch1_i)
            , .input_bit_selector_ch2_i(input_bit_selector_ch2_i)

            );


bsg_mesosync_output
           #( .width_p(width_p)
            ) mesosync_output
            ( .clk(clk)
            , .reset(reset)
             
                         
            // Sinals with their acknowledge
            , .chip_i(chip_i)
            , .ready_o(ready_o)

            , .pins_o(pins_o)
            
            // Logic analyzer signals for mesosync_input module
            , .logic_analyzer_data_i(logic_analyzer_data)
            , .LA_valid_i(LA_valid)
            , .ready_to_LA_o(ready_to_LA)

            // Configuration inputs
            , .output_clk_divider_i(clk_divider_i.output_clk_divider)
            , .output_mode_i(mode_cfg_i.output_mode)
            , .output_bit_selector_ch1_i(output_bit_selector_ch1_i)
            , .output_bit_selector_ch2_i(output_bit_selector_ch2_i)

            );

endmodule
