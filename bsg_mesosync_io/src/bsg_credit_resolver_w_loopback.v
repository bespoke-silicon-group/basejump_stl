// This module is a loopback module with FIFO in input port and 
// uses credit protocol on both directions. Moreover, it has 
// enable_i signal to be enabled and disabed, and line_ready_i signal
// which means output line is ready to accept the data.
// In case of ~loopback_en_i, it would function as two separete modules,
// to make the credit handshake between the core and pins. 

module bsg_credit_resolver_w_loopback #( parameter width_p          = "inv"
                                       , parameter els_p            = "inv"
                                       , parameter credit_initial_p = "inv"
                                       , parameter credit_max_val_p = "inv"
                                       )
    ( input                clk_i
    , input                reset_i
    , input                enable_i
    , input                loopback_en_i 
    , input                line_ready_i

    // Connection to mesosync_link
    , input [width_p-1:0]  pins_data_i
    , input                pins_v_i
    , output logic         pins_credit_o

    , output               pins_v_o
    , output [width_p-1:0] pins_data_o
    , input                pins_credit_i

    // connection to core
    , input [width_p-1:0]  core_data_i
    , input                core_v_i
    , output logic         core_ready_o

    , output               core_v_o
    , output [width_p-1:0] core_data_o
    , input                core_ready_i
    
    );

// internal signals
logic fifo_yumi, fifo_valid, ready, valid;
logic valid_and_line_ready, credit_counter_ready;
logic [width_p-1:0] fifo_data;

// in case of ~enable_i, the FIFO would not get filled and fifo_valid
// would be zero
assign core_data_o  = loopback_en_i ? 0                    : fifo_data;
assign core_v_o     = loopback_en_i ? 0                    : fifo_valid;
assign ready        = loopback_en_i ? credit_counter_ready : core_ready_i;

assign core_ready_o = loopback_en_i ? 0                    : credit_counter_ready;
assign valid        = loopback_en_i ? fifo_valid           : core_v_i;
assign pins_data_o  = loopback_en_i ? fifo_data            : core_data_i;


// converting between valid-yumi and valid-ready protocols in case of loopback
assign fifo_yumi = ready & fifo_valid & enable_i & line_ready_i;

// Using a fifo with credit input protocol for input side
bsg_fifo_1r1w_small_credit_on_input #( .width_p(width_p)
                                     , .els_p(els_p) 
                                     ) input_fifo
                            
    ( .clk_i(clk_i)
    , .reset_i(reset_i)

    , .data_i(pins_data_i)
    , .v_i(pins_v_i & enable_i)
    , .credit_o(pins_credit_o)

    , .v_o(fifo_valid)
    , .data_o(fifo_data)
    , .yumi_i(fifo_yumi)

    );

assign valid_and_line_ready = valid & line_ready_i & enable_i;

// using a flow converter from valid-ready to valid-credit using credit
// counter
bsg_ready_to_credit_flow_converter #( .credit_initial_p(credit_initial_p)
                                    , .credit_max_val_p(credit_max_val_p)
                                    ) output_credit_counter                  
                            
    ( .clk_i(clk_i)
    , .reset_i(reset_i)

    , .v_i(valid_and_line_ready)
    , .ready_o(credit_counter_ready)

    , .v_o(pins_v_o)
    , .credit_i(pins_credit_i)

    );
 
/*
// Relay nodes for connecting to far modules on chip
// internal signals for relay
logic valid1,valid2,ready1, ready2;
logic [width_p-1:0] data1, data2;

bsg_relay_fifo #(.width_p(width_p)) relay1
    (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.ready_o()
    ,.data_i()
    ,.v_i()

    ,.v_o()
    ,.data_o()
    ,.ready_i()
    );

bsg_relay_fifo #(.width_p(width_p)) relay2
    (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.ready_o()
    ,.data_i()
    ,.v_i()

    ,.v_o()
    ,.data_o()
    ,.ready_i ()
    );
*/

endmodule
