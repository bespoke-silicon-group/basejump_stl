
`include "bsg_defines.sv"

/*
 * This module takes 1 bit of data and sends it out along with a clock pulse.
 *
 * When this module receives a bit, tag_clk_r_o becomes low and the
 *   received data is put on tag_data_r_o on the current cycle. On next cycle,
 *   tag_clk_r_o will become high and generate a positive clock edge. The clock
 *   signal will remain high until the next data comes in.
 *
 *                -----+
 * v_i:                |
 *                     +-----------------------------
 *
 *                     +-----+     +-----+     +-----
 * clk_i:              |     |     |     |     |
 *                -----+     +-----+     +-----+
 *
 *                -----+           +-----------------
 * tag_clk_r_o:        |           |
 *                     +-----------+
 *
 *                     +-----------------------+
 * tag_data_r_o:       |                       |
 *                -----+                       +-----
 *
 * One use case is to write sequence of data from software through bsg_tag_bitbang
 *   to bsg tag master. This eliminates the need of dedicated hardware, like a ROM
 *   and a tag trace replay module.
 *
 */                                        

module bsg_tag_bitbang(
    input clk_i
  , input reset_i
  , input data_i
  , input v_i
  , output logic ready_and_o // throughput: clk_i / 2

  // tag clock is a synchronously generated variable frequency clock that toggles
  //   once for every data bit that is transmitted.
  , output logic tag_clk_r_o
  , output logic tag_data_r_o
);

  logic tag_clk_r;
  logic tag_data_r;
  // Lower tag clock for one cycle upon a successful handshake
  wire tag_clk_n = ~(ready_and_o & v_i);

  bsg_dff_reset #(
     .width_p(1)
    ,.reset_val_p(1)
  ) tag_clk_reg (
     .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(tag_clk_n)
    ,.data_o(tag_clk_r)
  );

  bsg_dff_en #(.width_p(1)
  ) tag_data_reg (
     .clk_i(clk_i)
    ,.data_i(data_i)
    ,.en_i(~tag_clk_n)
    ,.data_o(tag_data_r)
  );

  assign tag_data_r_o = tag_data_r;
  assign tag_clk_r_o = tag_clk_r;
  assign ready_and_o = tag_clk_r;

endmodule

