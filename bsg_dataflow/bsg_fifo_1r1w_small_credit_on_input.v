// This module converts between the valid-credit (input) and 
// valid-ready (output) handshakes, by using a fifo to keep
// the data
module bsg_fifo_1r1w_small_credit_on_input #( parameter width_p      = -1
                                            , parameter els_p        = -1
                                      
                                            //localpara
                                            , parameter ptr_width_lp = 
                                                `BSG_SAFE_CLOG2(els_p)+1
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
bsg_fifo_1r1w_small #( .width_p(width_p)
                     , .els_p(els_p) 
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

    
// Displaying errors in case of overflow or underflow
//synopsys translate_off		
always_ff @ (posedge clk_i)    
  begin  
		if (v_i  & ~ready & ~reset_i)
				$display("%m error: fifo-with-credit was not ready to \
          accept new data at time %t", $time);
		if (~v_o & yumi_i & ~reset_i)
				$display("%m error: fifo-with-credit did not send out \
          any data but received yumi at time %t", $time);			
  end
//synopsys translate_on								


endmodule 
