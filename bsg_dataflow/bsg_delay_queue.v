/**
 *
 *  bsg_delay_queue.v
 *
 *  This module is meant to simulate delay of arbitrary length.
 *  Though this is synthesizable, this is not intended to be used in a real design,
 *  as it is not ideal in terms of the energetic perspective.
 *
 */


module bsg_delay_queue
  #(parameter width_p="inv"
    , parameter delay_p="inv"
  )
  (
    input clk_i
    , input reset_i

    , input [width_p-1:0] data_i
    , input v_i
    , output logic ready_o
  
    , output logic [width_p-1:0] data_o
    , output logic v_o
    , input yumi_i
  );

  // delay buffer
  // valid_bit + data
  logic [delay_p-1:0][width_p:0] buffer;

  // handshaking logic 
  //
  logic stall;
  assign stall = v_o & ~yumi_i;  
  assign ready_o = ~stall;

  always_ff @ (posedge clk_i) begin
    if (reset_i)
      for (integer i = 0; i < delay_p; i++)
        buffer[i] <= '0;
    else
      if (~stall) begin
        buffer[0] <= {v_i, data_i};
        for (integer i = 1; i < delay_p; i++)
          buffer[i] <= buffer[i-1];
      end
  end

  assign v_o = buffer[delay_p-1][width_p]; 
  assign data_o = buffer[delay_p-1][0+:width_p];

endmodule
