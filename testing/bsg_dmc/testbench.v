module testbench();
  import bsg_tag_pkg::*;
  import bsg_dmc_pkg::*;
 
  parameter clk_gen_num_adgs_p = 1;
  parameter ui_addr_width_p    = 28;
  parameter ui_data_width_p    = 32;
`ifndef BRINGUP
  parameter ui_burst_length_p  = 8;
`else
  parameter ui_burst_length_p  = 2;
`endif
  parameter dq_data_width_p    = 32;
  parameter cmd_afifo_depth_p  = 4;
  parameter cmd_sfifo_depth_p  = 4;
  parameter debug_p            = 1'b1;

  localparam burst_data_width_lp = ui_data_width_p * ui_burst_length_p;
  localparam ui_mask_width_lp    = ui_data_width_p >> 3;
  localparam dq_group_lp         = dq_data_width_p >> 3;
  localparam dq_burst_length_lp  = burst_data_width_lp / dq_data_width_p;

  genvar i;

  integer j,k;

  wire bsg_tag_s        dmc_reset_tag_lines;
  wire bsg_tag_s  [3:0] dmc_dly_tag_lines;
  wire bsg_tag_s  [3:0] dmc_dly_trigger_tag_lines;
  wire bsg_tag_s        dmc_ds_tag_lines;

  bsg_dmc_s                        dmc_p;

  logic 						   stall_transmission_li;
  logic							   refresh_in_progress_lo;

  logic                            sys_reset;
  // User interface signals
  logic      [ui_addr_width_p-1:0] app_addr;
  app_cmd_e                        app_cmd;
  logic                            app_en;
  wire                             app_rdy;
  logic                            app_wdf_wren;
  logic      [ui_data_width_p-1:0] app_wdf_data;
  logic [(ui_data_width_p>>3)-1:0] app_wdf_mask;
  logic                            app_wdf_end;
  wire                             app_wdf_rdy;

  wire                             app_rd_data_valid;
  wire       [ui_data_width_p-1:0] app_rd_data;
  wire                             app_rd_data_end;

  wire                             app_ref_req;
  wire                             app_ref_ack;
  wire                             app_zq_req;
  wire                             app_zq_ack;
  wire                             app_sr_req;
  wire                             app_sr_active;
  // Status signal
  wire                             init_calib_complete;

  logic                            ui_clk;
  logic                            dfi_clk_2x;
  wire                             dfi_clk_1x;
  wire                             ui_clk_sync_rst;

  wire                      [11:0] device_temp;

  wire                             ddr_ck_p, ddr_ck_n;
  wire                             ddr_cke;
  wire                             ddr_cs_n;
  wire                             ddr_ras_n;
  wire                             ddr_cas_n;
  wire                             ddr_we_n;
  wire                       [2:0] ddr_ba;
  wire                      [15:0] ddr_addr;

  wire                             ddr_reset_n;
  wire                             ddr_odt;

  wire  [(dq_data_width_p>>3)-1:0] ddr_dm_oen_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dm_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_oen_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_ien_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p_li;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_oen_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_ien_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_lo;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n_li;
  wire       [dq_data_width_p-1:0] ddr_dq_oen_lo;
  wire       [dq_data_width_p-1:0] ddr_dq_lo;
  wire       [dq_data_width_p-1:0] ddr_dq_li;
  
  wire  [(dq_data_width_p>>3)-1:0] ddr_dm;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_p;
  wire  [(dq_data_width_p>>3)-1:0] ddr_dqs_n;
  wire       [dq_data_width_p-1:0] ddr_dq;

  // All tag lines from the btm
  bsg_tag_s [22:0] tag_lines_lo;

  traffic_generator #
    (.num_adgs_p         ( clk_gen_num_adgs_p  )
    ,.ui_addr_width_p    ( ui_addr_width_p     )
    ,.ui_data_width_p    ( ui_data_width_p     )
    ,.burst_data_width_p ( burst_data_width_lp )
    ,.dq_data_width_p    ( dq_data_width_p     )
    ,.cmd_afifo_depth_p  ( cmd_afifo_depth_p   )
    ,.cmd_sfifo_depth_p  ( cmd_sfifo_depth_p   ))
    // Tag lines
  traffic_generator_inst
    // Global asynchronous reset input, will be synchronized to each clock domain
    // Consistent with the reset signal defined in Xilinx UI interface
    // User interface signals
    (.app_addr_o            ( app_addr            )
    ,.app_cmd_o             ( app_cmd             )
    ,.app_en_o              ( app_en              )
    ,.app_rdy_i             ( app_rdy             )
    ,.app_wdf_wren_o        ( app_wdf_wren        )
    ,.app_wdf_data_o        ( app_wdf_data        )
    ,.app_wdf_mask_o        ( app_wdf_mask        )
    ,.app_wdf_end_o         ( app_wdf_end         )
    ,.app_wdf_rdy_i         ( app_wdf_rdy         )
    ,.app_rd_data_valid_i   ( app_rd_data_valid   )
    ,.app_rd_data_i         ( app_rd_data         )
    ,.app_rd_data_end_i     ( app_rd_data_end     )
    // Reserved to be compatible with Xilinx IPs
    ,.app_ref_req_o         ( app_ref_req         )
    ,.app_ref_ack_i         ( app_ref_ack         )
    ,.app_zq_req_o          ( app_zq_req          )
    ,.app_zq_ack_i          ( app_zq_ack          )
    ,.app_sr_req_o          ( app_sr_req          )
    ,.app_sr_active_i       ( app_sr_active       )
    // Status signal
    ,.init_calib_complete_i ( init_calib_complete )
    //
    ,.ui_clk_o              ( ui_clk              )
    ,.dfi_clk_2x_o          ( dfi_clk_2x          )
    //
    ,.ui_clk_sync_rst_i     ( ui_clk_sync_rst     )
	,.tag_lines_o			(tag_lines_lo)
	,.stall_trace_reading_i (stall_transmission_li));

 // Tag payload for bsg_dmc control signals
  logic [12:0][7:0] 	dmc_cfg_tag_data_lo;
  logic [12:0]      	dmc_cfg_tag_new_data_lo;
  logic 				dmc_reset_tag_lines;

  assign dmc_reset_tag_lines	   = tag_lines_lo[0];
  assign dmc_dly_tag_lines         = tag_lines_lo[1+:dq_group_lp];
  assign dmc_dly_trigger_tag_lines = tag_lines_lo[1+dq_group_lp+:4];
  assign dmc_ds_tag_lines          = tag_lines_lo[1+2*dq_group_lp];

  wire bsg_tag_s [12:0] dmc_cfg_tag_lines_lo = tag_lines_lo[2+2*dq_group_lp+:13];

  genvar idx;
  generate
    for(idx=0;idx<13;idx++) begin: dmc_cfg
      bsg_tag_client #(.width_p( 8 ))
        btc
          (.bsg_tag_i     ( dmc_cfg_tag_lines_lo[idx] )
          ,.recv_clk_i    ( dfi_clk_1x )
          ,.recv_new_r_o  ( dmc_cfg_tag_new_data_lo[idx] )
          ,.recv_data_r_o ( dmc_cfg_tag_data_lo[idx] )
          );
    end
  endgenerate

  assign dmc_p.trefi        	= {dmc_cfg_tag_data_lo[1], dmc_cfg_tag_data_lo[0]};
  assign dmc_p.tmrd         	= dmc_cfg_tag_data_lo[2][3:0];
  assign dmc_p.trfc         	= dmc_cfg_tag_data_lo[2][7:4];
  assign dmc_p.trc          	= dmc_cfg_tag_data_lo[3][3:0];
  assign dmc_p.trp          	= dmc_cfg_tag_data_lo[3][7:4];
  assign dmc_p.tras         	= dmc_cfg_tag_data_lo[4][3:0];
  assign dmc_p.trrd         	= dmc_cfg_tag_data_lo[4][7:4];
  assign dmc_p.trcd         	= dmc_cfg_tag_data_lo[5][3:0];
  assign dmc_p.twr          	= dmc_cfg_tag_data_lo[5][7:4];
  assign dmc_p.twtr         	= dmc_cfg_tag_data_lo[6][3:0];
  assign dmc_p.trtp         	= dmc_cfg_tag_data_lo[6][7:4];
  assign dmc_p.tcas         	= dmc_cfg_tag_data_lo[7][3:0];
  assign dmc_p.col_width    	= dmc_cfg_tag_data_lo[8][3:0];
  assign dmc_p.row_width    	= dmc_cfg_tag_data_lo[8][7:4];
  assign dmc_p.bank_width   	= dmc_cfg_tag_data_lo[9][1:0];
  assign dmc_p.bank_pos     	= dmc_cfg_tag_data_lo[9][7:2];
  assign dmc_p.dqs_sel_cal  	= dmc_cfg_tag_data_lo[7][6:4];
  assign dmc_p.init_cycles  	= {dmc_cfg_tag_data_lo[11], dmc_cfg_tag_data_lo[10]};
  assign sys_reset          	= dmc_cfg_tag_data_lo[12][0];

  //always @(posedge dfi_clk_1x) begin
  //    	if(ui_clk_sync_rst) begin
  //  	  	stall_transmission_li <= 0;
  //    	end
  //    	else if(dmc_cfg_tag_new_data_lo[13]) begin
  //  		stall_transmission_li <= dmc_cfg_tag_data_lo[13][0];
  //  	end
  //end

  bsg_dmc #
    (.num_adgs_p            ( clk_gen_num_adgs_p  )
    ,.ui_addr_width_p       ( ui_addr_width_p     )
    ,.ui_data_width_p       ( ui_data_width_p     )
    ,.burst_data_width_p    ( burst_data_width_lp )
    ,.dq_data_width_p       ( dq_data_width_p     )
    ,.cmd_afifo_depth_p     ( cmd_afifo_depth_p   )
    ,.cmd_sfifo_depth_p     ( cmd_sfifo_depth_p   ))
  dmc_inst
    (.async_reset_tag_i     ( dmc_reset_tag_lines       )
    ,.bsg_dly_tag_i         ( dmc_dly_tag_lines         )
    ,.bsg_dly_trigger_tag_i ( dmc_dly_trigger_tag_lines )
    ,.bsg_ds_tag_i          ( dmc_ds_tag_lines          )

	,.stall_transmission_i  (stall_transmission_li )
	,.refresh_in_progress_o (refresh_in_progress_lo)

    ,.dmc_p_i               ( dmc_p               )

    ,.sys_reset_i           ( sys_reset           )

    ,.app_addr_i            ( app_addr            )
    ,.app_cmd_i             ( app_cmd             )
    ,.app_en_i              ( app_en              )
    ,.app_rdy_o             ( app_rdy             )
    ,.app_wdf_wren_i        ( app_wdf_wren        )
    ,.app_wdf_data_i        ( app_wdf_data        )
    ,.app_wdf_mask_i        ( app_wdf_mask        )
    ,.app_wdf_end_i         ( app_wdf_end         )
    ,.app_wdf_rdy_o         ( app_wdf_rdy         )
    ,.app_rd_data_valid_o   ( app_rd_data_valid   )
    ,.app_rd_data_o         ( app_rd_data         )
    ,.app_rd_data_end_o     ( app_rd_data_end     )
    ,.app_ref_req_i         ( app_ref_req         )
    ,.app_ref_ack_o         ( app_ref_ack         )
    ,.app_zq_req_i          ( app_zq_req          )
    ,.app_zq_ack_o          ( app_zq_ack          )
    ,.app_sr_req_i          ( app_sr_req          )
    ,.app_sr_active_o       ( app_sr_active       )

    ,.init_calib_complete_o ( init_calib_complete )

    ,.ddr_ck_p_o            ( ddr_ck_p            )
    ,.ddr_ck_n_o            ( ddr_ck_n            )
    ,.ddr_cke_o             ( ddr_cke             )
    ,.ddr_ba_o              ( ddr_ba              )
    ,.ddr_addr_o            ( ddr_addr            )
    ,.ddr_cs_n_o            ( ddr_cs_n            )
    ,.ddr_ras_n_o           ( ddr_ras_n           )
    ,.ddr_cas_n_o           ( ddr_cas_n           )
    ,.ddr_we_n_o            ( ddr_we_n            )
    ,.ddr_reset_n_o         ( ddr_reset_n         )
    ,.ddr_odt_o             ( ddr_odt             )

    ,.ddr_dm_oen_o          ( ddr_dm_oen_lo       )
    ,.ddr_dm_o              ( ddr_dm_lo           )
    ,.ddr_dqs_p_oen_o       ( ddr_dqs_p_oen_lo    )
    ,.ddr_dqs_p_ien_o       ( ddr_dqs_p_ien_lo    )
    ,.ddr_dqs_p_o           ( ddr_dqs_p_lo        )
    ,.ddr_dqs_p_i           ( ddr_dqs_p_li        )
    ,.ddr_dqs_n_oen_o       ( ddr_dqs_n_oen_lo    )
    ,.ddr_dqs_n_ien_o       ( ddr_dqs_n_ien_lo    )
    ,.ddr_dqs_n_o           ( ddr_dqs_n_lo        )
    ,.ddr_dqs_n_i           ( ddr_dqs_n_li        )
    ,.ddr_dq_oen_o          ( ddr_dq_oen_lo       )
    ,.ddr_dq_o              ( ddr_dq_lo           )
    ,.ddr_dq_i              ( ddr_dq_li           )

    ,.ui_clk_i              ( ui_clk              )
    ,.dfi_clk_2x_i          ( dfi_clk_2x          )
    ,.dfi_clk_1x_o          ( dfi_clk_1x          )
    ,.ui_clk_sync_rst_o     ( ui_clk_sync_rst     )
    ,.device_temp_o         ( device_temp         ));

  generate
    for(i=0;i<dq_group_lp;i++) begin: dm_io
      assign ddr_dm[i]       = !ddr_dm_oen_lo[i]? ddr_dm_lo[i]: 1'bz;
    end
    for(i=0;i<dq_group_lp;i++) begin: dqs_io
      assign ddr_dqs_p[i]    = !ddr_dqs_p_oen_lo[i]? ddr_dqs_p_lo[i]: 1'bz;
      assign ddr_dqs_p_li[i] = !ddr_dqs_p_ien_lo[i]? ddr_dqs_p[i]: 1'b0;
      assign ddr_dqs_n[i]    = !ddr_dqs_n_oen_lo[i]? ddr_dqs_n_lo[i]: 1'bz;
      assign ddr_dqs_n_li[i] = !ddr_dqs_n_ien_lo[i]? ddr_dqs_n[i]: 1'b1;
    end
    for(i=0;i<dq_data_width_p;i++) begin: dq_io
      assign ddr_dq[i]    = !ddr_dq_oen_lo[i]? ddr_dq_lo[i]: 1'bz;
      assign ddr_dq_li[i] = ddr_dq[i];
    end
  endgenerate

  generate
    for(i=0;i<2;i++) begin: lpddr
      mobile_ddr mobile_ddr_inst
        (.Dq    (ddr_dq[16*i+15:16*i])
        ,.Dqs   (ddr_dqs_p[2*i+1:2*i])
        ,.Addr  (ddr_addr[13:0])
        ,.Ba    (ddr_ba[1:0])
        ,.Clk   (ddr_ck_p)
        ,.Clk_n (ddr_ck_n)
        ,.Cke   (ddr_cke)
        ,.Cs_n  (ddr_cs_n)
        ,.Ras_n (ddr_ras_n)
        ,.Cas_n (ddr_cas_n)
        ,.We_n  (ddr_we_n)
        ,.Dm    (ddr_dm[2*i+1:2*i]));
    end
  endgenerate

endmodule
