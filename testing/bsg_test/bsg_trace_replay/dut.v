module dut
  #(  parameter payload_width_p =80
   ) (  input clk_i
      , input reset_i

    // input channel
    , input v_i
    , input [payload_width_p-1:0] data_i
    , output logic ready_o

    // output channel
    , output logic v_o
    , output logic [payload_width_p-1:0] data_o
    , input ready_i
    );

assign v_o     = v_i            ;
assign ready_o = ready_i        ;
assign data_o  = ~data_i        ;

endmodule
