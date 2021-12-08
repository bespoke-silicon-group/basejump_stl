///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_base_test
//  DESCRIPTION: Test to instanciate TB environment and call out sequences
//       AUTHOR: Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/08/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_base_test extends uvm_test;

	//Register with factory
  	`uvm_component_utils(bsg_dmc_base_test);
	`bsg_log_utils("TEST/BASE")

	bsg_dmc_env env;

	local bit [ui_addr_width_p - 1 : 0] addr;
	local bit rand_addr=1;
	local string scenario="write";
	local int unsigned read_write_iter = 1;

	function new(string name = "bsg_dmc_base_test", uvm_component parent = null);
    	super.new(name, parent);
  	endfunction

	extern virtual function read_plusargs();
	extern virtual function void build_phase(uvm_phase phase);

	extern virtual task run_phase(uvm_phase phase);

endclass: bsg_dmc_base_test

function void bsg_dmc_base_test::build_phase(uvm_phase phase);
	env = bsg_dmc_env::type_id::create("bsg_dmc_base_test", this);
endfunction

task bsg_dmc_base_test::run_phase(uvm_phase phase);
	bsg_dmc_top_seq top_seq;

    phase.raise_objection( this, "Starting DMC test run phase" );
	
	//Wait for initialisation to complete
	`uvm_info(msg_id, "Starting DMC BASE TEST. Waiting for initialisation to complete", UVM_NONE)
	wait(testbench.init_calib_complete);
	uvm_top.print_topology();
	`uvm_info(msg_id, "Initialisation complete and the DUT is up. Will trigger scenarios now", UVM_NONE)
	read_plusargs();

	top_seq = bsg_dmc_top_seq::type_id::create("top_seq");
	top_seq.rand_addr = rand_addr;
	top_seq.set_addr(addr);
	top_seq.scenario = scenario;
	top_seq.read_write_iter = read_write_iter;
	top_seq.sqr = env.asic_agent.asic_sequencer;
	top_seq.set_addr_params(.row_width(testbench.dmc_p.row_width), .col_width(testbench.dmc_p.col_width), .bank_width(testbench.dmc_p.bank_width));
	top_seq.start(null);

    phase.drop_objection( this , "Finished DMC test run phase" );
endtask

function bsg_dmc_base_test::read_plusargs();
	if($value$plusargs("addr=%d", addr)) begin
		rand_addr = 0;
		`uvm_info(get_full_name(), $sformatf("Plusarg received: addr= %d", addr), UVM_MEDIUM)
	end

	if($value$plusargs("scenario=%s", scenario)) begin
		`uvm_info(get_full_name(), $sformatf("Plusarg received: Scenario= %s", scenario), UVM_MEDIUM)
	end
	if($value$plusargs("read_write_iter=%d", read_write_iter)) begin
		`uvm_info(get_full_name(), $sformatf("Plusarg received: number of read/writes= %d", read_write_iter ), UVM_MEDIUM)
	end
endfunction
