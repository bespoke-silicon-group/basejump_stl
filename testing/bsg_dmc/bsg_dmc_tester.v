///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_dmc_tester
//  DESCRIPTION: Tester design for bringing up on-chip DRAM controller
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/04/22
///////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module bsg_dmc_tester
		#(	parameter data_width_p=32,
		  	parameter addr_width_p = 28,
			parameter cmd_width_p = 3,
		  	parameter row_width_p = 14,
		  	parameter col_width_p = 11,
		  	parameter bank_width_p = 2,
			parameter burst_width_p = 2,
			parameter lg_fifo_depth_p=6
		 )
		();

	localparam rom_addr_width_lp=32;
	localparam cmd_plus_address_width_lp = addr_width_p + cmd_width_p;
	localparam data_mask_width_lp = data_width_p>>3;
	localparam payload_width_lp = addr_width_p + cmd_width_p + burst_width_p*(data_width_p + data_mask_width_lp);

  	//  trace replay
  	//
  	//  send trace: {opcode(5), addr, data}
  	//  recv trace: {filler(5+32), data}
  	//logic cmd_addr_tr_v_li;
  	//logic [cmd_plus_address_width_lp-1:0] cmd_addr_tr_data_li;
  	//logic cmd_addr_tr_ready_lo;
  	logic tr_v_lo;
  	logic [payload_width_lp-1:0] tr_data_lo;
  	logic yumi_li;

  	logic [rom_addr_width_lp-1:0] trace_rom_addr;
  	logic [cmd_plus_address_width_lp-1:0] trace_rom_data;

  	logic tr_done_lo;

	// FPGA SIDE LINK EDGE SIGNALS: CMD AND ADDR
	logic [payload_width_lp/2-1:0] fpga_link_upstream_edge_data;
	logic fpga_link_upstream_edge_valid;
	logic fpga_link_upstream_edge_token;
	logic fpga_link_upstream_edge_clk;
	logic fpga_link_upstream_core_ready_li;
	logic token_reset_0, token_reset_1;

	// FPGA SIDE LINK EDGE SIGNALS: WDATA
	//logic [data_width_p + data_mask_width_lp-1:0] wdata_edge_data;
	//logic wdata_edge_valid;
	//logic wdata_edge_token;
	//logic wdata_edge_clk;
  	
  	// FPGA and ASIC side link clock and reset
  	logic fpga_link_clk, asic_link_clk;
  	logic fpga_link_io_clk, asic_link_io_clk;

  	logic fpga_link_reset, asic_link_reset;
  	logic fpga_link_io_reset, asic_link_io_reset;
  	
	bsg_trace_replay
  	#(  .payload_width_p(payload_width_lp),
  	  	.rom_addr_width_p(6)
  	  ) trace_replay
    	(.clk_i(clk),
    	.reset_i(reset),
    	.en_i(1'b1),

    	.v_i(1'b0),
    	.data_i('0),
    	.ready_o(),

    	.v_o(tr_v_lo),
    	.data_o(tr_data_lo),
    	.yumi_i(tr_yumi_li),

    	.rom_addr_o(trace_rom_addr),
    	.rom_data_i(trace_rom_data),

    	.done_o(tr_done_lo),
    	.error_o()
  		);

    bsg_dmc_trace_rom #(
      .addr_width_p(rom_addr_width_lp)
      ,.width_p(payload_width_lp)
    ) trace_rom (
      .addr_i(trace_rom_addr)
      ,.data_o(trace_rom_data)
    );

	// FPGA SIDE LINKS START
	bsg_link_ddr_upstream
 	#(.width_p        (payload_width_lp)
 	 ,.channel_width_p(payload_width_lp/2)
 	 ,.num_channels_p (1)
 	 //,.lg_fifo_depth_p(lg_fifo_depth_p)
 	 //,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
 	 ) fpga_link_upstream
 	 (.core_clk_i         (fpga_link_clk)
 	 ,.io_clk_i           (fpga_link_io_clk)
 	 ,.core_link_reset_i  (fpga_link_reset)
 	 ,.io_link_reset_i    (fpga_link_io_reset)
 	 ,.async_token_reset_i(token_reset_0)
 	 
 	 ,.core_data_i (tr_data_lo)
 	 ,.core_valid_i(tr_v_lo)
 	 ,.core_ready_o(fpga_link_upstream_core_ready_li)

 	 ,.io_clk_r_o  (fpga_link_upstream_edge_clk)
 	 ,.io_data_r_o (fpga_link_upstream_edge_data)
 	 ,.io_valid_r_o(fpga_link_upstream_edge_valid)
 	 ,.token_clk_i (fpga_link_upstream_edge_token)
 	 );
 	 
  	//bsg_link_ddr_upstream
 	//#(.width_p        (link_width_p)
 	// ,.channel_width_p(cmd)
 	// ,.num_channels_p (1)
 	// ,.lg_fifo_depth_p(lg_fifo_depth_p)
 	// ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
 	// ) wdata_link_upstream
 	// (.core_clk_i         (fpga_link_clk)
 	// ,.io_clk_i           (fpga_link_clk)
 	// ,.core_link_reset_i  (fpga_link_reset)
 	// ,.io_link_reset_i    (fpga_link_reset)
 	// ,.async_token_reset_i(token_reset_0)
 	// 
 	// ,.core_data_i (wdata_tr_data_lo)
 	// ,.core_valid_i(wdata_tr_v_lo)
 	// ,.core_ready_o(wdata_tr_yumi_li)

 	// ,.io_clk_r_o  (wdata_edge_clk)
 	// ,.io_data_r_o (wdata_edge_data)
 	// ,.io_valid_r_o(wdata_edge_valid)
 	// ,.token_clk_i (wdata_edge_token)
 	// );

 	 //bsg_link_ddr_downstream
 	 //#(.width_p        (link_width_p)
 	 //,.channel_width_p(channel_width_p)
 	 //,.num_channels_p (1)
 	 //,.lg_fifo_depth_p(lg_fifo_depth_p)
 	 //,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
 	 //) rdata_link_downstream
 	 //(.core_clk_i       (fpga_link_clk)
 	 //,.core_link_reset_i(fpga_link_reset)
 	 //,.io_link_reset_i  (fpga_link_reset)
 	 //
 	 //,.core_data_o   ()
 	 //,.core_valid_o  ()
 	 //,.core_yumi_i   ()

  	 //,.io_clk_i      (rdata_clk)
  	 //,.io_data_i     (rdata_edge_data)
  	 //,.io_valid_i    (rdata_edge_valid)
  	 //,.core_token_r_o(rdata_edge_token)
  	 //);
	// FPGA SIDE LINKS END
	
	// ASIC SIDE LINKS START
	//bsg_link_ddr_downstream
 	//#(.width_p        (link_width_p)
 	// ,.channel_width_p(channel_width_p)
 	// ,.num_channels_p (1)
 	// ,.lg_fifo_depth_p(lg_fifo_depth_p)
 	// ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
 	// ) cmd_addr_link_downstream
 	// (.core_clk_i       (asic_link_clk)
 	// ,.core_link_reset_i(asic_link_reset)
 	// ,.io_link_reset_i  (asic_link_reset)
 	// 
 	// ,.core_data_o   (cmd_addr_asic_data)
 	// ,.core_valid_o  (cmd_addr_asic_valid)
 	// ,.core_yumi_i   (cmd_addr_asic_yumi)

  	// ,.io_clk_i      (cmd_addr_edge_clk)
  	// ,.io_data_i     (cmd_addr_edge_data)
  	// ,.io_valid_i    (cmd_addr_edge_valid)
  	// ,.core_token_r_o(cmd_addr_edge_token)
  	// );

	//bsg_link_ddr_downstream
 	//#(.width_p        (link_width_p)
 	// ,.channel_width_p(channel_width_p)
 	// ,.num_channels_p (1)
 	// ,.lg_fifo_depth_p(lg_fifo_depth_p)
 	// ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
 	// ) wdata_link_downstream
 	// (.core_clk_i       (asic_link_clk)
 	// ,.core_link_reset_i(asic_link_reset)
 	// ,.io_link_reset_i  (asic_link_reset)
 	// 
 	// ,.core_data_o   (out_ct_data_li)
 	// ,.core_valid_o  (out_ct_valid_li)
 	// ,.core_yumi_i   (out_ct_yumi_lo)

  	// ,.io_clk_i      (wdata_edge_clk)
  	// ,.io_data_i     (wdata_edge_data)
  	// ,.io_valid_i    (wdata_edge_valid)
  	// ,.core_token_r_o(wdata_edge_token)
  	// );

  	//bsg_link_ddr_upstream
 	//#(.width_p        (link_width_p)
 	// ,.channel_width_p(channel_width_p)
 	// ,.num_channels_p (1)
 	// ,.lg_fifo_depth_p(lg_fifo_depth_p)
 	// ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
 	// ) rdata_link_upstream
 	// (.core_clk_i         (asic_link_clk)
 	// ,.io_clk_i           (asic_link_clk)
 	// ,.core_link_reset_i  (asic_link_reset)
 	// ,.io_link_reset_i    (asic_link_reset)
 	// ,.async_token_reset_i(token_reset_0)
 	// 
 	// ,.core_data_i ()
 	// ,.core_valid_i()
 	// ,.core_ready_o()

 	// ,.io_clk_r_o  (rdata_edge_clk)
 	// ,.io_data_r_o (rdata_edge_data)
 	// ,.io_valid_r_o(rdata_edge_valid)
 	// ,.token_clk_i (rdata_edge_token)
 	// );
	// ASIC SIDE LINKS END

  	// Simulation of Clock
  	always #3 fpga_link_clk = ~fpga_link_clk;
  	always #3 asic_link_clk = ~asic_link_clk;
  	always #2 fpga_link_io_clk = ~fpga_link_io_clk;
  	always #3 asic_link_io_clk = ~asic_link_io_clk;
  	
  
	// below sequence adapted from bsg_wormhole_network_tester.v	
  	initial begin

  	  $display("Start Simulation\n");
  	
  	  // Init
  	  fpga_link_clk = 1;
  	  asic_link_clk = 1;
  	  fpga_link_io_clk     = 1;
  	  asic_link_io_clk     = 1;
  	  
  	  fpga_link_io_reset = 1;
  	  asic_link_io_reset = 1;
  	  token_reset_0 = 0;
  	  token_reset_1 = 0;
  	  
  	  fpga_link_reset = 1;
  	  asic_link_reset = 1;
  	  
  	  #1000;
  	  
  	  // token async reset
  	  token_reset_0 = 1;
  	  token_reset_1 = 1;
  	  
  	  #1000;
  	  
  	  token_reset_0 = 0;
  	  token_reset_1 = 0;
  	  
  	  #1000;
  	  
  	  // upstream io reset
  	  @(posedge fpga_link_io_clk); #1;
  	  fpga_link_io_reset = 0;
  	  @(posedge asic_link_io_clk); #1;
  	  asic_link_io_reset = 0;
  	  
  	  #100;
  	  
  	  // Reset signals propagate to downstream after io_clk is generated
  	  @(posedge fpga_link_io_clk); #1;
  	  fpga_link_io_reset = 1;
  	  @(posedge asic_link_io_clk); #1;
  	  asic_link_io_reset = 1;
  	    
  	  #1000;
  	  
  	  // downstream IO reset
  	  // edge clock 0 to downstream 1, edge clock 1 to downstream 0
  	  @(posedge fpga_link_io_clk); #1;
  	  fpga_link_io_reset = 0;
  	  @(posedge asic_link_io_clk); #1;
  	  asic_link_io_reset = 0;
  	  
  	  #1000;
  	  
  	  // core link reset
  	  @(posedge fpga_link_clk); #1;
  	  fpga_link_reset = 0;
  	  @(posedge asic_link_clk); #1;
  	  asic_link_reset = 0;
  	  
		#1000;
  	  
   	end
endmodule 
