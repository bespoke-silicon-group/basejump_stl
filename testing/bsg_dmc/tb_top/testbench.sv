///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: testbench
//  DESCRIPTION: TB TOP; instances DUT, connects TB to it and spawns off tests. The TB uses UVM 1.2
//    AUTHOR(S): Dr. Chun Zhao; Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 10/08/21
///////////////////////////////////////////////////////////////////////////////////////////////////

import uvm_pkg::*;
import bsg_dmc_params_pkg::*;
import uvm_pkg::*;
import bsg_dmc_pkg::*;
import bsg_dmc_asic_pkg::*;
import bsg_dmc_seq_pkg::*;

`include "uvm_macros.svh"

`include "../env/bsg_dmc_env.sv"
`include "bsg_dmc_base_test.sv"

module testbench();
	import bsg_tag_pkg::*;
	import bsg_dmc_pkg::*;
	
	//contains signals to connect between dut and tb
	`include "bsg_dmc_tb_top_signals.vh"

	//TODO: akashs3 COMMENTED: REMOVE AFTER FULL TB IS BROUGHT UP.
	//`include "tasks.v"
	genvar i;
	
	integer j,k;
	
	integer read_transactions;

	bsg_dmc_asic_interface asic_if();

	//TB TOP to TB connection for ASIC - DMC controller interface
	assign app_addr 					= asic_if.app_addr;
	assign app_cmd 						= asic_if.app_cmd;
	assign app_en 						= asic_if.app_en;
	assign asic_if.app_rdy				= app_rdy;
	assign app_wdf_wren					= asic_if.app_wdf_wren;
	assign app_wdf_data					= asic_if.app_wdf_data;
	assign app_wdf_mask					= asic_if.app_wdf_mask;
	assign app_wdf_end					= asic_if.app_wdf_end;
	assign asic_if.app_wdf_rdy			= app_wdf_rdy;

	assign asic_if.app_rd_data_valid	= app_rd_data_valid;
	assign asic_if.app_rd_data			= app_rd_data;
	assign asic_if.app_rd_data_end		= app_rd_data_end;

	assign app_ref_req					= asic_if.app_ref_req;
	assign asic_if.app_ref_ack			= app_ref_ack;
	assign app_zq_req					= asic_if.app_zq_req;
	assign asic_if.app_zq_ack			= app_zq_ack;
	assign app_sr_req					= asic_if.app_sr_req;
	assign asic_if.app_sr_active		= app_sr_active;
	
	//TB TOP to DUT connection
	bsg_dmc #
	  (.num_adgs_p            ( clk_gen_num_adgs_p  )
	  ,.ui_addr_width_p       ( ui_addr_width_p     )
	  ,.ui_data_width_p       ( ui_data_width_p     )
	  ,.burst_data_width_p    ( burst_data_width_lp )
	  ,.dq_data_width_p       ( dq_data_width_p     )
	  ,.cmd_afifo_depth_p     ( cmd_afifo_depth_p   )
	  ,.cmd_sfifo_depth_p     ( cmd_sfifo_depth_p   ))
	dmc_inst
	  (.async_reset_tag_i     ( dmc_reset_tag_lines_lo       )
	  ,.bsg_dly_tag_i         ( dmc_dly_tag_lines_lo         )
	  ,.bsg_dly_trigger_tag_i ( dmc_dly_trigger_tag_lines_lo )
	  ,.bsg_ds_tag_i          ( dmc_ds_tag_lines_lo          )
	
	  ,.dmc_p_i               ( dmc_p               )
	
	  ,.sys_reset_i           ( sys_reset           )
	
	  ,.app_addr_i            ( app_addr            )
	  ,.app_cmd_i             ( app_cmd             )
	  ,.app_en_i              ( app_en              )
	  ,.app_rdy_o             ( app_rdy             )
	  ,.app_wdf_wren_i        ( app_wdf_wren        )
	  ,.app_wdf_data_i        ( app_wdf_data        )
	  ,.app_wdf_mask_i        ( app_wdf_mask        )
	  ,.app_wdf_end_i         ( app_wdf_end         )
	  ,.app_wdf_rdy_o         ( app_wdf_rdy         )
	  ,.app_rd_data_valid_o   ( app_rd_data_valid   )
	  ,.app_rd_data_o         ( app_rd_data         )
	  ,.app_rd_data_end_o     ( app_rd_data_end     )
	  ,.app_ref_req_i         ( 1'b0                )
	  ,.app_ref_ack_o         ( app_ref_ack         )
	  ,.app_zq_req_i          ( 1'b0                )
	  ,.app_zq_ack_o          ( app_zq_ack          )
	  ,.app_sr_req_i          ( 1'b0                )
	  ,.app_sr_active_o       ( app_sr_active       )
	
	  ,.init_calib_complete_o ( init_calib_complete )
	
	  ,.ddr_ck_p_o            ( ddr_ck_p            )
	  ,.ddr_ck_n_o            ( ddr_ck_n            )
	  ,.ddr_cke_o             ( ddr_cke             )
	  ,.ddr_ba_o              ( ddr_ba              )
	  ,.ddr_addr_o            ( ddr_addr            )
	  ,.ddr_cs_n_o            ( ddr_cs_n            )
	  ,.ddr_ras_n_o           ( ddr_ras_n           )
	  ,.ddr_cas_n_o           ( ddr_cas_n           )
	  ,.ddr_we_n_o            ( ddr_we_n            )
	  ,.ddr_reset_n_o         ( ddr_reset_n         )
	  ,.ddr_odt_o             ( ddr_odt             )
	
	  ,.ddr_dm_oen_o          ( ddr_dm_oen_lo       )
	  ,.ddr_dm_o              ( ddr_dm_lo           )
	  ,.ddr_dqs_p_oen_o       ( ddr_dqs_p_oen_lo    )
	  ,.ddr_dqs_p_ien_o       ( ddr_dqs_p_ien_lo    )
	  ,.ddr_dqs_p_o           ( ddr_dqs_p_lo        )
	  ,.ddr_dqs_p_i           ( ddr_dqs_p_li        )
	  ,.ddr_dqs_n_oen_o       ( ddr_dqs_n_oen_lo    )
	  ,.ddr_dqs_n_ien_o       ( ddr_dqs_n_ien_lo    )
	  ,.ddr_dqs_n_o           ( ddr_dqs_n_lo        )
	  ,.ddr_dqs_n_i           ( ddr_dqs_n_li        )
	  ,.ddr_dq_oen_o          ( ddr_dq_oen_lo       )
	  ,.ddr_dq_o              ( ddr_dq_lo           )
	  ,.ddr_dq_i              ( ddr_dq_li           )
	
	  ,.ui_clk_i              ( ui_clk              )
	  ,.dfi_clk_2x_i          ( dfi_clk_2x          )
	  ,.dfi_clk_1x_o          ( dfi_clk_1x          )
	  ,.ui_clk_sync_rst_o     ( ui_clk_sync_rst     )
	  ,.device_temp_o         ( device_temp         ));
	
	generate
	  for(i=0;i<dq_group_lp;i++) begin: dm_io
	    assign ddr_dm[i]       = !ddr_dm_oen_lo[i]? ddr_dm_lo[i]: 1'bz;
	  end
	  for(i=0;i<dq_group_lp;i++) begin: dqs_io
	    assign ddr_dqs_p[i]    = !ddr_dqs_p_oen_lo[i]? ddr_dqs_p_lo[i]: 1'bz;
	    assign ddr_dqs_p_li[i] = !ddr_dqs_p_ien_lo[i]? ddr_dqs_p[i]: 1'b0;
	    assign ddr_dqs_n[i]    = !ddr_dqs_n_oen_lo[i]? ddr_dqs_n_lo[i]: 1'bz;
	    assign ddr_dqs_n_li[i] = !ddr_dqs_n_ien_lo[i]? ddr_dqs_n[i]: 1'b1;
	  end
	  for(i=0;i<dq_data_width_p;i++) begin: dq_io
	    assign ddr_dq[i]    = !ddr_dq_oen_lo[i]? ddr_dq_lo[i]: 1'bz;
	    assign ddr_dq_li[i] = ddr_dq[i];
	  end
	endgenerate
	
	generate
	  for(i=0;i<2;i++) begin: lpddr
	    mobile_ddr mobile_ddr_inst
	      (.Dq    (ddr_dq[16*i+15:16*i])
	      ,.Dqs   (ddr_dqs_p[2*i+1:2*i])
	      ,.Addr  (ddr_addr[13:0])
	      ,.Ba    (ddr_ba[1:0])
	      ,.Clk   (ddr_ck_p)
	      ,.Clk_n (ddr_ck_n)
	      ,.Cke   (ddr_cke)
	      ,.Cs_n  (ddr_cs_n)
	      ,.Ras_n (ddr_ras_n)
	      ,.Cas_n (ddr_cas_n)
	      ,.We_n  (ddr_we_n)
	      ,.Dm    (ddr_dm[2*i+1:2*i]));
	  end
	endgenerate

	initial begin
		dfi_clk_2x = 0;
		ui_clk = 0;
	end	
	//TODO: akashs3 : no hardcoded clk period vals.
	always #1.25 dfi_clk_2x = ~dfi_clk_2x;
	//always #0.625 ui_clk = ~ui_clk;
	always #2.5 ui_clk = ~ui_clk;
	
	initial begin
		sys_reset = 1;
		//sync initiation delay.
		#200;
		//deassert active low reset
		sys_reset = 0;
	end

	assign asic_if.ui_clk				= ui_clk;
	assign asic_if.ui_clk_sync_rst		= ui_clk_sync_rst;

	initial begin
		init_configuration_values(); 
	end

	initial begin
	  asic_if.app_cmd = 0;
	  asic_if.app_addr = 0;
	  asic_if.app_en = 0;
	  asic_if.app_wdf_wren = 0;
	  asic_if.app_wdf_end = 0;
	end
	
	initial begin
		//UVM config DB is a locker system. 
		//We set and get objects and variables from across the testbench based on access rules configured through arguments of set method while storing it.
		//Here, we pass pointers (virtual interface) of physical interfaces to all components below this hierarchy (* denotes all components). Tthese will be used by components to interact with the DUT.
    	uvm_config_db#(virtual bsg_dmc_asic_interface)::set(null, "*", "asic_if", asic_if);
    	//Call the test - by passing run_test argument as test class name
    	//Another option is to not pass any test argument and use +UVM_TEST on command line to specify which test to run
    	run_test("bsg_dmc_base_test");
	end
	
	task init_configuration_values();

		dmc_p.trefi = 1023;
	    dmc_p.tmrd = 1;
	    dmc_p.trfc = 15;
	    dmc_p.trc = 10;
	    dmc_p.trp = 2;
	    dmc_p.tras = 7;
	    dmc_p.trrd = 1;
	    dmc_p.trcd = 2;
	    dmc_p.twr = 10;
	    dmc_p.twtr = 7;
	    dmc_p.trtp = 10;
	    dmc_p.tcas = 3;
		// TODO: akashs3: bank/row/col widths are specific to x16 DDR. Randomise them while verifying for various mem configurations.
	    dmc_p.col_width = 11;
	    dmc_p.row_width = 14;
	    dmc_p.bank_width = 2;
	    dmc_p.bank_pos = 25;// col_width + row_width

	    dmc_p.dqs_sel_cal = 3;
	    dmc_p.init_cycles = 40010;
	    force dmc_inst.dmc_clk_rst_gen.btc_async_reset.tag_data_reg.data_r = 0;
	    force dmc_inst.dmc_clk_rst_gen.dly_lines[0].dly_line_inst.ctrl_rrr = 31;
	    force dmc_inst.dmc_clk_rst_gen.dly_lines[1].dly_line_inst.ctrl_rrr = 31;
	    force dmc_inst.dmc_clk_rst_gen.dly_lines[2].dly_line_inst.ctrl_rrr = 31;
	    force dmc_inst.dmc_clk_rst_gen.dly_lines[3].dly_line_inst.ctrl_rrr = 31;
	    force dmc_inst.dmc_clk_rst_gen.clk_gen_ds_inst.reset_i = 1'b1;
	    force dmc_inst.dmc_clk_rst_gen.clk_gen_ds_inst.strobe_r = 1'b0;
	    #100;
	    force dmc_inst.dmc_clk_rst_gen.clk_gen_ds_inst.reset_i = 1'b0;
	    force dmc_inst.dmc_clk_rst_gen.clk_gen_ds_inst.strobe_r = 1'b1;

	endtask: init_configuration_values

	  //TODO: akashs3 COMMENTED: REMOVE AFTER FULL TB IS BROUGHT UP.
	  //initial begin
	  //  $display("\n#### Regression test started ####");
	  //  sys_reset = 1'b1;
	  //  ui_clk = 1'b0;
	  //  dfi_clk_2x = 1'b0;
	  //  #1000 sys_reset=1'b0;
	  //  repeat(100) @(posedge ui_clk);
	  //  for(k=0;k<256;k++) begin
	  //    waddr = k*dq_burst_length_lp;
	  //    wdata = 0;
	  //    for(j=0;j<ui_burst_length_p;j++)
	  //      wdata = (wdata << ui_data_width_p) + waddr + j;
	  //    wdata_array[waddr] = wdata;
	  //    $display("Time: %8d ns, Write %x to %x", $time(), wdata, waddr);
	  //    fork
	  //      ui_cmd(`WRITE, waddr);
	  //      ui_write(0, wdata);
	  //    join
	  //  end
	  //  for(k=0;k<256;k++) begin
	  //    raddr = k*dq_burst_length_lp;
	  //    raddr_queue.push_front(raddr);
	  //    ui_cmd(`READ, raddr);
	  //  end
	  //  repeat(1000) @(posedge ui_clk);
	  //  $display("\nRegression test passed!");
	  //  $display("\n#### Regression test ended ####");
	  //  $finish();
	  //end
	
	  //for(i=0;i<ui_burst_length_p;i++) begin
	  //  assign sipo_data[ui_data_width_p*i+:ui_data_width_p] = sipo_data_lo[i];
	  //end
	
	  //bsg_serial_in_parallel_out #
	  //  (.width_p    ( ui_data_width_p   )
	  //  ,.els_p      ( ui_burst_length_p ))
	  //sipo
	  //  (.clk_i      ( ui_clk            )
	  //  ,.reset_i    ( ui_clk_sync_rst   )
	  //  ,.valid_i    ( app_rd_data_valid )
	  //  ,.data_i     ( app_rd_data       )
	  //  ,.ready_o    (                   ) 
	  //  ,.valid_o    ( sipo_valid_lo     )
	  //  ,.data_o     ( sipo_data_lo      )
	  //  ,.yumi_cnt_i ( sipo_yumi_cnt_li  ));
	
	  //assign sipo_yumi_cnt_li = ($clog2(ui_burst_length_p)+1)'(&sipo_valid_lo? ui_burst_length_p: 0);
	
	  //always @(posedge ui_clk) begin
	  //  if(&sipo_valid_lo) begin
	  //    read_transactions = read_transactions + 1;
	  //    rx_addr = raddr_queue.pop_back();
	  //    tx_data = wdata_array[rx_addr];
	  //    rx_data = sipo_data;
	  //    $display("Time: %8d ns, Read %x from %x", $time(), rx_data, rx_addr);
	  //    if(tx_data != rx_data) begin
	  //      $display("Error: Data expected to be %x, but %x received", tx_data, rx_data);
	  //      $display("\nRegression test failed!");
	  //      $finish();
	  //    end
	  //  end
	  //end

endmodule

