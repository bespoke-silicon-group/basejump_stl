// bsg_mesosync_channel is the designed IO in bsg group that devides
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
// To find out the proper values for bit configuration, it has 2 logic
// analzers which would sample input singal on both positive and negative
// edges of the clock. Master chooses two lines at a time and sends known
// patterns to them and read the logic analyzer's data to find out the delays
// of each line and find the proper line configurations. Finally, a loopback
// mode is enabled and it sends out the input data to its output. 
//
// There is no handshake protocl on the pins side, but from channel to core 
// there is valid handshake to tell the FIFO which data is valid to be
// sampled. On the core to channel connection, it has ready protocol, to let 
// the core know when it can send data. 
//
// Most important feature of this IO is least latency.

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
                    
                    , parameter width_lp = ch1_width_p + ch2_width_p
                   )
                   (  input                       clk
                    , input                       reset
                    , input  config_s             config_i

                    // Signals with their acknowledge
                    , input  [width_lp-1:0]       pins_i
                    , output logic [width_lp-1:0] pins_o
                    
                    // connection to core, 2 bits are used for handshake
                    , input  [width_lp-3:0]       core_data_i
                    , input                       core_v_i
                    , output logic                core_ready_o

                    , output                      core_v_o
                    , output [width_lp-3:0]       core_data_o
                    , input                       core_ready_i
     
                    );

// internal singals
logic                          loopback_en,fifo_en;
logic                          channel_reset;
logic                          ready, valid;
logic [width_lp-1:0]           to_pins;
logic [width_lp-1:0]           to_loopback;
logic [width_lp-1:0]           from_loopback;
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

            , .core_o(to_loopback)
            , .valid_o(valid)
            
            // Logic analyzer signals for mesosync_output module
            , .logic_analyzer_data_o(logic_analyzer_data)
            , .LA_valid_o(LA_valid)
            , .ready_to_LA_i(ready_to_LA)
                   
            // loopback signals
            , .fifo_en_o(fifo_en)
            , .loopback_en_o(loopback_en)
            , .channel_reset_o(channel_reset)

            );


bsg_mesosync_output
           #( .width_p(width_lp)
            , .cfg_tag_base_id_p(cfg_tag_base_id_p)
            ) mesosync_output
            ( .clk(clk)
            , .reset(reset)
            , .config_i(relay_out)
                         
            // Sinals with their acknowledge
            , .core_i(from_loopback)
            , .ready_o(ready)

            , .pins_o(to_pins)
            
            // Logic analyzer signals for mesosync_input module
            , .logic_analyzer_data_i(logic_analyzer_data)
            , .LA_valid_i(LA_valid)
            , .ready_to_LA_o(ready_to_LA)
            
            );

// loop back module with enable and ready inputs, and credit protocol
// on both directions
bsg_credit_resolver_w_loopback #( .width_p(width_lp-2)
                                , .els_p(loopback_els_p)
                                , .credit_initial_p(credit_initial_p)
                                , .credit_max_val_p(credit_max_val_p)
                                ) loopback
    ( .clk_i(clk)
    , .reset_i(reset)
    , .enable_i(fifo_en & ~channel_reset)
    , .loopback_en_i(loopback_en)
    , .line_ready_i(ready)

    // Connection to mesosync_link
    , .pins_data_i(to_loopback[width_lp-1:2])
    , .pins_v_i(valid & to_loopback[0])
    , .pins_credit_o(from_loopback[1])

    , .pins_v_o(from_loopback[0])
    , .pins_data_o(from_loopback[width_lp-1:2])
    , .pins_credit_i(valid & to_loopback[1])
    
    // connection to core
    , .core_data_i(core_data_i)
    , .core_v_i(core_v_i)
    , .core_ready_o(core_ready_o)

    , .core_v_o(core_v_o)
    , .core_data_o(core_data_o)
    , .core_ready_i(core_ready_i)
  
    );

// mesosync channel uses the channel reset from config_tag
// hence during reset output of module must be made zero on 
// this top module
always_comb
  if (reset) begin
    pins_o = 0;
  end else begin 
    pins_o = to_pins;
  end

endmodule
