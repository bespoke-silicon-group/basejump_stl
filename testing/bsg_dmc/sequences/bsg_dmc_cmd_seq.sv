///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_cmd_seq
//  DESCRIPTION: Creates packets to issue commands to the DMC.
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/24/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_cmd_seq extends uvm_sequence;

	//Register with the factory
	`uvm_object_utils(bsg_dmc_cmd_seq)

	bsg_dmc_asic_transaction cmd_txn;
	local app_cmd_e cmd;
	local bit [ui_addr_width_p-1:0] addr;

	function new(string name = "bsg_dmc_cmd_seq");
		super.new(name);
	endfunction: new

	extern virtual function set_params(app_cmd_e cmd, bit [ui_addr_width_p-1:0] addr);
	extern virtual task body();

endclass: bsg_dmc_cmd_seq

///////////////////////////////////////////////////////////////////////////////////////////////////
//     FUNCTION: get_params
//   PARAMETERS: cmd, addr
//      RETURNS: 
//  DESCRIPTION: DMC controller command and corresponding params to be set
function bsg_dmc_cmd_seq::set_params(app_cmd_e cmd, bit [ui_addr_width_p-1:0] addr);
	this.cmd = cmd;
	this.addr = addr;
endfunction: set_params

///////////////////////////////////////////////////////////////////////////////////////////////////
//         TASK: body
//   PARAMETERS: 
//  DESCRIPTION: initialist asic txn and pass to sequencer
task bsg_dmc_cmd_seq::body();

	`uvm_info(get_full_name(), $sformatf("Starting dmc_cmd_seq for cmd %s", this.cmd), UVM_NONE)
	cmd_txn =  bsg_dmc_asic_transaction::type_id::create("cmd_txn");
	cmd_txn.app_cmd = this.cmd;
	cmd_txn.app_addr = this.addr;
	cmd_txn.txn_type = ASIC_CMD;

	start_item(cmd_txn);
	finish_item(cmd_txn);

	`uvm_info(get_full_name(), "Done with dmc_cmd_seq", UVM_NONE)

endtask: body
