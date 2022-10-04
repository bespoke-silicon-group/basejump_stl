///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_asic_transaction
//  DESCRIPTION: Transaction packet for driving down signals on the ASIC data interface
//       AUTHOR: Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/08/21
///////////////////////////////////////////////////////////////////////////////////////////////////

class bsg_dmc_asic_transaction extends uvm_sequence_item;

	// Register with factory
  	`uvm_object_utils(bsg_dmc_asic_transaction)

	function new(string name= "bsg_dmc_asic_transaction");
		super.new(name);
	endfunction

	asic_txn_type_t							txn_type=ASIC_WRITE;	

	bit [3:0] row_width, col_width;
	bit [1:0] bank_width;
	bit rand_addr;

	rand bit [15:0] row_addr, col_addr;
	rand bit [2:0] bank_addr;

	// cmd interface signals
	bit      [ui_addr_width_p-1:0] 			app_addr;
  	app_cmd_e                      			app_cmd;
  	bit                            			app_en;
  	bit                            			app_rdy;

	// write interface signals
  	rand bit [ui_data_width_p-1:0] 			app_wdf_data;
  	rand bit [(ui_data_width_p>>3)-1:0] 	app_wdf_mask;

  	bit                            			app_wdf_wren;
  	bit                            			app_wdf_end;
  	bit                            			app_wdf_rdy;

	// Read interface signals
  	bit                            			app_rd_data_valid;
  	bit [ui_data_width_p-1:0]				app_rd_data;
  	bit                            			app_rd_data_end;

	// delay after which packet has to be driven
	bit [1:0]								delay;

	constraint legal_row_col_bank_addr {
		row_addr inside {[0:(2**row_width -1)]};
		col_addr inside {[0:(2**col_width -1)]};
		bank_addr inside {[0:(2**bank_width -1)]};						
	}

	function void pre_randomize();
		if(rand_addr) begin
		`uvm_info(get_full_name(), $sformatf("Randomising packet with row width %d col_width %d bank_width %d", row_width, col_width, bank_width), UVM_MEDIUM)
		end
		else begin
			app_addr.rand_mode(0);
		end
	endfunction

	function void post_randomize();
		if(txn_type == ASIC_CMD && rand_addr) begin
			int unsigned row_plus_col_widths = row_width + col_width;

			app_addr |= col_addr; 
			app_addr |= ({{30{0}},row_addr} << (col_width));
			app_addr |= ({{30{0}},bank_addr} << (row_plus_col_widths));

			`uvm_info(get_full_name(), $sformatf("Randomised packet with row_addr %b col_addr %b bank_addr %b. Setting address to %b", row_addr, col_addr, bank_addr, app_addr), UVM_MEDIUM)
		end
	endfunction

	virtual function set_params(int unsigned row_width, int unsigned col_width, int unsigned bank_width);
		this.row_width = row_width;
		this.col_width = col_width;
		this.bank_width = bank_width;
	endfunction

endclass: bsg_dmc_asic_transaction
