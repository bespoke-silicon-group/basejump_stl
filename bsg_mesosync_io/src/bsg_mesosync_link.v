// bsg_mesosync_link is the designed IO in bsg group that devides
// the core's clock to a slower clock for IO based on the configuration 
// it receives. For each input data line it can choose between the clock
// edge and which cycle in the divided clock to take the sameple, based on
// the bit_cfg_i configuration. 
//
// It has four phases to be calibrated. After reset, it would send out a 
// known pattern so the other side (master) can bit-allign its input. Next 
// it would send all possible transitions of data using two counters to make 
// sure the output channel is reliable.
//
// To find out the proper values for bit configuration, it has a logic
// analzers which would sample input singal on both positive and negative
// edges of the clock. Master chooses a line at a time and sends known
// patterns to it and read the logic analyzer's data to find out the delays
// of each line and find the proper line configurations. Finally, a loopback
// mode is enabled and it sends out the input data to its output for final check. 
//
// There is no handshake protocol on the pins side, but from channel to core 
// there is valid-and-ready handshake protocol. It must be connected to a 
// valid-and-credit protocol based module on the connected chip. It uses 
// a FIFO and credit counter to convert from valid-only to valid-and-credit
// and to valid-and-ready in next step. 
// 
// It includes 3 main modules, bsg_mesosync_input must be close to input pins,
// bsg_mesosync_output must be close to output pins and bsg_mesosync_loopback
// must be close and next to bsg_mesosync_output. Connection between input
// and output module and input and loopback module are distance safe, using 
// bsg_fifo_relay. Moreover, connection between core and loopback module is
// distance safe as well.
//
// Most important feature of this IO is least latency.

`include "bsg_defines.v"

`ifndef DEFINITIONS_V
`include "definitions.v"
`endif

module bsg_mesosync_link
                  #(  parameter ch1_width_p       = "inv" //3  
                    , parameter ch2_width_p       = "inv" //3  
                    , parameter LA_els_p          = "inv" //64 
                    , parameter cfg_tag_base_id_p = "inv" //10 
                    , parameter loopback_els_p    = "inv" //16 
                    , parameter credit_initial_p  = "inv" //8  
                    , parameter credit_max_val_p  = "inv" //12 
                    , parameter decimation_p      = "inv" //4

                    , parameter width_lp = ch1_width_p + ch2_width_p
                   )
                   (  input                       clk
                    , input                       reset
                    , input  config_s             config_i

                    // Signals with their acknowledge
                    , input  [width_lp-1:0]       pins_i
                    , output logic [width_lp-1:0] pins_o
                    
                    // connection to core, 2 bits are used for handshake
                    , input  [width_lp-3:0]       data_i
                    , input                       v_i
                    , output logic                ready_o

                    , output                      v_o
                    , output [width_lp-3:0]       data_o
                    , input                       ready_i
     
                    );

// internal singals
logic                          channel_reset;
logic                          loopback_en;
logic                          ready, valid;
logic [width_lp-1:0]           from_meso_input;
logic [width_lp-1:0]           to_meso_output;
logic                          logic_analyzer_data, ready_to_LA, LA_valid;

// relay nodes
config_s relay_out;

relay_node input_relay_1(.config_i(config_i),
                         .config_o(relay_out));

// Mesosynchronous channel
bsg_mesosync_input
           #( .ch1_width_p(ch1_width_p)
            , .ch2_width_p(ch2_width_p)
            , .LA_els_p(LA_els_p)
            , .cfg_tag_base_id_p(cfg_tag_base_id_p)
            ) mesosync_input
            ( .clk(clk)
            , .reset(reset)
            , .config_i(relay_out)
            
            // Sinals with their acknowledge
            , .pins_i(pins_i)

            , .data_o(from_meso_input)
            , .valid_o(valid)

            // Logic analyzer signals for mesosync_output module
            , .LA_data_o(logic_analyzer_data)
            , .LA_valid_o(LA_valid)
            , .ready_to_LA_i(ready_to_LA)
                   
            );

bsg_mesosync_output
           #( .width_p(width_lp)
            , .cfg_tag_base_id_p(cfg_tag_base_id_p)
            ) mesosync_output
            ( .clk(clk)
            , .reset(reset)
            , .config_i(relay_out)
                         
            // Sinals with their acknowledge
            , .data_i(to_meso_output)
            , .ready_o(ready)

            , .pins_o(pins_o)
            
            // Logic analyzer signals for mesosync_input module
            , .LA_data_i(logic_analyzer_data)
            , .LA_valid_i(LA_valid)
            , .ready_to_LA_o(ready_to_LA)
            
            // loopback signals
            , .loopback_en_o(loopback_en)
            , .channel_reset_o(channel_reset)
            );

// loop back module with mode and line_ready inputs, and valid-and-credit 
// protocol on both directions to meso-channel , and valid-and-ready protocol
// on both directions to core
bsg_mesosync_core #( .width_p(width_lp-2)
                   , .els_p(loopback_els_p)
                   , .credit_initial_p(credit_initial_p)
                   , .credit_max_val_p(credit_max_val_p)
                   , .decimation_p(decimation_p)
                   ) mesosync_core
    ( .clk_i(clk)
    , .reset_i(channel_reset)
    , .loopback_en_i(loopback_en)
    , .line_ready_i(ready)

    // Connection to mesosync_link
    , .meso_data_i(from_meso_input[width_lp-1:2])
    , .meso_v_i(valid & from_meso_input[0])
    , .meso_token_o(to_meso_output[1])

    , .meso_v_o(to_meso_output[0])
    , .meso_data_o(to_meso_output[width_lp-1:2])
    , .meso_token_i(valid & from_meso_input[1])
    
    // connection to core
    , .data_i(data_i)
    , .v_i(v_i)
    , .ready_o(ready_o)

    , .v_o(v_o)
    , .data_o(data_o)
    , .ready_i(ready_i)
  
    );

endmodule
