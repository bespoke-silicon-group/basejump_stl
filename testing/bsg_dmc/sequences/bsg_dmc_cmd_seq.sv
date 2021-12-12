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

	local app_cmd_e cmd;
	local bit [ui_addr_width_p-1:0] addr;
	local bit rand_addr;
	local int unsigned row_width, col_width, bank_width;
	local int unsigned delay;

	function new(string name = "bsg_dmc_cmd_seq");
		super.new(name);
	endfunction: new

	extern virtual function set_params(app_cmd_e cmd, bit [ui_addr_width_p-1:0] addr=0, bit rand_addr=1);
	extern virtual function set_addr_params(int unsigned row_width, int unsigned col_width, int unsigned bank_width);
	extern virtual function set_delay(int unsigned delay);

	extern virtual function int unsigned get_addr();

	extern virtual task body();

endclass: bsg_dmc_cmd_seq

///////////////////////////////////////////////////////////////////////////////////////////////////
//  FUNCTION: set_params
//  PARAMETERS: cmd, addr
//  RETURNS: 
//  DESCRIPTION: DMC controller command and corresponding params to be set
function bsg_dmc_cmd_seq::set_params(app_cmd_e cmd, bit [ui_addr_width_p-1:0] addr=0, bit rand_addr = 1);
	this.cmd = cmd;
	this.addr = addr;
	this.rand_addr = rand_addr;
endfunction: set_params

function bsg_dmc_cmd_seq::set_addr_params(int unsigned row_width, int unsigned col_width, int unsigned bank_width);
	this.row_width = row_width;
	this.col_width = col_width;
	this.bank_width = bank_width;
endfunction

function bsg_dmc_cmd_seq::set_delay(int unsigned delay);
	this.delay = delay;
endfunction

///////////////////////////////////////////////////////////////////////////////////////////////////
//  TASK: body
//  PARAMETERS: 
//  DESCRIPTION: initialise asic txn and pass to sequencer
task bsg_dmc_cmd_seq::body();
	bsg_dmc_asic_transaction cmd_txn;

	`uvm_info(get_full_name(), $sformatf("Starting dmc_cmd_seq for cmd %s", this.cmd), UVM_NONE)
	cmd_txn =  bsg_dmc_asic_transaction::type_id::create("cmd_txn");
	cmd_txn.txn_type = ASIC_CMD;
	cmd_txn.rand_addr = this.rand_addr;
	cmd_txn.app_cmd = cmd;
	cmd_txn.app_addr = this.addr;
	cmd_txn.delay = delay;
	
	cmd_txn.set_params(.row_width(row_width), .col_width(col_width), .bank_width(bank_width));
	start_item(cmd_txn);
	cmd_txn.randomize();

	//for read followed by write, we need the write addr saved
	this.addr = cmd_txn.app_addr;

	finish_item(cmd_txn);

	`uvm_info(get_full_name(), $sformatf("Done with dmc_cmd_seq for cmd %s for addr %d", cmd, addr), UVM_NONE)

endtask: body

function int unsigned bsg_dmc_cmd_seq::get_addr();
	return addr;
endfunction
