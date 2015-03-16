// A mesosynchronous channel that has the loopback module inside as well

//`ifndef DEFINITIONS_V
//`include "definitions.v"
//`endif

module bsg_mesosync_channel_w_loopback 
                  #(  parameter width_p          = -1
                    , parameter LA_els_p         = -1
                    , parameter loopback_els_p   = -1
                    , parameter credit_initial_p = -1
                    , parameter credit_max_val_p = -1
                    )
                   (  input                          clk
                    , input                          reset
                    , input                          ch_reset
  
                    // Configuration inputs
                    , input  clk_divider_s           clk_divider_i
                    , input  bit_cfg_s [width_p-1:0] bit_cfg_i
                    , input  mode_cfg_s              mode_cfg_i
                    , input  [$clog2(width_p)-1:0]   input_bit_selector_ch1_i
                    , input  [$clog2(width_p)-1:0]   output_bit_selector_ch1_i
                    , input  [$clog2(width_p)-1:0]   input_bit_selector_ch2_i
                    , input  [$clog2(width_p)-1:0]   output_bit_selector_ch2_i

                    , input                          en_loopback_i             
                    // Sinals with their acknowledge
                    , input  [width_p-1:0]           IO_i
                    , output logic [width_p-1:0]     IO_o
                   );

// Internal Signals
logic [width_p-1:0] to_loopback;
logic [width_p-1:0] from_loopback;
logic valid , ready;

bsg_mesosync_channel 
           #(  .width_p(width_p)
             , .LA_els_p(LA_els_p)
             ) mesosync_channel
            (  .clk(clk)
             , .reset(ch_reset)
             
             // Configuration inputs
             , .clk_divider_i(clk_divider_i)
             , .bit_cfg_i(bit_cfg_i)
             , .mode_cfg_i(mode_cfg_i)
             , .input_bit_selector_ch1_i(input_bit_selector_ch1_i)
             , .output_bit_selector_ch1_i(output_bit_selector_ch1_i)
             , .input_bit_selector_ch2_i(input_bit_selector_ch2_i)
             , .output_bit_selector_ch2_i(output_bit_selector_ch2_i)

        
             // Sinals with their acknowledge
             , .IO_i(IO_i)

             , .chip_o(to_loopback)
             , .valid_o(valid)
             
             , .chip_i(from_loopback)
             , .ready_o(ready)

             , .IO_o(IO_o)

             );

bsg_loopback_credit_protocol #( .width_p(width_p-2)
                              , .els_p(loopback_els_p)
                              , .credit_initial_p(credit_initial_p)
                              , .credit_max_val_p(credit_max_val_p)
                              ) loopback
    ( .clk_i(clk)
    , .reset_i(reset)
    , .enable_i(en_loopback_i)
    , .ready_i(ready)

    , .data_i(to_loopback[width_p-1:2])
    , .v_i(valid & to_loopback[0])
    , .credit_o(from_loopback[1])

    , .v_o(from_loopback[0])
    , .data_o(from_loopback[width_p-1:2])
    , .credit_i(valid & to_loopback[1])

    );

endmodule
