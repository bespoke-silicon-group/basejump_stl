///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_dfi_monitor
//  DESCRIPTION: monitor for the interface between DMC controller and DMC DFI modules.
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 11/02/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_dfi_monitor extends uvm_monitor #(bsg_dmc_dfi_transaction);
	//Register with the factory
	`uvm_component_utils(bsg_dmc_dfi_monitor)

	bsg_dmc_dfi_transaction txn;

	uvm_analysis_port#(bsg_dmc_dfi_transaction) dfi_mon_analysis_port;

	virtual bsg_dmc_dfi_interface 	vif;

	local bit reset_triggered;

	extern virtual function void build_phase(uvm_phase phase);

	extern virtual task check_reset();
	extern virtual task capture_signals();
	extern virtual task run_phase(uvm_phase phase);

	function new(string name, uvm_component parent);
    	super.new(name,parent);
  	endfunction

endclass: bsg_dmc_dfi_monitor

function void bsg_dmc_asic_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info(get_full_name(), "In ASIC monitor build_phase", UVM_NONE)

    if(!uvm_config_db#(virtual bsg_dmc_asic_interface)::get(this,"","asic_if", vif)) begin
      `uvm_fatal(get_full_name(),"Unable to get ASIC virtual interface")
    end
endfunction: build_phase

task bsg_dmc_asic_monitor::run_phase(uvm_phase phase);

	super.run_phase(phase);

	`uvm_info(get_full_name(), "In DFI monitor run_phase", UVM_NONE)
	
	fork begin
		forever begin
			check_reset();
			capture_signals();
		end
	end
	join_none
endtask: run_phase

task bsg_dmc_asic_monitor::check_reset();
	//reset is active low. Wait for it to be deasserted.
	if(!reset_triggered) begin
		@(negedge vif.);
		reset_triggered = 1;
	end
endtask

