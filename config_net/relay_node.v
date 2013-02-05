module relay_node
   (input config_in_s config_in,
    output bit_o
   );

  /* ========================================================================== *
   * This node simply forwards configuration bits from input to output. It can
   * be used to break critical paths in the config_node network.
   * ========================================================================== */

  logic bit_r, bit_n;

  assign bit_n = config_in.bit_i;

  always_ff @ (posedge config_in.clk_i) begin
    bit_r <= bit_n;
  end

  assign bit_o = bit_r;

endmodule
