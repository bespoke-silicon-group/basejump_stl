// bsg_nonsynth_mixin_motherboard_comm_link
//
// This module is a mixin module, because it is parameterize by a module name
// and two submodules that need to be predefined.
//
// This file is a generic motherboard testing module; there are two "sockets"
// for chips. These chips have standard electrical interfaces corresponding
// to the bsg comm link. One socket is for the chipset, and the other is for the
// chip.
//
// To use this module, you must set three defines:
//
// BSG_NONSYNTH_MIXIN_MOTHERBOARD_module_name - the name of the motherboard module
//
// BSG_NONSYNTH_MIXIN_MOTHERBOARD_chipset_sig - partial instantiation of chipset module
// BSG_NONSYNTH_MIXIN_MOTHERBOARD_chip_sig    - partial instantiation of the chip module
//
//
//

`include "bsg_defines.v"

`ifndef BSG_NONSYNTH_MIXIN_MOTHERBOARD_module_name
ERROR in bsg_nonsynth_mixin_motherboard.v: BSG_NONSYNTH_MIXIN_MOTHERBOARD_module_name must be defined
`endif


`ifndef BSG_NONSYNTH_MIXIN_MOTHERBOARD_chip_sig
ERROR in bsg_nonsynth_mixin_motherboard.v: BSG_NONSYNTH_MIXIN_MOTHERBOARD_chip_sig must be defined
`endif


`ifndef BSG_NONSYNTH_MIXIN_MOTHERBOARD_chip_sig
ERROR in bsg_nonsynth_mixin_motherboard.v: BSG_NONSYNTH_MIXIN_MOTHERBOARD_chip_sig must be defined
`endif



// note: this module is non-synthesizable

module `BSG_NONSYNTH_MOTHERBOARD_MIXIN_module_name
 #( parameter tile_x_max_p    = "inv"
  , parameter tile_y_max_p    = "inv"
  , parameter asic_core_period_p         = 5ns
  , parameter chipset_core_period_p      = 6ns
  , parameter asic_io_master_period_p    = 7ns
  , parameter chipset_io_master_period_p = 8ns
  , parameter tline_delay_p              = 5ns // we could change this to have different delays
    // defaults; usually do not change
  , parameter num_channels_p  = 4
  , parameter channel_width_p = 8
  )
   ( output    logic asic_core_clock_o
     , output    logic asic_core_reset_o
    );

   wire  asic_core_clk_i;
   wire  asic_async_reset_i;
   wire  asic_io_master_clk_i;

   wire  chipset_core_clk_i;
   wire  chipset_async_reset_i;
   wire  chipset_io_master_clk_i;

   assign asic_core_clock_o = asic_core_clk_i;

   bsg_nonsynth_clock_gen #(.cycle_time_p(asic_core_period_p))    asic_clk     (.o(asic_core_clk_i   ));
   bsg_nonsynth_clock_gen #(.cycle_time_p(chipset_core_period_p)) chipset_clk  (.o(chipset_core_clk_i));

   initial
     $display("%m creating clocks"
              ,asic_core_period_p     , chipset_core_period_p
              ,asic_io_master_period_p, chipset_io_master_period_p);

   bsg_nonsynth_clock_gen #(.cycle_time_p(asic_io_master_period_p))    i0_clk (.o(asic_io_master_clk_i   ));
   bsg_nonsynth_clock_gen #(.cycle_time_p(chipset_io_master_period_p)) i1_clk (.o(chipset_io_master_clk_i));

   localparam core_reset_cycles_hi_lp = 256;
   localparam core_reset_cycles_lo_lp = 16;

   bsg_nonsynth_reset_gen
     #(.num_clocks_p(4)
       ,.reset_cycles_lo_p(core_reset_cycles_lo_lp)
       ,.reset_cycles_hi_p(core_reset_cycles_hi_lp)
       ) reset_gen
       (.clk_i({ asic_core_clk_i, asic_io_master_clk_i, chipset_core_clk_i, chipset_io_master_clk_i })
        ,.async_reset_o(chipset_async_reset_i)
        );

   wire [num_channels_p-1:0]  asic_io_clk_tline_i;
   wire [num_channels_p-1:0]  asic_io_valid_tline_i;
   wire [channel_width_p-1:0] asic_io_data_tline_i  [num_channels_p-1:0];
   wire [num_channels_p-1:0]  asic_io_token_clk_tline_o;

   // out to i/o
   wire [num_channels_p-1:0]  asic_im_clk_tline_o;
   wire [num_channels_p-1:0]  asic_im_valid_tline_o;
   wire [channel_width_p-1:0] asic_im_data_tline_o  [num_channels_p-1:0];
   wire [num_channels_p-1:0]  asic_token_clk_tline_i;

   wire [num_channels_p-1:0]  chipset_io_clk_tline_i;
   wire [num_channels_p-1:0]  chipset_io_valid_tline_i;
   wire [channel_width_p-1:0] chipset_io_data_tline_i  [num_channels_p-1:0];
   wire [num_channels_p-1:0]  chipset_io_token_clk_tline_o;

   // out to i/o
   wire [num_channels_p-1:0]  chipset_im_clk_tline_o;
   wire [num_channels_p-1:0]  chipset_im_valid_tline_o;
   wire [channel_width_p-1:0] chipset_im_data_tline_o  [num_channels_p-1:0];
   wire [num_channels_p-1:0]  chipset_token_clk_tline_i;

   wire                       chipset_im_slave_reset_tline_r_o;
   wire                       chipset_core_reset_o;

   // **************************
   // the FPGA

/*
   bsg_nonsynth_raw_chipset_vtile_pli #(.tile_x_max_p(tile_x_max_p)
                                        ,.tile_y_max_p(tile_y_max_p)
                                        ,.channel_width_p(channel_width_p)
                                        ,.num_channels_p(num_channels_p)
                                        ,.master_bypass_test_p(5'b11111) // speed up simulation
                                        ,.enabled_at_start_vec_p( { (tile_x_max_p+1) {1'b1 } })
                                        ) */

   `BSG_NONSYNTH_MIXIN_MOTHERBOARD_chipset_sig

   chipset
     (
      .core_clk_i(chipset_core_clk_i)
      , .async_reset_i(chipset_async_reset_i)
      , .io_master_clk_i(chipset_io_master_clk_i)

      // input from i/o
      , .io_clk_tline_i  (chipset_io_clk_tline_i)       // clk
      , .io_valid_tline_i(chipset_io_valid_tline_i)
      , .io_data_tline_i (chipset_io_data_tline_i)
      , .io_token_clk_tline_o(chipset_io_token_clk_tline_o) // clk

      // out to i/o
      , .im_clk_tline_o   (chipset_im_clk_tline_o   )    // clk
      , .im_valid_tline_o (chipset_im_valid_tline_o )
      , .im_data_tline_o  (chipset_im_data_tline_o  )
      , .token_clk_tline_i(chipset_token_clk_tline_i)    // clk

      // note: generate by the master (FPGA) and sent to the slave (ASIC)
      // not used by slave (ASIC).
      , .im_slave_reset_tline_r_o(chipset_im_slave_reset_tline_r_o)

      // this signal is the post-calibration reset signal
      // synchronous to the core clock
      , .core_reset_o(chipset_core_reset_o)
      );

   // **************************
   // PC board traces
   //
   // we introduce delays in the transmission lines that
   // go between chips; technically we could use different delays
   //

   bsg_nonsynth_delay_line #(.width_p(num_channels_p), .delay_p(tline_delay_p)) bdl0
   (.i(asic_im_clk_tline_o),    .o(chipset_io_clk_tline_i));

   bsg_nonsynth_delay_line #(.width_p(num_channels_p), .delay_p(tline_delay_p)) bdl1
   (.i(chipset_im_clk_tline_o), .o(asic_io_clk_tline_i));

   bsg_nonsynth_delay_line #(.width_p(num_channels_p), .delay_p(tline_delay_p)) bdl2
   (.i(asic_im_valid_tline_o), .o(chipset_io_valid_tline_i));

   bsg_nonsynth_delay_line #(.width_p(num_channels_p), .delay_p(tline_delay_p)) bdl3
   (.i(chipset_im_valid_tline_o), .o(asic_io_valid_tline_i));

   bsg_nonsynth_delay_line #(.width_p(num_channels_p), .delay_p(tline_delay_p)) bdl4
   (.i(asic_io_token_clk_tline_o), .o(chipset_token_clk_tline_i));

   bsg_nonsynth_delay_line #(.width_p(num_channels_p), .delay_p(tline_delay_p)) bdl5
   (.i(chipset_io_token_clk_tline_o), .o(asic_token_clk_tline_i));

   genvar                     i;

   for (i=0; i < num_channels_p; i++)
     begin: rof
        bsg_nonsynth_delay_line #(.width_p(channel_width_p), .delay_p(tline_delay_p)) bdl6
          (.i(asic_im_data_tline_o[i]), .o(chipset_io_data_tline_i[i]));

        bsg_nonsynth_delay_line #(.width_p(channel_width_p), .delay_p(tline_delay_p)) bdl7
          (.i(chipset_im_data_tline_o[i]), .o(asic_io_data_tline_i[i]));
     end

   bsg_nonsynth_delay_line #(.width_p(1), .delay_p(tline_delay_p)) bdl8
   (.i(chipset_im_slave_reset_tline_r_o), .o(asic_async_reset_i));

   // **************************
   // the ASIC

/*     
   bsg_guts_greendroid_node #(.tile_x_max_p(tile_x_max_p)
                              ,.tile_y_max_p(tile_y_max_p)
                              ,.south_side_only_p(1)
                              )
 */
 

   `BSG_NONSYNTH_MIXIN_MOTHERBOARD_chip_sig

   asic
     (.core_clk_i(asic_core_clk_i)
      , .async_reset_i(asic_async_reset_i)
      , .io_master_clk_i(asic_io_master_clk_i)

      // input from i/o
      , .io_clk_tline_i  (asic_io_clk_tline_i  )       // clk
      , .io_valid_tline_i(asic_io_valid_tline_i)
      , .io_data_tline_i (asic_io_data_tline_i )
      , .io_token_clk_tline_o(asic_io_token_clk_tline_o) // clk

      // out to i/o
      , .im_clk_tline_o   (asic_im_clk_tline_o   )       // clk
      , .im_valid_tline_o (asic_im_valid_tline_o )
      , .im_data_tline_o  (asic_im_data_tline_o  )
      , .token_clk_tline_i(asic_token_clk_tline_i)    // clk

      // note: generate by the master (FPGA) and sent to the slave (ASIC)
      // not used by slave (ASIC).
      , .im_slave_reset_tline_r_o() // unused; fixme remove?

      // this signal is the post-calibration reset signal
      // synchronous to the core clock
      , .core_reset_o(asic_core_reset_o)
      );

endmodule
