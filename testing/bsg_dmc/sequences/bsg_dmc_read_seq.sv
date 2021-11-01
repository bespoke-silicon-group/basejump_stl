///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_read_seq
//  DESCRIPTION: Sequence to do basic read from the DDR
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/28/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_read_seq extends uvm_sequence;

	//Register with the factory
	`uvm_object_utils(bsg_dmc_read_seq)

	bsg_dmc_asic_transaction txn;
	bsg_dmc_asic_sequencer sqr;

	local bit [ui_burst_length_p-1:0][ui_mask_width_lp -1 :0] wmask;
	local bit [ui_burst_length_p-1:0][ui_data_width_p-1:0] wdata;
	local int unsigned burst_length;

	function new(string name = "bsg_dmc_cmd_seq");
		super.new(name);
	endfunction: new

	extern virtual function set_burst_length (int unsigned burst_length);
	extern virtual task start_cmd_seq();
	extern virtual task start_reading( bit last_packet=0);
	extern virtual task body();

endclass: bsg_dmc_read_seq

function bsg_dmc_read_seq::set_burst_length(int unsigned burst_length);
	this.burst_length = burst_length;
endfunction

task bsg_dmc_read_seq::body();

	`uvm_info(get_full_name(), "Starting read sequence", UVM_MEDIUM)
	start_cmd_seq();
	
	for(int i=0;i< burst_length; i++) begin
		bit last_packet;
		if(i == burst_length -1) begin
			last_packet = 1;
		end
		`uvm_info(get_full_name(), $sformatf("Starting to read packet number: %0d", i), UVM_NONE)
		start_reading(.last_packet(last_packet));
	end

	`uvm_info(get_full_name(), "Exiting read sequence", UVM_MEDIUM)

endtask:body

task bsg_dmc_read_seq::start_cmd_seq();
	bsg_dmc_cmd_seq cmd_seq;
	cmd_seq = bsg_dmc_cmd_seq::type_id::create("cmd_seq");
	cmd_seq.set_params(.cmd(RD), .addr(8));
	cmd_seq.start(sqr);
endtask

task bsg_dmc_read_seq::start_reading(bit last_packet=0);
	
	bsg_dmc_asic_transaction txn;
	txn = bsg_dmc_asic_transaction::type_id::create("read_txn");
	txn.txn_type = ASIC_READ;

	start_item(txn);
	finish_item(txn);

	`uvm_info(get_full_name(), $sformatf("Read data %h from the driver", txn.app_rd_data), UVM_MEDIUM)

endtask
