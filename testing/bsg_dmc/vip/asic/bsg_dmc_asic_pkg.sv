`include "bsg_dmc_asic_interface.sv"

package bsg_dmc_asic_pkg;
	import uvm_pkg::*;
	import bsg_dmc_pkg::*;
	import bsg_dmc_params_pkg::*;

	typedef  enum {ASIC_CMD, ASIC_WRITE, ASIC_READ} asic_txn_type_t;

	`include "bsg_dmc_asic_transaction.sv"
	`include "bsg_dmc_asic_driver.sv"
	`include "bsg_dmc_asic_monitor.sv"
	`include "bsg_dmc_asic_agent.sv"

endpackage: bsg_dmc_asic_pkg
