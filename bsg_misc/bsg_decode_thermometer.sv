module bsg_decode_thermometer #(parameter in_width_p, parameter out_width_lp=(1 << in_width_p)) (input [in_width_p-1:0] i, output logic [out_width_lp-1:0] o);
  logic signed [out_width_lp:0] temp;
  
  always @*
    begin
      temp = ( $signed(1'b1) << (out_width_lp) >>> i);
      o = { << { temp[out_width_lp-1:0] } };
    end
  
endmodule

`BSG_ABSTRACT_MODULE(bsg_decode_thermometer)
