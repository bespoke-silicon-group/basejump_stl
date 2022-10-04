///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_asic_driver
//  DESCRIPTION: Drives signals on the ASIC - DMC controller interface.
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/14/21
///////////////////////////////////////////////////////////////////////////////////////////////////

class bsg_dmc_asic_driver extends uvm_driver #(bsg_dmc_asic_transaction);

	//Register with the factory
	`uvm_component_utils(bsg_dmc_asic_driver)
	//`bsg_log_utils("ASIC/DRIVER")

	bsg_dmc_asic_transaction txn;

	virtual bsg_dmc_asic_interface 	vif;

	local bit reset_triggered;
	local bsg_dmc_asic_transaction cmd_q[$], write_q[$], read_q[$];

	extern virtual function void build_phase(uvm_phase phase);

	extern virtual task check_reset();
	extern virtual task get_set_and_drive();
	extern virtual task set_and_drive_cmd();
	extern virtual task set_and_drive_write();
	extern virtual task set_and_drive_read();

	extern virtual task get_txn();
	extern virtual task create_delay(int unsigned delay);
	extern virtual task run_phase(uvm_phase phase);

	function new(string name, uvm_component parent);
    	super.new(name,parent);
  	endfunction

endclass: bsg_dmc_asic_driver

function void bsg_dmc_asic_driver::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info(get_full_name(), "In ASIC driver build_phase", UVM_NONE)

    if(!uvm_config_db#(virtual bsg_dmc_asic_interface)::get(this,"","asic_if", vif)) begin
      `uvm_fatal(get_full_name(),"Unable to get ASIC virtual interface")
    end
endfunction: build_phase

task bsg_dmc_asic_driver::run_phase(uvm_phase phase);

	super.run_phase(phase);

	`uvm_info(get_full_name(), "In ASIC driver run_phase", UVM_NONE)
	
	fork begin
		forever begin
			check_reset();
			get_set_and_drive();
		end
	end
	join_none
endtask: run_phase

task bsg_dmc_asic_driver::check_reset();
	//reset is active low. Wait for it to be deasserted.
	if(!reset_triggered) begin
		@(negedge vif.ui_clk_sync_rst);
		reset_triggered = 1;
	end
	
endtask: check_reset

task bsg_dmc_asic_driver::get_set_and_drive();
	fork
		get_txn();
		set_and_drive_cmd();
		set_and_drive_write();
		set_and_drive_read();
	join
	//seq_item_port.item_done();
endtask: get_set_and_drive

task bsg_dmc_asic_driver::get_txn();
	`uvm_info(get_full_name(), "Waiting for ASIC transaction", UVM_MEDIUM)
	seq_item_port.peek(txn);
	if(txn.txn_type == ASIC_CMD) begin
		if(!cmd_q.size())begin
			cmd_q.push_back(txn);
			seq_item_port.item_done();
		end
	end
	else if(txn.txn_type == ASIC_WRITE) begin
		if(!write_q.size())begin
			write_q.push_back(txn);
		end
	end
	else if(txn.txn_type == ASIC_READ) begin
		if(!read_q.size())begin
			read_q.push_back(txn);
		end
	end
	`uvm_info(get_full_name(), "Got ASIC transaction packet", UVM_MEDIUM)
endtask: get_txn

task bsg_dmc_asic_driver::set_and_drive_cmd();


	if(cmd_q.size() && (write_q.size() || read_q.size()))begin
		bsg_dmc_asic_transaction cmd_txn = cmd_q.pop_front();
		`uvm_info(get_full_name(), $sformatf("Got txn type: %s .Driving cmd : %s to DMC controller", cmd_txn.txn_type, cmd_txn.app_cmd), UVM_MEDIUM)
		create_delay(cmd_txn.delay);
		@(posedge vif.ui_clk);

	    vif.app_en 		<= 1'b1;
		vif.app_addr 	<= cmd_txn.app_addr;
		vif.app_cmd 	<= cmd_txn.app_cmd;
		do @(posedge vif.ui_clk); while(!vif.app_rdy);
		vif.app_en <= 1'b0;	
	end
endtask: set_and_drive_cmd

task bsg_dmc_asic_driver::set_and_drive_write();

	if(write_q.size()) begin
		bsg_dmc_asic_transaction write_txn = write_q.pop_front();
		`uvm_info(get_full_name(), $sformatf("Got txn type: %s .Driving cmd : %s to DMC controller", write_txn.txn_type, write_txn.app_cmd), UVM_MEDIUM)
		@(posedge vif.ui_clk);
		create_delay(write_txn.delay);

    	vif.app_wdf_wren <= 1'b1;
		vif.app_wdf_data <= write_txn.app_wdf_data; 
		vif.app_wdf_mask <= write_txn.app_wdf_mask;
		if(write_txn.app_wdf_end) vif.app_wdf_end <= 1'b1;
		do @(posedge vif.ui_clk); while(!vif.app_wdf_rdy);
		vif.app_wdf_wren <= 1'b0;
		vif.app_wdf_end <= 1'b0;
		seq_item_port.item_done();					
	end
endtask 

task bsg_dmc_asic_driver::set_and_drive_read();
	if(read_q.size()) begin
		bsg_dmc_asic_transaction read_txn = read_q.pop_front();
		`uvm_info(get_full_name(), $sformatf("Got txn type: %s from DMC controller", read_txn.txn_type), UVM_MEDIUM)
		@(posedge vif.ui_clk);

		wait(vif.app_rd_data_valid);
		read_txn.app_rd_data = vif.app_rd_data;
		seq_item_port.item_done();
	end	
endtask				

task bsg_dmc_asic_driver::create_delay(int unsigned delay);
	for(int i=0; i < delay; i++) begin
		@(posedge vif.ui_clk);
	end
endtask
