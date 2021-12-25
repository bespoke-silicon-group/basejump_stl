///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_env
//  DESCRIPTION: Environment component for the DMC testbench: instanciate and connect top TB agents
//       AUTHOR: Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/08/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_env extends uvm_env;

	`uvm_component_utils(bsg_dmc_env)

	bsg_dmc_asic_agent asic_agent;
	bsg_dmc_ddr_monitor ddr_monitor;
	bsg_dmc_scoreboard scoreboard;

	function new(string name, uvm_component parent);
		super.new("bsg_dmc_env", parent);
	endfunction: new

	extern virtual function void build_phase (uvm_phase phase);
	extern virtual function void connect_phase (uvm_phase phase);

endclass: bsg_dmc_env

function void bsg_dmc_env::build_phase(uvm_phase phase);
	asic_agent = bsg_dmc_asic_agent::type_id::create("asic_agent", this);
	ddr_monitor = bsg_dmc_ddr_monitor::type_id::create("ddr_monitor", this);
	scoreboard = bsg_dmc_scoreboard::type_id::create("scoreboard", this);
endfunction : build_phase

function void bsg_dmc_env::connect_phase(uvm_phase phase);
	ddr_monitor.ddr_mon_analysis_port.connect(scoreboard.ddr_imp);
endfunction : connect_phase
