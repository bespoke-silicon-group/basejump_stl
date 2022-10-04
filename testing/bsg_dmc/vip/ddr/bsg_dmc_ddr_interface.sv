interface bsg_dmc_ddr_interface;
	import bsg_dmc_pkg::*;
	import bsg_dmc_params_pkg::*;

	logic     [dq_data_width_p-1:0]  		ddr_dq;
	logic     [(dq_data_width_p>>3)-1:0] 	ddr_dqs_p;
	logic     [15:0]						ddr_addr;
	logic     [2:0] 						ddr_ba;
	logic     								ddr_ck_p;
	logic     								ddr_ck_n;
	logic     								ddr_cke;
	logic     								ddr_cs_n;
	logic     								ddr_ras_n;
	logic     								ddr_cas_n;
	logic     								ddr_we_n;
	logic     [(dq_data_width_p>>3)-1:0] 	ddr_dm;
	logic									ui_clk_sync_rst;
endinterface
