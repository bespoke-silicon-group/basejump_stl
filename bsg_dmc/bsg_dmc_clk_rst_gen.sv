`include "bsg_defines.sv"

`include "bsg_clk_gen.svh"

module bsg_dmc_clk_rst_gen
  import bsg_tag_pkg::bsg_tag_s;
  import bsg_dmc_pkg::*;
 #(parameter num_taps_p         = 4
  ,parameter ds_width_p         = 2
  ,parameter `BSG_INV_PARAM(dq_groups_p        ))
  (
  input bsg_dmc_dly_tag_lines_s         dly_tag_lines_i
  ,input bsg_dmc_osc_tag_lines_s        osc_tag_lines_i    
  // clock input and delayed clock output (for dqs), generating 90-degree phase
  // shift
  ,input           [dq_groups_p-1:0]    dqs_clk_i
  ,output          [dq_groups_p-1:0]    dqs_clk_o
  // 2x clock input from clock generator and 1x clock output
  //
  ,input                                ext_dfi_clk_2x_i
  ,input                                ui_clk_i
  ,input                                async_reset_i
  ,output                               ui_reset_o
  ,output                               dfi_reset_o
  ,output                               dfi_clk_2x_o
  ,output                               dfi_clk_1x_o);

  localparam debug_level_lp = 0;

  genvar i;

  logic dly_async_reset_r;
  bsg_tag_client_unsync #(.width_p(1)) btc_async_reset
    (.bsg_tag_i      ( dly_tag_lines_i.async_reset )
    ,.data_async_r_o ( dly_async_reset_r     ));

  // Clock Generator (CG) Instance
  for(i=0;i<dq_groups_p;i++) begin: dly_lines
    bsg_dmc_dly_line_v3 #(.num_taps_p(num_taps_p)) dly_line_inst
      (.clk_i(dqs_clk_i[i])
       ,.async_reset_i(dly_async_reset_r)
       ,.clk_o(dqs_clk_o[i])
       );
  end

  `declare_bsg_clk_gen_ds_tag_payload_s(ds_width_p);

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
    (.width_p  ( ds_width_p )
    ,.harden_p ( 1 ))
  clk_gen_ds_inst
    (.clk_i   ( dfi_clk_2x_o               )
    ,.reset_i ( ds_tag_payload_r.reset )
    ,.val_i   ( ds_tag_payload_r.val   )
    ,.clk_r_o ( dfi_clk_1x_o               ));

  logic osc_async_reset_r;

  bsg_tag_client_unsync #( .width_p(1) )
    osc_async_reset
      (.bsg_tag_i(osc_tag_lines_i.async_reset)
      ,.data_async_r_o(osc_async_reset_r)
      );

  logic [1:0] sel_tag_payload_r;

  bsg_tag_client_unsync #( .width_p(2) )
    osc_sel
      (.bsg_tag_i(osc_tag_lines_i.sel)
      ,.data_async_r_o(sel_tag_payload_r)
      );

  // Rely on true 400 MHz signal. Leaving the clock gen here for
  //   posterity. It should be possible to monitor this signal
  //   that we dynamically adjust the frequency and stay within
  //   tolerance without an external crystal
  assign dfi_clk_2x_o = ext_dfi_clk_2x_i;
  //bsg_clk_gen #(.downsample_width_p(ds_width_p)
  //             ,.num_adgs_p(num_adgs_p)
  //             ,.version_p(2)
  //             )
  //clk_gen_inst
  //    (.async_osc_reset_i     (osc_async_reset_r)
  //    ,.bsg_osc_tag_i         (osc_tag_lines_i.osc)
  //    ,.bsg_osc_trigger_tag_i (osc_tag_lines_i.osc_trigger)
  //    ,.bsg_ds_tag_i          (osc_tag_lines_i.ds)
  //    ,.ext_clk_i             (ext_dfi_clk_2x_i)
  //    ,.select_i              (sel_tag_payload_r)
  //    ,.clk_o                 (dfi_clk_2x_o)
  //    );

  bsg_sync_sync #(.width_p(1)) ui_reset_inst
    (.oclk_i      ( ui_clk_i      )
    ,.iclk_data_i ( async_reset_i )
    ,.oclk_data_o ( ui_reset_o    ));

  bsg_sync_sync #(.width_p(1)) dfi_reset_inst
    (.oclk_i      ( dfi_clk_1x_o      )
    ,.iclk_data_i ( async_reset_i     )
    ,.oclk_data_o ( dfi_reset_o       ));


endmodule

`BSG_ABSTRACT_MODULE(bsg_dmc_clk_rst_gen)
