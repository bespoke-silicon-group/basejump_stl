///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_top_seq
//  DESCRIPTION: Top level sequence that looks at the scenario and triggers actions accordingly. 
//  It randomises the scenario if no plusarg is provided
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 11/09/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_top_seq extends uvm_sequence;

	//Register with the factory
	`uvm_object_utils(bsg_dmc_top_seq)

	function new(string name = "bsg_dmc_top_seq");
		super.new(name);
	endfunction: new

	string scenario;
	int unsigned addr;
	bit rand_addr;
	bsg_dmc_asic_sequencer sqr;

	local int unsigned row_width, col_width, bank_width;

	extern virtual task body();
	extern virtual task start_cmd_seq(app_cmd_e cmd);
	extern virtual task do_write();
	extern virtual task do_read();
	extern virtual function set_addr_params(int unsigned row_width, int unsigned col_width, int unsigned bank_width);
endclass: bsg_dmc_top_seq

task bsg_dmc_top_seq::body();
	`uvm_info(get_full_name(), $sformatf("In top sequence to implement scenario: %s", scenario), UVM_NONE)

	case (scenario)
		"write": begin
					do_write();
		end
		"write_auto_precharge": begin
					do_write();
		end
		"read": begin
					do_read();
		end
		"read_auto_precharge": begin
					do_read();
		end
		"write_read_same_addr": begin
					do_write();
					//use the address from prev write for read
					rand_addr = 0;
					do_read();
		end
		"write_n_times": begin
		end
		default: begin
					`uvm_fatal(get_full_name(), $sformatf(" Scenario: %s not recognised", scenario)
		end
	endcase
endtask

task bsg_dmc_top_seq::start_cmd_seq(app_cmd_e cmd);
	bsg_dmc_cmd_seq cmd_seq;
	cmd_seq = bsg_dmc_cmd_seq::type_id::create("cmd_seq");
	cmd_seq.set_params(.cmd(cmd), .addr(addr), .rand_addr(rand_addr));
	cmd_seq.set_addr_params(.row_width(row_width), .col_width(col_width), .bank_width(bank_width));
	cmd_seq.start(sqr);
	addr = cmd_seq.get_addr();
endtask

task bsg_dmc_top_seq::do_write();
	bsg_dmc_write_seq write_seq;

	start_cmd_seq(.cmd(WR));
	write_seq = bsg_dmc_write_seq::type_id::create("write_seq");
	write_seq.set_burst_length(ui_burst_length_p);
	write_seq.start(sqr);
endtask

task bsg_dmc_top_seq::do_read();
	bsg_dmc_read_seq read_seq;

	start_cmd_seq(.cmd(RD));
	read_seq = bsg_dmc_read_seq::type_id::create("read_seq");
	read_seq.set_burst_length(ui_burst_length_p);
	read_seq.start(sqr);
endtask

function bsg_dmc_top_seq::set_addr_params(int unsigned row_width, int unsigned col_width, int unsigned bank_width);
	this.row_width = row_width;
	this.col_width = col_width;
	this.bank_width = bank_width;
endfunction
