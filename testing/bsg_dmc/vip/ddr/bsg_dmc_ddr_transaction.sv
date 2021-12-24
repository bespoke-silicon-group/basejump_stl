///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_ddr_transaction
//  DESCRIPTION: transaction packet with interface information between DMC-DFI to DDR modules
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 11/02/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_ddr_transaction extends uvm_sequence_item;

	//Register with factory
  	`uvm_object_utils(bsg_dmc_ddr_transaction)

	function new(string name= "bsg_dmc_asic_transaction");
		super.new(name);
	endfunction

	bit     [dq_data_width_p-1:0]  		ddr_dq;
	bit     [(dq_data_width_p>>3)-1:0] 	ddr_dqs_p;
	bit     [15:0]						ddr_addr;
	bit     [2:0] 						ddr_ba;
	bit     							ddr_ck_p;
	bit     							ddr_ck_n;
	bit     							ddr_cke;
	bit     							ddr_cs_n;
	bit     							ddr_ras_n;
	bit     							ddr_cas_n;
	bit     							ddr_we_n;
	bit     [(dq_data_width_p>>3)-1:0] 	ddr_dm;
	bit									ui_clk_sync_rst;

endclass: bsg_dmc_ddr_transaction
