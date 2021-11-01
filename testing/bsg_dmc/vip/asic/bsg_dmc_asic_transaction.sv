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

	//Register with factory
  	`uvm_object_utils(bsg_dmc_asic_transaction)

	function new(string name= "bsg_dmc_asic_transaction");
		super.new(name);
	endfunction

	//Data interface signals
	asic_txn_type_t					txn_type;	
	bit      [ui_addr_width_p-1:0] 	app_addr;
  	app_cmd_e                      	app_cmd;
  	bit                            	app_en;
  	bit                            	app_rdy;
  	bit                            	app_wdf_wren;
  	bit      [ui_data_width_p-1:0] 	app_wdf_data;
  	bit [(ui_data_width_p>>3)-1:0] 	app_wdf_mask;
  	bit                            	app_wdf_end;
  	bit                            	app_wdf_rdy;

  	bit                            	app_rd_data_valid;
  	bit       [ui_data_width_p-1:0]	app_rd_data;
  	bit                            	app_rd_data_end;

  	bit                            	app_ref_req;
  	bit                            	app_ref_ack;
  	bit                            	app_zq_req;
  	bit                            	app_zq_ack;
  	bit                            	app_sr_req;
  	bit                            	app_sr_active;

endclass: bsg_dmc_asic_transaction
