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
						#(parameter `BSG_INV_PARAM(dq_group_lp)
						,parameter ds_width_p         = 8
						,parameter num_adgs_p         = 1
						)
						(
						input bsg_tag_s [28:0] tag_lines_i
						,input ext_clk_i
						,input dfi_clk_1x_i
						,input ui_clk_sync_rst_i
						,output  bsg_tag_lines_s dmc_tag_lines_s_o							
						,output bsg_dmc_s dmc_p_o
						,output dfi_clk_2x_o
						,output sys_reset_o
						,output logic stall_transmission_o
						);

							 

  	assign dmc_tag_lines_s_o.async_reset_tag	    	= tag_lines_i[0];
  	assign dmc_tag_lines_s_o.bsg_dly_tag         		= tag_lines_i[1+:dq_group_lp];
  	assign dmc_tag_lines_s_o.bsg_dly_trigger_tag 		= tag_lines_i[1+dq_group_lp+:4];
  	assign dmc_tag_lines_s_o.bsg_ds_tag         		= tag_lines_i[1+2*dq_group_lp];
	assign dmc_tag_lines_s_o.bsg_clk_monitor_ds_tag   	= tag_lines_i[28];

	logic [14:0][7:0] 	dmc_cfg_tag_data_lo;
	logic [14:0]      	dmc_cfg_tag_new_data_lo;

	`declare_bsg_clk_gen_ds_tag_payload_s(3)

  	bsg_clk_gen_ds_tag_payload_s clock_monitor_clock_downsample;

	bsg_tag_s [13:0] dmc_cfg_tag_lines_lo;
	assign dmc_cfg_tag_lines_lo = tag_lines_i[2+2*dq_group_lp+:14];

  	genvar idx;
  	generate
  	  for(idx=0;idx<14;idx++) begin: dmc_cfg
  	    bsg_tag_client #(.width_p( 8 ))
  	      btc
  	        (.bsg_tag_i     ( dmc_cfg_tag_lines_lo[idx] )
  	        ,.recv_clk_i    (  dfi_clk_1x_i)
  	        ,.recv_new_r_o  ( dmc_cfg_tag_new_data_lo[idx] )
  	        ,.recv_data_r_o ( dmc_cfg_tag_data_lo[idx] )
  	        );
  	  end
  	endgenerate

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
	//assign clock_monitor_clock_downsample 	= dmc_cfg_tag_data_lo[12][2:0];

	always @(posedge dfi_clk_1x_i) begin
	   	if(ui_clk_sync_rst_i) begin
	  	  	stall_transmission_o <= 0;
	    end
		else begin
	  		stall_transmission_o <= dmc_cfg_tag_data_lo[13][0];
	  	end
	end

	bsg_tag_s osc_tag_lines_li;
	bsg_tag_s osc_trigger_tag_lines_li;
	bsg_tag_s ds_tag_lines_li;
	logic async_reset_lo;
	bsg_tag_s async_reset_tag_lines_li;
	
	bsg_tag_client_unsync #( .width_p(1) )
	  btc_async_reset
	    (.bsg_tag_i(async_reset_tag_lines_li)
	    ,.data_async_r_o(async_reset_lo)
	    );

	assign async_reset_tag_lines_li 	= tag_lines_i[24];
	assign osc_tag_lines_li         	= tag_lines_i[25];
	assign osc_trigger_tag_lines_li 	= tag_lines_i[26];
	assign ds_tag_lines_li         		= tag_lines_i[27];

	bsg_clk_gen #(.downsample_width_p(ds_width_p)
	             ,.num_adgs_p(num_adgs_p)
	             ,.version_p(2)
				 ,.nonsynth_sim_osc_mul_factor_p(50)
	             )
	  clk_gen_inst
	    (.async_osc_reset_i     (async_reset_lo)
	    ,.bsg_osc_tag_i         (osc_tag_lines_li)
	    ,.bsg_osc_trigger_tag_i (osc_trigger_tag_lines_li)
	    ,.bsg_ds_tag_i          (ds_tag_lines_li)
	    ,.ext_clk_i             (ext_clk_i)
	    ,.select_i              (2'b00)
	    ,.clk_o                 (dfi_clk_2x_o)
	    );

endmodule
