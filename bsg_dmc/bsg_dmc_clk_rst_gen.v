`include "bsg_defines.v"

`include "bsg_clk_gen.vh"

module bsg_dmc_clk_rst_gen
  import bsg_tag_pkg::bsg_tag_s;
  import bsg_dmc_pkg::*;
 #(parameter num_adgs_p         = 2
  ,parameter `BSG_INV_PARAM(num_lines_p        ))
  (
  input bsg_dmc_dly_tag_lines_s         dly_tag_lines_i
  ,input bsg_dmc_osc_tag_lines_s        osc_tag_lines_i    
  // asynchronous reset for dram controller
  ,output                               async_reset_o
  // clock input and delayed clock output (for dqs), generating 90-degree phase
  // shift
  ,input           [num_lines_p-1:0]    clk_i
  ,output          [num_lines_p-1:0]    clk_o
  // 2x clock input from clock generator and 1x clock output
  //
  ,input                                ext_clk_i
  ,output                               dfi_clk_2x_o
  ,output                               dfi_clk_1x_o);

  localparam debug_level_lp = 0;

  genvar i;

  bsg_tag_client_unsync #(.width_p(1)) btc_async_reset
    (.bsg_tag_i      ( dly_tag_lines_i.async_reset )
    ,.data_async_r_o ( async_reset_o     ));

  // Clock Generator (CG) Instance
  for(i=0;i<num_lines_p;i++) begin: dly_lines
    bsg_dly_line #(.num_adgs_p(num_adgs_p)) dly_line_inst
      (.bsg_tag_i         ( dly_tag_lines_i.dly[i]         )
      ,.bsg_tag_trigger_i ( dly_tag_lines_i.dly_trigger[i] )
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
    ,.harden_p  ( 1                                   ))
  btc_ds
    (.bsg_tag_i     ( dly_tag_lines_i.ds              )

    ,.recv_clk_i    ( dfi_clk_2x_o             )
    ,.recv_new_r_o  ( ds_tag_payload_new_r )   // we don't require notification
    ,.recv_data_r_o ( ds_tag_payload_r     ));

  if (debug_level_lp > 1)
  always_ff @(negedge dfi_clk_2x_o) begin
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
    (.clk_i   ( dfi_clk_2x_o               )
    ,.reset_i ( ds_tag_payload_r.reset )
    ,.val_i   ( 2'd0                   )
    ,.clk_r_o ( dfi_clk_1x_o               ));

  logic async_reset_lo;

  bsg_tag_client_unsync #( .width_p(1) )
    osc_async_reset
      (.bsg_tag_i(osc_tag_lines_i.async_reset)
      ,.data_async_r_o(async_reset_lo)
      );

  bsg_clk_gen #(.downsample_width_p(2)
               ,.num_adgs_p(num_adgs_p)
               ,.version_p(2)
  			 ,.nonsynth_sim_osc_granularity_p(50)
               )
  clk_gen_inst
      (.async_osc_reset_i     (async_reset_lo)
      ,.bsg_osc_tag_i         (osc_tag_lines_i.osc)
      ,.bsg_osc_trigger_tag_i (osc_tag_lines_i.osc_trigger)
      ,.bsg_ds_tag_i          (osc_tag_lines_i.ds)
      ,.ext_clk_i             (ext_clk_i)
      ,.select_i              (2'b00)
      ,.clk_o                 (dfi_clk_2x_o)
      );

endmodule

`BSG_ABSTRACT_MODULE(bsg_dmc_clk_rst_gen)
