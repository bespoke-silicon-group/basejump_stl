// This module converts from valid-and-credit protocol to valid-and-ready
// protocol, using FIFO in input side and credit-counter on output side.
// Moreover, it is taylored for bsg_mesosynchronous_io, which also requires
// another level of handshake, a line_ready_i signal. This signal acts like 
// valid-and-ready protocol and means channel has sent the data. 

// Moreover, it has two modes, one for forwarding between meso-synchronous 
// channel and the core on the other side, or loopback mode for last step 
// of mesosynchronous channel callibration. Operation mode is determined
// by line_ready_i signal.

module bsg_mesosync_loopback #( parameter width_p          = "inv"
                              , parameter els_p            = "inv"
                              , parameter credit_initial_p = "inv"
                              , parameter credit_max_val_p = "inv"
                              )
    ( input                clk_i
    , input                reset_i
    , input                loopback_en_i 
    , input                line_ready_i

    // Connection to mesosync_link
    , input [width_p-1:0]  meso_data_i
    , input                meso_v_i
    , output logic         meso_credit_o

    , output               meso_v_o
    , output [width_p-1:0] meso_data_o
    , input                meso_credit_i

    // connection to core
    , input [width_p-1:0]  data_i
    , input                v_i
    , output logic         ready_o

    , output               v_o
    , output [width_p-1:0] data_o
    , input                ready_i
    
    );

// Relay nodes for connecting to far modules on chip
// internal signals for relay
logic v_i_r,v_o_r,ready_i_r, ready_o_r;
logic [width_p-1:0] data_i_r, data_o_r;

bsg_relay_fifo #(.width_p(width_p)) input_relay
    (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(v_i)
    ,.data_i(data_i)
    ,.ready_o(ready_o)

    ,.v_o(v_i_r)
    ,.data_o(data_i_r)
    ,.ready_i(ready_o_r)
    );

bsg_relay_fifo #(.width_p(width_p)) output_relay
    (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i(v_o_r)
    ,.data_i(data_o_r)
    ,.ready_o(ready_i_r)

    ,.v_o(v_o)
    ,.data_o(data_o)
    ,.ready_i (ready_i)
    );


// internal signals
logic yumi_to_fifo, ready_to_fifo;
logic fifo_valid, ready, valid;
logic valid_to_credit_counter, credit_counter_ready;
logic [width_p-1:0] fifo_data;

// Muxes for mode selection, between loopback or normal mode
assign valid          = loopback_en_i ? fifo_valid           : v_i_r;
assign ready          = loopback_en_i ? credit_counter_ready : ready_i_r;
assign meso_data_o    = loopback_en_i ? fifo_data            : data_i_r;

assign v_o_r          = loopback_en_i ? 0 : fifo_valid & line_ready_i;
assign data_o_r       = loopback_en_i ? 0 : fifo_data;
assign ready_o_r      = loopback_en_i ? 0 : credit_counter_ready & line_ready_i;

// Adding ready signal from bsg_mesosync_output module, line_ready_i
assign valid_to_credit_counter = line_ready_i & valid;
// also converting from yumi protocol to ready protocol
assign yumi_to_fifo            = ready & line_ready_i & fifo_valid;

// Using a fifo with credit input protocol for input side
bsg_fifo_1r1w_small_credit_on_input #( .width_p(width_p)
                                     , .els_p(els_p) 
                                     ) input_fifo
                            
    ( .clk_i(clk_i)
    , .reset_i(reset_i)

    , .data_i(meso_data_i)
    , .v_i(meso_v_i)
    , .credit_o(meso_credit_o)

    , .v_o(fifo_valid)
    , .data_o(fifo_data)
    , .yumi_i(yumi_to_fifo)

    );

// using a flow converter from valid-ready to valid-credit using credit
// counter
bsg_ready_to_credit_flow_converter #( .credit_initial_p(credit_initial_p)
                                    , .credit_max_val_p(credit_max_val_p)
                                    ) output_credit_counter                  
                            
    ( .clk_i(clk_i)
    , .reset_i(reset_i)

    , .v_i(valid_to_credit_counter)
    , .ready_o(credit_counter_ready)

    , .v_o(meso_v_o)
    , .credit_i(meso_credit_i)

    );
 
endmodule
