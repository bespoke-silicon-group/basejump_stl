///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_write_seq
//  DESCRIPTION: pass packets to perform a write to LPDDR
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/24/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_write_seq extends uvm_sequence;

	//Register with the factory
	`uvm_object_utils(bsg_dmc_write_seq)

	bsg_dmc_asic_transaction txn;
	bsg_dmc_asic_sequencer sqr;

	local bit [ui_burst_length_p-1:0][ui_mask_width_lp -1 :0] wmask;
	local bit [ui_burst_length_p-1:0][ui_data_width_p-1:0] wdata;
	local int unsigned burst_length;

	function new(string name = "bsg_dmc_cmd_seq");
		super.new(name);
	endfunction: new

	extern virtual function set_data_params(bit [ui_burst_length_p-1:0][ui_mask_width_lp -1 :0] wmask, bit [ui_burst_length_p-1:0][ui_data_width_p-1:0] wdata);
	extern virtual function set_burst_length (int unsigned burst_length);
	extern virtual task start_cmd_seq();
	extern virtual task start_writing(bit[ui_data_width_p-1:0] pkt_number, bit last_packet=0);
	extern virtual task body();

endclass: bsg_dmc_write_seq

function bsg_dmc_write_seq::set_data_params(bit [ui_burst_length_p-1:0][ui_mask_width_lp -1 :0] wmask, bit [ui_burst_length_p-1:0][ui_data_width_p-1:0] wdata);
	this.wmask = wmask;
	this.wdata = wdata;
endfunction

function bsg_dmc_write_seq::set_burst_length(int unsigned burst_length);
	this.burst_length = burst_length;
endfunction

task bsg_dmc_write_seq::body();

	`uvm_info(get_full_name(), "Starting write sequence", UVM_MEDIUM)
	start_cmd_seq();
	
	for(int i=0;i< burst_length; i++) begin
		bit last_packet;
		if(i == burst_length -1) begin
			last_packet = 1;
		end
		wdata[i] = $random;
		`uvm_info(get_full_name(), $sformatf("Starting to write packet number: %0d", i), UVM_NONE)
		start_writing(.pkt_number(i), .last_packet(last_packet));
	end

	`uvm_info(get_full_name(), "Exiting write sequence", UVM_MEDIUM)

endtask:body

task bsg_dmc_write_seq::start_cmd_seq();
	bsg_dmc_cmd_seq cmd_seq;
	cmd_seq = bsg_dmc_cmd_seq::type_id::create("cmd_seq");
	cmd_seq.set_params(.cmd(WR), .addr(8));
	cmd_seq.start(sqr);
endtask

task bsg_dmc_write_seq::start_writing(bit[ui_data_width_p-1:0] pkt_number, bit last_packet=0);
	
	bsg_dmc_asic_transaction txn;
	txn = bsg_dmc_asic_transaction::type_id::create("write_txn");
	txn.txn_type = ASIC_WRITE;
	txn.app_wdf_data = wdata[pkt_number];
	txn.app_wdf_mask = wmask[pkt_number];

	if(last_packet) begin
		txn.app_wdf_end = 1;
	end
	`uvm_info(get_full_name(), $sformatf("Writing data %h,wmask %h last_packet %d to the driver", txn.app_wdf_data, txn.app_wdf_mask, txn.app_wdf_mask), UVM_MEDIUM)

	start_item(txn);
	finish_item(txn);

endtask
