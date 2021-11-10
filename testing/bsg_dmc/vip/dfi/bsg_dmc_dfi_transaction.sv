///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//        CLASS: bsg_dmc_dfi_transaction
//  DESCRIPTION: DMC DFI transaction packet - has signal info for DMC-DFI interface.
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 11/02/21
///////////////////////////////////////////////////////////////////////////////////////////////////
class bsg_dmc_dfi_transaction extends uvm_transaction;
	//Register with factory
  	`uvm_object_utils(bsg_dmc_dfi_transaction)

	function new(string name= "bsg_dmc_dfi_transaction");
		super.new(name);
	endfunction

	bit                          dfi_clk_1x_i;
	bit                          dfi_clk_2x_i;
	bit                          dfi_rst_i;
	bit                    [2:0] dfi_bank_i;
	bit                   [15:0] dfi_address_i;
	bit                          dfi_cke_i;
	bit                          dfi_cs_n_i;
	bit                          dfi_ras_n_i;
	bit                          dfi_cas_n_i;
	bit                          dfi_we_n_i;
	bit                          dfi_reset_n_i;
	bit                          dfi_odt_i;
	bit                          dfi_wrdata_en_i;
	bit  [2*dq_data_width_p-1:0] dfi_wrdata_i;
	bit      [2*dq_group_lp-1:0] dfi_wrdata_mask_i;
	bit                          dfi_rddata_en_i;
	bit [2*dq_data_width_p-1:0] dfi_rddata_o;
	bit                   dfi_rddata_valid_o;

endclass: bsg_dmc_dfi_transaction
