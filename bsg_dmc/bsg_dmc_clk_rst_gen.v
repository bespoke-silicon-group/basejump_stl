`include "bsg_defines.v"

`include "bsg_clk_gen.vh"

module bsg_dmc_clk_rst_gen
  import bsg_tag_pkg::bsg_tag_s;
 #(parameter num_adgs_p         = 2
  ,parameter num_lines_p        = "inv")
  (input bsg_tag_s                   async_reset_tag_i
  ,input bsg_tag_s [num_lines_p-1:0] bsg_dly_tag_i
  ,input bsg_tag_s [num_lines_p-1:0] bsg_dly_trigger_tag_i
  ,input bsg_tag_s                   bsg_ds_tag_i
  // asynchronous reset for dram controller
  ,output                            async_reset_o
  // clock input and delayed clock output (for dqs), generating 90-degree phase
  // shift
  ,input           [num_lines_p-1:0] clk_i
  ,output          [num_lines_p-1:0] clk_o
  // 2x clock input from clock generator and 1x clock output
  ,input                             clk_2x_i
  ,output                            clk_1x_o);

  localparam debug_level_lp = 0;

  genvar i;

  bsg_tag_client_unsync #(.width_p(1)) btc_async_reset
    (.bsg_tag_i      ( async_reset_tag_i )
    ,.data_async_r_o ( async_reset_o     ));

  // Clock Generator (CG) Instance
  for(i=0;i<num_lines_p;i++) begin: dly_lines
    bsg_dly_line #(.num_adgs_p(num_adgs_p)) dly_line_inst
      (.bsg_tag_i         ( bsg_dly_tag_i[i]         )
      ,.bsg_tag_trigger_i ( bsg_dly_trigger_tag_i[i] )
      ,.async_reset_i     ( async_reset_o            )
      ,.clk_i             ( clk_i[i]                 )
      ,.clk_o             ( clk_o[i]                 ));
  end

  `declare_bsg_clk_gen_ds_tag_payload_s(2)

  bsg_clk_gen_ds_tag_payload_s ds_tag_payload_r;

  wire  ds_tag_payload_new_r;

  // fixme: maybe wire up a default and deal with reset issue?
  // downsampler bsg_tag interface
  bsg_tag_client #
    (.width_p   ( $bits(bsg_clk_gen_ds_tag_payload_s) )
    ,.default_p ( 0                                   )
    ,.harden_p  ( 1                                   ))
  btc_ds
    (.bsg_tag_i     ( bsg_ds_tag_i         )

    ,.recv_clk_i    ( clk_2x_i             )
    ,.recv_reset_i  ( 1'b0                 )   // node must be programmed by bsg tag
    ,.recv_new_r_o  ( ds_tag_payload_new_r )   // we don't require notification
    ,.recv_data_r_o ( ds_tag_payload_r     ));

  if (debug_level_lp > 1)
  always_ff @(negedge clk_2x_i) begin
    if (ds_tag_payload_new_r)
      $display("## bsg_clk_gen downsampler received configuration state: %b",ds_tag_payload_r);
  end

  // clock downsampler
  //
  // we allow the clock downsample reset to be accessed via bsg_tag; this way
  // we can turn it off by holding reset high to save power.
  //
  bsg_counter_clock_downsample #
    (.width_p  ( 2 )
    ,.harden_p ( 1 ))
  clk_gen_ds_inst
    (.clk_i   ( clk_2x_i               )
    ,.reset_i ( ds_tag_payload_r.reset )
    ,.val_i   ( 2'd0                   )
    ,.clk_r_o ( clk_1x_o               ));

endmodule

