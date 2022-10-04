///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_ddr_monitor
//  DESCRIPTION: Monitors signals on the DDR interface for checking command ordering
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 12/24/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_ddr_monitor extends uvm_monitor #(bsg_dmc_ddr_transaction);

	//Register with the factory
	`uvm_component_utils(bsg_dmc_ddr_monitor)

	bsg_dmc_ddr_transaction txn;

	uvm_analysis_port#(bsg_dmc_ddr_transaction) ddr_mon_analysis_port;

	virtual bsg_dmc_ddr_interface 	vif;

	local bit reset_triggered;

	extern virtual function void build_phase(uvm_phase phase);

	extern virtual task check_reset();
	extern virtual task capture_signals();
	extern virtual task run_phase(uvm_phase phase);

	function new(string name, uvm_component parent);
    	super.new(name,parent);
		ddr_mon_analysis_port = new("ddr_mon_analysis_port", this);
  	endfunction

endclass: bsg_dmc_ddr_monitor

function void bsg_dmc_ddr_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info(get_full_name(), "In DDR monitor build_phase", UVM_NONE)

    if(!uvm_config_db#(virtual bsg_dmc_ddr_interface)::get(this,"","ddr_if", vif)) begin
      `uvm_fatal(get_full_name(),"Unable to get DDR virtual interface")
    end
endfunction: build_phase

task bsg_dmc_ddr_monitor::run_phase(uvm_phase phase);

	super.run_phase(phase);

	`uvm_info(get_full_name(), "In DDR monitor run_phase", UVM_NONE)
	
	fork begin
		forever begin
			check_reset();
			capture_signals();
		end
	end
	join_none
endtask: run_phase

task bsg_dmc_ddr_monitor::check_reset();
	//reset is active low. Wait for it to be deasserted.
	if(!reset_triggered) begin
		@(negedge vif.ui_clk_sync_rst);
		reset_triggered = 1;
	end
endtask

task bsg_dmc_ddr_monitor::capture_signals();
	@(negedge vif.ddr_cs_n);
	txn = bsg_dmc_ddr_transaction::type_id::create("txn");
	txn.ddr_ras_n = vif.ddr_ras_n;
	txn.ddr_cas_n = vif.ddr_cas_n;
	txn.ddr_we_n = vif.ddr_we_n;
	txn.ddr_ba = vif.ddr_ba;
	txn.ddr_addr = vif.ddr_addr;
	txn.command = {vif.ddr_ras_n, vif.ddr_cas_n,vif.ddr_we_n };
	`uvm_info(get_full_name(), $sformatf("got cmd %d to addr %h and bank addr %d at DDR monitor", {txn.ddr_ras_n,txn.ddr_cas_n, txn.ddr_we_n}, txn.ddr_addr, txn.ddr_ba), UVM_MEDIUM)

	ddr_mon_analysis_port.write(txn);
endtask
