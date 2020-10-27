`include "bsg_defines.v"

`include "config_defs.v"

module relay_node
   (input config_s config_i,
    output config_s config_o
   );

  /* ========================================================================== *
   * This node simply forwards configuration bits from input to output(s). It
   * can be used to break critical paths in the config_nodw network.
   * ========================================================================== */

  logic bit_r, bit_n;

  assign bit_n = config_i.cfg_bit;

  always_ff @ (posedge config_i.cfg_clk) begin
    bit_r <= bit_n;
  end

  assign config_o.cfg_clk = config_i.cfg_clk;
  assign config_o.cfg_bit = bit_r;

endmodule
