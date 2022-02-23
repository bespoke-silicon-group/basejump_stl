`include "bsg_dmc.vh"

module bsg_dmc
  import bsg_tag_pkg::*;
  import bsg_dmc_pkg::*;
 #(parameter  num_adgs_p         = 1
  ,parameter `BSG_INV_PARAM( ui_addr_width_p    )
  ,parameter `BSG_INV_PARAM( ui_data_width_p    ) // data width of UI interface, can be 2^n while n = [3, log2(burst_data_width_p)]
  ,parameter `BSG_INV_PARAM( burst_data_width_p ) // data width of an outstanding read/write transaction, typically data width of a cache line
  ,parameter `BSG_INV_PARAM( dq_data_width_p    ) // data width of DDR interface, consistent with packaging
  ,parameter `BSG_INV_PARAM( cmd_afifo_depth_p  ) // maximum number of outstanding read/write transactions can be queued when the controller is busy
  ,parameter `BSG_INV_PARAM( cmd_sfifo_depth_p  ) // maximum number of DRAM commands can be queued when the DDR interface is busy, no less than cmd_afifo_depth_p
  ,localparam ui_mask_width_lp   = ui_data_width_p >> 3
  ,localparam dfi_data_width_lp  = dq_data_width_p << 1
  ,localparam dfi_mask_width_lp  = (dq_data_width_p >> 3) << 1
  ,localparam dq_group_lp        = dq_data_width_p >> 3)
  // Tag lines
  (
  output logic						 refresh_in_progress_o
  ,input bsg_dmc_tag_lines_s 	     tag_lines_i
  , output							 clock_monitor_clk_o
  // Global asynchronous reset input, will be synchronized to each clock domain
  // Consistent with the reset signal defined in Xilinx UI interface
  // User interface signals
  ,input       [ui_addr_width_p-1:0] app_addr_i
  ,input app_cmd_e                   app_cmd_i
  ,input                             app_en_i
  ,output                            app_rdy_o
  ,input                             app_wdf_wren_i
  ,input       [ui_data_width_p-1:0] app_wdf_data_i
  ,input      [ui_mask_width_lp-1:0] app_wdf_mask_i
  ,input                             app_wdf_end_i
  ,output                            app_wdf_rdy_o
  ,output                            app_rd_data_valid_o
  ,output      [ui_data_width_p-1:0] app_rd_data_o
  ,output                            app_rd_data_end_o
  // Reserved to be compatible with Xilinx IPs
  ,input                             app_ref_req_i
  ,output                            app_ref_ack_o
  ,input                             app_zq_req_i
  ,output                            app_zq_ack_o
  ,input                             app_sr_req_i
  ,output                            app_sr_active_o
  // Status signal
  ,output                            init_calib_complete_o
  // DDR interface signals
  // Physically compatible with (LP)DDR3/DDR2/DDR, but only (LP)DDR
  // protocal is logically implemented in the controller
  // Command and Address interface
  ,output                            ddr_ck_p_o
  ,output                            ddr_ck_n_o
  ,output                            ddr_cke_o
  ,output                      [2:0] ddr_ba_o
  ,output                     [15:0] ddr_addr_o
  ,output                            ddr_cs_n_o
  ,output                            ddr_ras_n_o
  ,output                            ddr_cas_n_o
  ,output                            ddr_we_n_o
  ,output                            ddr_reset_n_o
  ,output                            ddr_odt_o
  // Data interface
  ,output          [dq_group_lp-1:0] ddr_dm_oen_o
  ,output          [dq_group_lp-1:0] ddr_dm_o
  ,output          [dq_group_lp-1:0] ddr_dqs_p_oen_o
  ,output          [dq_group_lp-1:0] ddr_dqs_p_ien_o
  ,output          [dq_group_lp-1:0] ddr_dqs_p_o
  ,input           [dq_group_lp-1:0] ddr_dqs_p_i
  ,output          [dq_group_lp-1:0] ddr_dqs_n_oen_o
  ,output          [dq_group_lp-1:0] ddr_dqs_n_ien_o
  ,output          [dq_group_lp-1:0] ddr_dqs_n_o
  ,input           [dq_group_lp-1:0] ddr_dqs_n_i
  ,output      [dq_data_width_p-1:0] ddr_dq_oen_o
  ,output      [dq_data_width_p-1:0] ddr_dq_o
  ,input       [dq_data_width_p-1:0] ddr_dq_i
  // Clock interface signals
  ,input                             ui_clk_i
  //
  ,output                            ui_clk_sync_rst_o
  ,output                            dfi_clk_2x_o
  ,output                            dfi_clk_1x_o
  // Reserved to be compatible with Xilinx IPs
  ,output                     [11:0] device_temp_o
);

  wire                               dfi_clk_1x_lo;
  logic								 sys_reset_lo;
  logic								 dfi_clk_2x_lo;

  wire                               sys_reset;
  wire                               ui_reset;
  wire                               dfi_reset;

  // DFI 1.0 compatible
  wire                         [2:0] dfi_bank;
  wire                        [15:0] dfi_address;
  wire                               dfi_cke;
  wire                               dfi_cs_n;
  wire                               dfi_ras_n;
  wire                               dfi_cas_n;
  wire                               dfi_we_n;
  wire                               dfi_reset_n;
  wire                               dfi_odt;
  wire                               dfi_wrdata_en;
  wire       [dfi_data_width_lp-1:0] dfi_wrdata;
  wire       [dfi_mask_width_lp-1:0] dfi_wrdata_mask;
  wire                               dfi_rddata_en;
  wire       [dfi_data_width_lp-1:0] dfi_rddata;
  wire                               dfi_rddata_valid;

  wire             [dq_group_lp-1:0] dqs_p_li;

  bsg_dmc_s 						 dmc_p_lo;
  assign device_temp_o = 12'd0;

  bsg_dmc_delay_tag_lines_s dmc_delay_tag_lines_s_lo;
  bsg_dmc_clk_gen_tag_lines_s clk_gen_tag_lines_lo;

  logic stall_transmission_lo;

  assign dfi_clk_2x_o = dfi_clk_2x_lo;
  assign dfi_clk_1x_o = dfi_clk_1x_lo;

  
  bsg_dmc_tag_clients
					#(.dq_group_p(dq_group_lp)
					)
					dmc_tag_clients
					(
                        //.tag_lines_i(tag_lines_i)
                    .cfg_tag_lines_i(tag_lines_i.cfg_tag_lines)
					,.ext_clk_i(ui_clk_i)
					,.dfi_clk_1x_i(dfi_clk_1x_lo)
					,.ui_clk_sync_rst_i(ui_clk_sync_rst_o)
					,.dmc_p_o(dmc_p_lo)
					,.sys_reset_o(sys_reset_lo)
					,.stall_transmission_o(stall_transmission_lo)
					);
					 
  bsg_dmc_clk_rst_gen #
    (.num_adgs_p  ( num_adgs_p  )
    ,.num_lines_p ( dq_group_lp ))
  dmc_clk_rst_gen
    // tag lines
    (
    .async_reset_o         ( sys_reset             )
    ,.bsg_dmc_delay_tag_lines_s_i ( tag_lines_i.delay_tag_lines )
    ,.clk_gen_tag_lines_i   ( tag_lines_i.clk_gen_tag_lines)
    ,.clk_i                 ( ddr_dqs_p_i           )
    ,.clk_o                 ( dqs_p_li              )
    ,.dfi_clk_2x_o          ( dfi_clk_2x_lo         )
    ,.clk_1x_o              ( dfi_clk_1x_lo         )
	,.clock_monitor_clk_o	(clock_monitor_clk_o));

  bsg_sync_sync #(.width_p(1)) ui_reset_inst
    (.oclk_i      ( ui_clk_i    )
    ,.iclk_data_i ( sys_reset_lo )
    ,.oclk_data_o ( ui_reset    ));

  bsg_sync_sync #(.width_p(1)) dfi_reset_inst
    (.oclk_i      ( dfi_clk_1x_lo   )
    ,.iclk_data_i ( sys_reset_lo    )
    ,.oclk_data_o ( dfi_reset       ));

  assign ui_clk_sync_rst_o = ui_reset;

  bsg_dmc_controller #
    (.ui_addr_width_p       ( ui_addr_width_p       )
    ,.ui_data_width_p       ( ui_data_width_p       )
    ,.burst_data_width_p    ( burst_data_width_p    )
    ,.dfi_data_width_p      ( dfi_data_width_lp     )
    ,.cmd_afifo_depth_p     ( cmd_afifo_depth_p     )
    ,.cmd_sfifo_depth_p     ( cmd_sfifo_depth_p     ))
  controller
    // User interface clock and reset
    (.ui_clk_i              ( ui_clk_i              )
    ,.ui_clk_sync_rst_i     ( ui_reset              )
	,.stall_transmission_i  (stall_transmission_lo  )
	,.refresh_in_progress_o (refresh_in_progress_o  )
    // User interface signals
    ,.app_addr_i            ( app_addr_i            )
    ,.app_cmd_i             ( app_cmd_i             )
    ,.app_en_i              ( app_en_i              )
    ,.app_rdy_o             ( app_rdy_o             )
    ,.app_wdf_wren_i        ( app_wdf_wren_i        )
    ,.app_wdf_data_i        ( app_wdf_data_i        )
    ,.app_wdf_mask_i        ( app_wdf_mask_i        )
    ,.app_wdf_end_i         ( app_wdf_end_i         )
    ,.app_wdf_rdy_o         ( app_wdf_rdy_o         )
    ,.app_rd_data_valid_o   ( app_rd_data_valid_o   )
    ,.app_rd_data_o         ( app_rd_data_o         )
    ,.app_rd_data_end_o     ( app_rd_data_end_o     )
    ,.app_ref_req_i         ( app_ref_req_i         )
    ,.app_ref_ack_o         ( app_ref_ack_o         )
    ,.app_zq_req_i          ( app_zq_req_i          )
    ,.app_zq_ack_o          ( app_zq_ack_o          )
    ,.app_sr_req_i          ( app_sr_req_i          )
    ,.app_sr_active_o       ( app_sr_active_o       )
    // DDR PHY interface clock and reset
    ,.dfi_clk_i             ( dfi_clk_1x_lo         )
    ,.dfi_clk_sync_rst_i    ( dfi_reset             )
    // DDR PHY interface signals
    ,.dfi_bank_o            ( dfi_bank              )
    ,.dfi_address_o         ( dfi_address           )
    ,.dfi_cke_o             ( dfi_cke               )
    ,.dfi_cs_n_o            ( dfi_cs_n              )
    ,.dfi_ras_n_o           ( dfi_ras_n             )
    ,.dfi_cas_n_o           ( dfi_cas_n             )
    ,.dfi_we_n_o            ( dfi_we_n              )
    ,.dfi_reset_n_o         ( dfi_reset_n           )
    ,.dfi_odt_o             ( dfi_odt               )
    ,.dfi_wrdata_en_o       ( dfi_wrdata_en         )
    ,.dfi_wrdata_o          ( dfi_wrdata            )
    ,.dfi_wrdata_mask_o     ( dfi_wrdata_mask       )
    ,.dfi_rddata_en_o       ( dfi_rddata_en         )
    ,.dfi_rddata_i          ( dfi_rddata            )
    ,.dfi_rddata_valid_i    ( dfi_rddata_valid      )
    // Control and Status Registers
    ,.dmc_p_i               ( dmc_p_lo               )
    //
    ,.init_calib_complete_o ( init_calib_complete_o ));

  bsg_dmc_phy #(.dq_data_width_p(dq_data_width_p)) phy
    // DDR PHY interface clock and reset
    (.dfi_clk_1x_i        ( dfi_clk_1x_lo       )
    ,.dfi_clk_2x_i        ( dfi_clk_2x_lo        )
    ,.dfi_rst_i           ( dfi_reset           )
    // DFI interface signals
    ,.dfi_bank_i          ( dfi_bank            )
    ,.dfi_address_i       ( dfi_address         )
    ,.dfi_cke_i           ( dfi_cke             )
    ,.dfi_cs_n_i          ( dfi_cs_n            )
    ,.dfi_ras_n_i         ( dfi_ras_n           )
    ,.dfi_cas_n_i         ( dfi_cas_n           )
    ,.dfi_we_n_i          ( dfi_we_n            )
    ,.dfi_reset_n_i       ( dfi_reset_n         )
    ,.dfi_odt_i           ( dfi_odt             )
    ,.dfi_wrdata_en_i     ( dfi_wrdata_en       )
    ,.dfi_wrdata_i        ( dfi_wrdata          )
    ,.dfi_wrdata_mask_i   ( dfi_wrdata_mask     )
    ,.dfi_rddata_en_i     ( dfi_rddata_en       )
    ,.dfi_rddata_o        ( dfi_rddata          )
    ,.dfi_rddata_valid_o  ( dfi_rddata_valid    )
    // DDR interface signals
    ,.ck_p_o              ( ddr_ck_p_o          )
    ,.ck_n_o              ( ddr_ck_n_o          )
    ,.cke_o               ( ddr_cke_o           )
    ,.ba_o                ( ddr_ba_o            )
    ,.a_o                 ( ddr_addr_o          )
    ,.cs_n_o              ( ddr_cs_n_o          )
    ,.ras_n_o             ( ddr_ras_n_o         )
    ,.cas_n_o             ( ddr_cas_n_o         )
    ,.we_n_o              ( ddr_we_n_o          )
    ,.reset_o             ( ddr_reset_n_o       )
    ,.odt_o               ( ddr_odt_o           )
    ,.dm_oe_n_o           ( ddr_dm_oen_o        )
    ,.dm_o                ( ddr_dm_o            )
    ,.dqs_p_oe_n_o        ( ddr_dqs_p_oen_o     )
    ,.dqs_p_ie_n_o        ( ddr_dqs_p_ien_o     )
    ,.dqs_p_o             ( ddr_dqs_p_o         )
    ,.dqs_p_i             ( dqs_p_li            )
    ,.dqs_n_oe_n_o        ( ddr_dqs_n_oen_o     )
    ,.dqs_n_ie_n_o        ( ddr_dqs_n_ien_o     )
    ,.dqs_n_o             ( ddr_dqs_n_o         )
    ,.dqs_n_i             ( ~dqs_p_li           )
    ,.dq_oe_n_o           ( ddr_dq_oen_o        )
    ,.dq_o                ( ddr_dq_o            )
    ,.dq_i                ( ddr_dq_i            )
    // Control and Status Registers
    ,.dqs_sel_cal         ( dmc_p_lo.dqs_sel_cal ));

endmodule

`BSG_ABSTRACT_MODULE(bsg_dmc)
