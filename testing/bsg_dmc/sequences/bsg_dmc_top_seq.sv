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
	bit rand_addr;
	int unsigned read_write_iter;
	bit enable_random_delay=0;
	bsg_dmc_asic_sequencer sqr;

	local int unsigned addr_queue[$];

	local int unsigned row_width, col_width, bank_width;

	extern virtual task body();
	extern virtual function set_addr(int unsigned addr);
	extern virtual task start_cmd_seq(app_cmd_e cmd, int unsigned delay=0);
	extern virtual task do_write(bit auto_precharge=0);
	extern virtual task do_read(bit auto_precharge=0);
	extern virtual task random_delay();
	extern virtual task do_write_read(bit read_auto_precharge=0, bit write_auto_precharge=0, bit same_addr=0);

	extern virtual function set_addr_params(int unsigned row_width, int unsigned col_width, int unsigned bank_width);
endclass: bsg_dmc_top_seq

task bsg_dmc_top_seq::body();
	`uvm_info(get_full_name(), $sformatf("In top sequence to implement scenario: %s", scenario), UVM_NONE)

	if(rand_addr) begin
		 addr_queue.pop_front();
	end

	case (scenario)
		"write": begin
				do_write();
		end
		"write_auto_precharge": begin
				do_write(.auto_precharge(1));
		end
		"write_read_same_addr": begin
				do_write_read(.read_auto_precharge(0), .write_auto_precharge(0), .same_addr(1));
				#1us;
		end
		"write_read_same_addr_auto_precharge": begin
				do_write_read(.read_auto_precharge(1), .write_auto_precharge(1), .same_addr(1));					
		end
		"write_consecutive_addresses": begin
			int unsigned address;
			rand_addr=0;
			for(int i=0; i<read_write_iter; i++) begin
				addr_queue.push_back(address);
				address++;
			end
			for(int i=0; i<read_write_iter; i++) begin
				do_write();
			end			
		end
		"write_n_times": begin
			for(int i=0; i<read_write_iter; i++) begin
				random_delay();
				do_write();
			end
		end
		"write_n_times_read_n_times": begin
			for(int i=0; i<read_write_iter; i++) begin
				random_delay();				
				do_write();
			end
			rand_addr = 0;
			for(int i=0; i<read_write_iter; i++) begin
				random_delay();				
				do_read();
			end
			#1us;
		end
		"write_n_times_read_n_times_same_addr": begin
			do_write();
			rand_addr = 0;			
			for(int i=0; i<read_write_iter-1; i++) begin
				random_delay();				
				do_write();
			end
			for(int i=0; i<read_write_iter; i++) begin
				random_delay();				
				do_read();
			end
			#1us;
		end
		"write_n_times_read_n_times_rand_auto_precharge": begin
			bit auto_precharge;
			for(int i=0; i<read_write_iter; i++) begin
				auto_precharge = $random;
				random_delay();				
				do_write(.auto_precharge(auto_precharge));
			end
			rand_addr = 0;
			for(int i=0; i<read_write_iter; i++) begin
				auto_precharge = $random;	
				random_delay();				
				do_read(.auto_precharge(auto_precharge));
			end
		end
		"write_n_times_read_or_write_n_times_rand_auto_precharge": begin
			bit auto_precharge, read_or_write_n;
			for(int i=0; i<read_write_iter; i++) begin
				auto_precharge = $random;
				do_write(.auto_precharge(auto_precharge));
			end
			rand_addr = 0;
			addr_queue.shuffle();
			for(int i=0; i<read_write_iter; i++) begin
				auto_precharge = $random;
				read_or_write_n = $random;
				if(read_or_write_n) begin		
					do_read(.auto_precharge(auto_precharge));
				end
				else begin
					do_write(.auto_precharge(auto_precharge));
				end
			end
		end
		"write_n_times_rand_auto_precharge": begin
			for(int i=0; i<read_write_iter; i++) begin
				bit auto_precharge = $random;
				do_write(.auto_precharge(auto_precharge));
			end
		end
		default: begin
			`uvm_fatal(get_full_name(), $sformatf("Scenario: %s not recognised", scenario))
		end
	endcase
endtask

task bsg_dmc_top_seq::start_cmd_seq(app_cmd_e cmd, int unsigned delay=0);
	bsg_dmc_cmd_seq cmd_seq;
	int unsigned address ;

	if(!rand_addr) begin
		address = addr_queue.pop_front();
	end

	cmd_seq = bsg_dmc_cmd_seq::type_id::create("cmd_seq");
	cmd_seq.set_params(.cmd(cmd), .addr(address), .rand_addr(rand_addr));
	cmd_seq.set_addr_params(.row_width(row_width), .col_width(col_width), .bank_width(bank_width));
	cmd_seq.set_delay(delay);
	cmd_seq.start(sqr);
	if(rand_addr) begin
		addr_queue.push_back(cmd_seq.get_addr());
	end
endtask

task bsg_dmc_top_seq::do_write(bit auto_precharge=0);
	bsg_dmc_write_seq write_seq;

	app_cmd_e cmd = (auto_precharge) ? WP : WR;

	fork
		begin
			bit rand_delay;
			rand_delay = $urandom_range(1,0);
			`uvm_info(get_full_name(), $sformatf("Delaying write command by %d cycle", rand_delay), UVM_MEDIUM)
			start_cmd_seq(.cmd(cmd), .delay(rand_delay));
		end
		begin
			bit [1:0] rand_delay;
			rand_delay = $urandom_range(1,0);
			`uvm_info(get_full_name(), $sformatf("Delaying write data by %d cycle", rand_delay), UVM_MEDIUM)			
			write_seq = bsg_dmc_write_seq::type_id::create("write_seq");
			write_seq.set_burst_length(ui_burst_length_p);
			write_seq.set_delay(rand_delay);
			write_seq.start(sqr);
		end
	join

endtask

task bsg_dmc_top_seq::do_read(bit auto_precharge=0);
	bsg_dmc_read_seq read_seq;

	app_cmd_e cmd = (auto_precharge) ? RP : RD;

	start_cmd_seq(.cmd(cmd));
	read_seq = bsg_dmc_read_seq::type_id::create("read_seq");
	read_seq.set_burst_length(ui_burst_length_p);
	read_seq.start(sqr);
endtask

task bsg_dmc_top_seq::do_write_read(bit read_auto_precharge=0, bit write_auto_precharge=0, bit same_addr=0);
	do_write(.auto_precharge(write_auto_precharge));
	//use the address from prev write for read?
	if(same_addr) begin
		this.rand_addr = 0;
	end
	do_read(.auto_precharge(read_auto_precharge));
endtask

task bsg_dmc_top_seq::random_delay();
	// delay = rand_delay*100ps
	if(enable_random_delay) begin
		int unsigned rand_delay = $urandom_range(30000, 20000);
		`uvm_info(get_full_name, $sformatf("Generating delay of %d * 100ps", rand_delay), UVM_MEDIUM)
		#(rand_delay);
	end
endtask

function bsg_dmc_top_seq::set_addr_params(int unsigned row_width, int unsigned col_width, int unsigned bank_width);
	this.row_width = row_width;
	this.col_width = col_width;
	this.bank_width = bank_width;
endfunction

function bsg_dmc_top_seq::set_addr(int unsigned addr);
	addr_queue.push_back(addr);
endfunction
