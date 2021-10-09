`include "bsg_dmc_asic_interface.sv"

package bsg_dmc_asic_pkg;
	import uvm_pkg::*;
	import bsg_dmc_pkg::*;
	import bsg_dmc_params_pkg::*;

	`include "bsg_dmc_asic_transaction.sv"
	`include "bsg_dmc_asic_agent.sv"
	//`include "bsg_dmc_asic_driver.sv"
	//`include "bsg_dmc_asic_monitor.sv"

endpackage: bsg_dmc_asic_pkg
