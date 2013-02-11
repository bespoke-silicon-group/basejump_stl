module config_driver
  #(parameter
    test_vector_p = -1,
    test_vector_bits_p = -1
   )
   (input clk_i,
    input reset_i,
    output config_s config_o
   );

  logic [test_vector_bits_p - 1 : 0] test_vector;

  // initialize and right shift test vector
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      test_vector = test_vector_p;
    end else begin
      test_vector = {1'b0, test_vector[test_vector_bits_p - 1 : 1]};
    end
  end

  assign config_o.cfg_clk = clk_i;
  assign config_o.cfg_bit = test_vector[0];

endmodule
