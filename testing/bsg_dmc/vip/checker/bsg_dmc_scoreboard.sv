///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_scoreboard
//  DESCRIPTION: Scoreboarding commands, write and read data
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 12/24/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(bsg_dmc_scoreboard)

	local dfi_cmd_e current_cmd, prev_cmd;
	local bit auto_precharge;

	`uvm_analysis_imp_decl(_ddr)
	`uvm_analysis_imp_decl(_asic)

  	uvm_analysis_imp_asic#(bsg_dmc_asic_transaction,bsg_dmc_scoreboard) asic_imp; 
  	uvm_analysis_imp_ddr#(bsg_dmc_ddr_transaction,bsg_dmc_scoreboard) ddr_imp;

	function new(string name, uvm_component parent);
		super.new("bsg_dmc_scoreboard", parent);
		ddr_imp = new("ddr_imp", this);
	endfunction: new

	extern virtual function write_ddr(bsg_dmc_ddr_transaction txn);
	extern virtual function write_asic(bsg_dmc_asic_transaction txn);

	//extern virtual function void build_phase(uvm_phase phase);
	//extern virtual task run_phase(uvm_phase phase);
	//extern virtual task get_write_data();
	//extern virtual task get_read_data();
	//extern virtual function compare_read_write_data();
	extern virtual function check_legal_transition();
	extern virtual function print_error_transition();

endclass: bsg_dmc_scoreboard

function bsg_dmc_scoreboard::write_asic(bsg_dmc_asic_transaction txn);

endfunction

function bsg_dmc_scoreboard::write_ddr (bsg_dmc_ddr_transaction txn);
	prev_cmd = current_cmd;
	current_cmd = txn.command;

	if(txn.command inside {READ, WRITE}) begin
		auto_precharge = txn.ddr_addr[10];
	end
	else begin
		auto_precharge = 0;
	end

	`uvm_info(get_full_name(), $sformatf("got command %s and auto precharge %d at scoreboard", current_cmd, auto_precharge), UVM_NONE)
	check_legal_transition();
endfunction

function bsg_dmc_scoreboard::check_legal_transition();
	case(prev_cmd)
		LMR: begin
				if(!(current_cmd inside {ACT, LMR})) begin
					print_error_transition();
			 	end
		end
		REF: begin
				if(!(current_cmd inside {ACT, REF, LMR})) begin
					print_error_transition();
				end
			end
		PRE: begin
				if(!(current_cmd inside {ACT, REF})) begin
					print_error_transition();
				end
				if(auto_precharge) begin
					print_error_transition();
				end
			end
		ACT: begin
				if(! (current_cmd inside {READ, WRITE})) begin
					print_error_transition();
				end
			end	
		READ: begin
				if(! (current_cmd inside {READ, WRITE, PRE, ACT, REF})) begin
					print_error_transition();
				end
			 end
		WRITE: begin
				if(! (current_cmd inside {READ, WRITE, PRE, ACT, REF})) begin
					print_error_transition();
				end
			 end
	endcase	
endfunction: check_legal_transition

function bsg_dmc_scoreboard::print_error_transition();
	`uvm_fatal(get_full_name(), $sformatf("Illegal transition - Previous cmd: %s, current cmd: %s, auto_precharge %d", prev_cmd, current_cmd, auto_precharge))
endfunction
