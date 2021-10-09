///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_dmc_asic_interface
//  DESCRIPTION: 
//       AUTHOR: Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/08/21
///////////////////////////////////////////////////////////////////////////////////////////////////

interface bsg_dmc_asic_interface;
	
	import bsg_dmc_pkg::*;
	import bsg_dmc_params_pkg::*;

	logic ui_clk;
	logic ui_clk_sync_rst;

	// Config interface paremeters
	bsg_dmc_s bsg_dmc_config_s;

	//Data interface signals	
	logic      [ui_addr_width_p-1:0] app_addr;
  	app_cmd_e                        app_cmd;
  	logic                            app_en;
  	logic                            app_rdy;
  	logic                            app_wdf_wren;
  	logic      [ui_data_width_p-1:0] app_wdf_data;
  	logic [(ui_data_width_p>>3)-1:0] app_wdf_mask;
  	logic                            app_wdf_end;
  	logic                            app_wdf_rdy;

  	logic                            app_rd_data_valid;
  	logic       [ui_data_width_p-1:0]app_rd_data;
  	logic                            app_rd_data_end;

  	logic                            app_ref_req;
  	logic                            app_ref_ack;
  	logic                            app_zq_req;
  	logic                            app_zq_ack;
  	logic                            app_sr_req;
  	logic                            app_sr_active;
endinterface : bsg_dmc_asic_interface
