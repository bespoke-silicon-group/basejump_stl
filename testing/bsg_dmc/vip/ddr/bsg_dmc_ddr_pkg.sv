`include "bsg_dmc_ddr_interface.sv"

package bsg_dmc_ddr_pkg;
	import uvm_pkg::*;
	import bsg_dmc_pkg::*;
	import bsg_dmc_params_pkg::*;

	`include "bsg_dmc_ddr_transaction.sv"
	`include "bsg_dmc_ddr_monitor.sv";
endpackage
