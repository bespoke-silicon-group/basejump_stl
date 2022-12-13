
`include "bsg_defines.v"

/*
 * When a new data arrives, tag_clk_r_o will toggle once and then be held
 *   high until the next new data comes in.
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
 */                                        

module bsg_tag_bitbang(
    input clk_i
  , input reset_i
  , input data_i
  , input v_i
  , output logic ready_then_o // throughput: clk_i / 2

  , output logic tag_clk_r_o
  , output logic tag_data_r_o
);

  logic tag_data_valid_r;
  logic tag_data_r;
  wire tag_data_valid_n = ~tag_data_valid_r | ~v_i;

  bsg_dff_reset #(
     .width_p(1)
    ,.reset_val_p(1)
  ) tag_data_valid_reg (
     .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.data_i(tag_data_valid_n)
    ,.data_o(tag_data_valid_r)
  );

  bsg_dff_en #(.width_p(1)
  ) tag_data_reg (
     .clk_i(clk_i)
    ,.data_i(data_i)
    ,.en_i(~tag_data_valid_n)
    ,.data_o(tag_data_r)
  );

  assign tag_data_r_o = tag_data_r;
  assign tag_clk_r_o = tag_data_valid_r;
  assign ready_then_o = tag_data_valid_r;

endmodule

