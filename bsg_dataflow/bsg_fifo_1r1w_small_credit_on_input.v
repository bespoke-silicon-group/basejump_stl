// This module converts between the valid-credit (input) and 
// valid-ready (output) handshakes, by using a fifo to keep
// the data
`include "bsg_defines.v"

module bsg_fifo_1r1w_small_credit_on_input #( parameter width_p      = -1
                                            , parameter els_p        = -1
                                            )                           
                            
    ( input                clk_i
    , input                reset_i

    , input [width_p-1:0]  data_i
    , input                v_i
    , output logic         credit_o

    , output               v_o
    , output [width_p-1:0] data_o
    , input                yumi_i

    );

// internal signal for assert
logic ready;

// Yumi can be asserted during clock period, but credit must
// be asserted at the beginning of a cycle
always_ff @ (posedge clk_i)
  if (reset_i)
    credit_o <= 0;
  else
    credit_o <= yumi_i;

// ready_o is not checked since it is guaranteed by credit 
// system not to send extra inputs and every input must be 
// stored
// FIFO used to keep the data values
// credit protocol must take care of not enquing while fifo 
// is full, and assert an error otherwise, so it is like a
// fifo with ready_then_valid protocol
bsg_fifo_1r1w_small #( .width_p(width_p)
                     , .els_p(els_p) 
                     , .ready_THEN_valid_p(1)
                     ) fifo

                     ( .clk_i(clk_i)
                     , .reset_i(reset_i)

                     , .data_i(data_i)
                     , .v_i(v_i)
                     , .ready_o(ready)

                     , .v_o(v_o)
                     , .data_o(data_o)
                     , .yumi_i(yumi_i)

                     );
 
endmodule 
