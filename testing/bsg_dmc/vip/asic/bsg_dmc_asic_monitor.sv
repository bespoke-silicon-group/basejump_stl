///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_asic_monitor
//  DESCRIPTION: Monitors the interface between ASIC and DMC controller to pass info to the checker
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/31/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_asic_monitor extends uvm_monitor #(bsg_dmc_asic_transaction);

	//Register with the factory
	`uvm_component_utils(bsg_dmc_asic_monitor)

	bsg_dmc_asic_transaction txn;

	uvm_analysis_port#(bsg_dmc_asic_transaction) asic_mon_analysis_port;

	virtual bsg_dmc_asic_interface 	vif;

	local bit reset_triggered, cmd_recd;
	local bsg_dmc_asic_transaction buffer_txn;

	extern virtual function void build_phase(uvm_phase phase);

	extern virtual task check_reset();
	extern virtual task capture_signals();
	extern virtual task run_phase(uvm_phase phase);

	function new(string name, uvm_component parent);
    	super.new(name,parent);
		asic_mon_analysis_port = new("asic_mon_analysis_port", this);
  	endfunction

endclass: bsg_dmc_asic_monitor

function void bsg_dmc_asic_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);
	`uvm_info(get_full_name(), "In ASIC monitor build_phase", UVM_NONE)

    if(!uvm_config_db#(virtual bsg_dmc_asic_interface)::get(this,"","asic_if", vif)) begin
      `uvm_fatal(get_full_name(),"Unable to get ASIC virtual interface")
    end
endfunction: build_phase

task bsg_dmc_asic_monitor::run_phase(uvm_phase phase);

	super.run_phase(phase);

	`uvm_info(get_full_name(), "In ASIC monitor run_phase", UVM_NONE)
	
	fork begin
		forever begin
			check_reset();
			capture_signals();
		end
	end
	join_none
endtask: run_phase

task bsg_dmc_asic_monitor::check_reset();
	//reset is active low. Wait for it to be deasserted.
	if(!reset_triggered) begin
		@(negedge vif.ui_clk_sync_rst);
		reset_triggered = 1;
	end
endtask

task bsg_dmc_asic_monitor::capture_signals();
	fork
		begin
			@(posedge vif.app_en);
			txn = bsg_dmc_asic_transaction::type_id::create("txn");
			txn.txn_type = ASIC_CMD;
			txn.app_addr = vif.app_addr;
			txn.app_cmd = vif.app_cmd;
			txn.app_rdy = vif.app_rdy;
			cmd_recd = 1;
			`uvm_info(get_full_name(), $sformatf("got cmd %s to addr %h at ASIC monitor", txn.app_cmd, txn.app_addr), UVM_MEDIUM)
		end
		begin
			@(posedge vif.app_wdf_wren);
			if(!cmd_recd) begin
				$display("cmd not recd");
				buffer_txn = bsg_dmc_asic_transaction::type_id::create("txn");
				buffer_txn.txn_type = ASIC_WRITE;
				buffer_txn.app_wdf_data = vif.app_wdf_data;
				buffer_txn.app_wdf_mask = vif.app_wdf_mask;
				buffer_txn.app_wdf_end = vif.app_wdf_end;
			end
			if(cmd_recd) begin
				txn = bsg_dmc_asic_transaction::type_id::create("txn");
				txn.txn_type = ASIC_WRITE;
				txn.app_addr = vif.app_addr;					
				txn.app_wdf_data = vif.app_wdf_data;
				txn.app_wdf_mask = vif.app_wdf_mask;
				txn.app_wdf_end = vif.app_wdf_end;

				if(buffer_txn != null) begin
					buffer_txn.app_addr = vif.app_addr;
					asic_mon_analysis_port.write(buffer_txn);
					`uvm_info(get_full_name(), $sformatf("got buffer wdata %h and wmask %h wdf_end %d at addr %h at ASIC monitor", buffer_txn.app_wdf_data, buffer_txn.app_wdf_mask, buffer_txn.app_wdf_end, buffer_txn.app_addr ), UVM_MEDIUM)			

					buffer_txn = null;
				end

				if(txn.app_wdf_end)
					cmd_recd=0;
				`uvm_info(get_full_name(), $sformatf("got wdata %h and wmask %h wdf_end %d at addr %h at ASIC monitor", txn.app_wdf_data, txn.app_wdf_mask, txn.app_wdf_end, txn.app_addr ), UVM_MEDIUM)			

			end
		end
		begin 
			wait(vif.app_rd_data_valid);
			@(vif.app_rd_data);
			if(vif.app_rd_data_valid) begin
				txn = bsg_dmc_asic_transaction::type_id::create("txn");
				txn.txn_type = ASIC_READ;						
				txn.app_addr = vif.app_addr;			
				txn.app_rd_data = vif.app_rd_data;
				txn.app_rd_data_end = vif.app_rd_data_end;
				cmd_recd=0;			
				`uvm_info(get_full_name(), $sformatf("got rdata %h and rdata_end %h at ASIC monitor", txn.app_rd_data, txn.app_rd_data_valid ), UVM_MEDIUM)	
			end		
		end					
	join_any
	disable fork;
	if(txn != null )
		asic_mon_analysis_port.write(txn);
endtask
