///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_dmc_tag_clients
//  DESCRIPTION: Part of the bsg_dmc hierarchy. Input: chip side tag liens, Output: decoded tag values, DFI 2x clock
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/26/22
///////////////////////////////////////////////////////////////////////////////////////////////////
module bsg_dmc_tag_clients
						import bsg_tag_pkg::*;
						import bsg_dmc_pkg::*;
						#(parameter `BSG_INV_PARAM(dq_group_p)
						,parameter ds_width_p         = 8
						,parameter num_adgs_p         = 1
						)
						(
						input  bsg_dmc_cfg_tag_lines_s cfg_tag_lines_i 
						,input ext_clk_i
						,input dfi_clk_1x_i
						,input ui_clk_sync_rst_i
                        ,output bsg_dmc_s dmc_p_o
						,output sys_reset_o
						,output logic stall_transmission_o
						);

    logic [14:0][7:0] 	dmc_cfg_tag_data_lo;
	logic [14:0]      	dmc_cfg_tag_new_data_lo;

  	genvar idx;
    for(idx=0;idx<14;idx++) begin: dmc_cfg
      bsg_tag_client #(.width_p( 8 ))
        btc
          (.bsg_tag_i     ( cfg_tag_lines_i.tag_lines[idx] )
          ,.recv_clk_i    (  dfi_clk_1x_i)
          ,.recv_new_r_o  ( dmc_cfg_tag_new_data_lo[idx] )
          ,.recv_data_r_o ( dmc_cfg_tag_data_lo[idx] )
          );
    end

	assign dmc_p_o.trefi        			= {dmc_cfg_tag_data_lo[1], dmc_cfg_tag_data_lo[0]};
	assign dmc_p_o.tmrd         			= dmc_cfg_tag_data_lo[2][3:0];
	assign dmc_p_o.trfc         			= dmc_cfg_tag_data_lo[2][7:4];
	assign dmc_p_o.trc          			= dmc_cfg_tag_data_lo[3][3:0];
	assign dmc_p_o.trp          			= dmc_cfg_tag_data_lo[3][7:4];
	assign dmc_p_o.tras         			= dmc_cfg_tag_data_lo[4][3:0];
	assign dmc_p_o.trrd         			= dmc_cfg_tag_data_lo[4][7:4];
	assign dmc_p_o.trcd         			= dmc_cfg_tag_data_lo[5][3:0];
	assign dmc_p_o.twr          			= dmc_cfg_tag_data_lo[5][7:4];
	assign dmc_p_o.twtr         			= dmc_cfg_tag_data_lo[6][3:0];
	assign dmc_p_o.trtp         			= dmc_cfg_tag_data_lo[6][7:4];
	assign dmc_p_o.tcas         			= dmc_cfg_tag_data_lo[7][3:0];
	assign dmc_p_o.col_width    			= dmc_cfg_tag_data_lo[8][3:0];
	assign dmc_p_o.row_width    			= dmc_cfg_tag_data_lo[8][7:4];
	assign dmc_p_o.bank_width   			= dmc_cfg_tag_data_lo[9][1:0];
	assign dmc_p_o.bank_pos     			= dmc_cfg_tag_data_lo[9][7:2];
	assign dmc_p_o.dqs_sel_cal  			= dmc_cfg_tag_data_lo[7][6:4];
	assign dmc_p_o.init_cycles  			= {dmc_cfg_tag_data_lo[11], dmc_cfg_tag_data_lo[10]};
	assign sys_reset_o          			= dmc_cfg_tag_data_lo[12][0];
    assign stall_transmission_o             = dmc_cfg_tag_data_lo[13][0];
endmodule
