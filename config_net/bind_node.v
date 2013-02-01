module bind_node
  #(parameter             // node specific parameters 
    id_p = -1,            // unique ID of this node
    data_bits_p = -1,     // number of bits of configurable register associated with this node
    data_ref_len_p = -1,  // default/reset value of configurable register associated with this node
    logic [data_bits_p - 1 : 0] data_ref_p[data_ref_len_p] = 0  // data_o change reference array
   )
   (input config_in_s config_in,
    
    input [data_bits_p - 1 : 0] data_o,
    input bit_o
   );

   int data_ref_idx = 0;
   always @ (data_o) begin
     $display("  @time %0d: \t output data_o_%0d\t changed to %b", $time, id_p, data_o);
     if (data_o !== data_ref_p[data_ref_idx]) begin
       $display("  @time %0d: \t ERROR output data_o_%0d = %b <-> expected = %b", $time, id_p, data_o, data_ref_p[data_ref_idx]);
     end
     data_ref_idx += 1;
   end

endmodule
