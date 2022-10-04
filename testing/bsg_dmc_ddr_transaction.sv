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


