// This module is a loopback module with FIFO in input port and 
// uses credit protocol on both directions. Moreover, it has 
// enable_i signal to be enabled and disabed, and line_ready_i signal
// which means output line is ready to accept the data.
// In case of ~loopback_en_i, it would function as two separete modules,
// to make the credit handshake between the chip and pins. 

module bsg_credit_resolver_w_loopback #( parameter width_p          = -1
                                       , parameter els_p            = -1
                                       , parameter credit_initial_p = -1
                                       , parameter credit_max_val_p = -1
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

    // connection to chip
    , input [width_p-1:0]  chip_data_i
    , input                chip_v_i
    , output logic         chip_ready_o

    , output               chip_v_o
    , output [width_p-1:0] chip_data_o
    , input                chip_yumi_i
    
    );

// internal signals
logic yumi, fifo_valid, ready, valid;
logic [width_p-1:0] data;

assign chip_data_o  = loopback_en_i ? 0   : data;
// in case of ~enable_i, the FIFO would not get filled and fifo_valid
// would be zero
assign chip_v_o     = loopback_en_i ? 0   : fifo_valid;
assign chip_ready_o = loopback_en_i ? 0   : ready;
assign pins_data_o  = loopback_en_i ? data: chip_data_i;

// converting between valid-yumi and valid-ready protocols in case of loopback
assign yumi         = loopback_en_i ? 
      (ready & fifo_valid & line_ready_i) : chip_yumi_i;

assign valid        = loopback_en_i ? 
              (fifo_valid & line_ready_i) : chip_v_i;

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
    , .data_o(data)
    , .yumi_i(yumi & enable_i)

    );


// using a flow converter from valid-ready to valid-credit using credit
// counter
bsg_ready_to_credit_flow_converter #( .credit_initial_p(credit_initial_p)
                                   , .credit_max_val_p(credit_max_val_p)
                                   ) output_credit_counter                  
                            
    ( .clk_i(clk_i)
    , .reset_i(reset_i)

    , .v_i(valid & enable_i)
    , .ready_o(ready)

    , .v_o(pins_v_o)
    , .credit_i(pins_credit_i)

    );
 
endmodule
