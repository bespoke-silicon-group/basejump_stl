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

	function new(string name = "bsg_dmc_base_test", uvm_component parent = null);
    	super.new(name, parent);
  	endfunction

	extern virtual function void build_phase(uvm_phase phase);
	extern virtual task run_phase(uvm_phase phase);

endclass: bsg_dmc_base_test

function void bsg_dmc_base_test::build_phase(uvm_phase phase);
	env = bsg_dmc_env::type_id::create("bsg_dmc_base_test", this);
endfunction

task bsg_dmc_base_test::run_phase(uvm_phase phase)  ;
    phase.raise_objection( this, "Starting DMC test run phase" );
	//uvm_top.print_topology();  	
	
	//Wait for initialisation to complete
	`uvm_info(msg_id, "Starting DMC BASE TEST. Waiting for initialisation to complete", UVM_NONE)
	wait(testbench.init_calib_complete);
	uvm_top.print_topology();
	`uvm_info(msg_id, "Initialisation complete and the DUT is up. Will trigger scenarios now", UVM_NONE)
	
    phase.drop_objection( this , "Finished DMC test run phase" );
endtask		
