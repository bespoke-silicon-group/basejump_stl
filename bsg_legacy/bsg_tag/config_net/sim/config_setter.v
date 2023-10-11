`include "bsg_defines.v"

`include "config_defs.v"

module config_setter
  #(parameter
    setter_vector_p = -1,
    setter_vector_bits_p = -1
   )
   (input clk_i,
    input reset_i,
    output config_s config_o
   );

  logic [setter_vector_bits_p - 1 : 0] setter_vector;

  // initialize and right shift setter vector
  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      setter_vector = setter_vector_p;
    end else begin
      setter_vector = {1'b0, setter_vector[setter_vector_bits_p - 1 : 1]};
    end
  end

  assign config_o.cfg_clk = clk_i;
  assign config_o.cfg_bit = setter_vector[0];

endmodule
