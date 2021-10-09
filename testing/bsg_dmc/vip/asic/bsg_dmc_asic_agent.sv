///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_asic_agent
//  DESCRIPTION: ASIC agent class that drives and monitors ASIC - DMC interface
//       AUTHOR: Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/08/21
///////////////////////////////////////////////////////////////////////////////////////////////////

//We don't customise anything other than the transction packet class in sequencer. So we are not extending the uvm_sequencer class, just parameterising it.
typedef uvm_sequencer#(bsg_dmc_asic_transaction) bsg_dmc_asic_sequencer;

class bsg_dmc_asic_agent extends uvm_agent;
		
	//Register with factory
  	`uvm_component_utils(bsg_dmc_asic_agent);

	//bsg_dmc_asic_driver asic_driver;
	bsg_dmc_asic_sequencer asic_sequencer;
	//bsg_dmc_asic_monitor asic_monitor;
	
	function new(string name = "bsg_dmc_asic_agent", uvm_component parent = null);
    	super.new(name, parent);
  	endfunction

	extern virtual function void build_phase (uvm_phase phase);
	extern virtual function void connect_phase (uvm_phase phase);

endclass: bsg_dmc_asic_agent

function void bsg_dmc_asic_agent::build_phase (uvm_phase phase);

	//asic_driver = bsg_dmc_asic_driver::type_id::create("asic_driver", this);
	asic_sequencer = bsg_dmc_asic_sequencer::type_id::create("asic_sequencer", this);

endfunction

function void bsg_dmc_asic_agent::connect_phase (uvm_phase phase);
	//Connect sequencer to driver for transmitting transaction packets.
    //asic_driver.seq_item_port.connect(asic_sequencer.seq_item_export);
	
endfunction
