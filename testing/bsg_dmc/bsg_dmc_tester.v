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
			parameter cmd_width_p = 4,
		  	//parameter row_width_p = 14,
		  	//parameter col_width_p = 11,
		  	//parameter bank_width_p = 2,
			parameter burst_width_p = 2,
			//parameter lg_fifo_depth_p=6
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
  	logic tr_v_lo;
  	logic [payload_width_lp-1:0] tr_data_lo;
  	logic tr_yumi_li;

  	logic [rom_addr_width_lp-1:0] trace_rom_addr;
  	logic [payload_width_lp +4 - 1:0] trace_rom_data;

  	logic tr_done_lo;

	// FPGA SIDE LINK EDGE SIGNALS
	logic [payload_width_lp/2-1:0] fpga_link_upstream_edge_data;
	logic fpga_link_upstream_edge_valid;
	logic fpga_link_upstream_edge_token;
	logic fpga_link_upstream_edge_clk;
	logic fpga_link_upstream_core_ready_li;
	logic token_reset_0, token_reset_1;

	// ASIC SIDE LINK EDGE SIGNALS
	logic [payload_width_lp/2-1:0] asic_link_downstream_edge_data;
	logic asic_link_downstream_edge_valid;
	logic asic_link_downstream_edge_token;
	logic asic_link_downstream_edge_clk;
	logic asic_link_downstream_core_ready_li;

	logic [payload_width_lp-1:0] asic_link_core_data;
	logic asic_link_core_valid;
	logic asic_link_core_yumi;
  	
  	// FPGA and ASIC side link clock and reset
  	logic fpga_link_clk, asic_link_clk;
  	logic fpga_link_io_clk, asic_link_io_clk;

  	logic fpga_link_reset, asic_link_reset;
  	logic fpga_link_io_reset, asic_link_io_reset;
  
	// DMC input FIFO related signals
	logic [payload_width_lp - 1:0] dmc_adapter_input_data;
	logic dmc_adapter_input_valid;
	logic dmc_adapter_yumi;
	logic dmc_input_fifo_ready;	

	logic dmc_adapter_ready;

	bsg_trace_replay
  	#(  .payload_width_p(payload_width_lp),
  	  	.rom_addr_width_p(6)
  	  ) trace_replay
    	(.clk_i(fpga_link_clk),
    	.reset_i(fpga_link_reset),
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
      ,.width_p(payload_width_lp+4)
    ) trace_rom (
      .addr_i(trace_rom_addr)
      ,.data_o(trace_rom_data)
    );

	assign tr_yumi_li = fpga_link_upstream_core_ready_li ;
	
	// FPGA SIDE LINKS START
	bsg_link_ddr_upstream
 	#(.width_p        (payload_width_lp)
 	 ,.channel_width_p(payload_width_lp/2)
 	 ,.num_channels_p (1)
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
 	 ,.token_clk_i (asic_link_downstream_edge_token)
 	 );
	// FPGA SIDE LINKS END
	
	assign asic_link_core_yumi = asic_link_core_valid & dmc_input_fifo_ready;

	// ASIC SIDE LINKS START
	bsg_link_ddr_downstream
 	#(.width_p        (payload_width_lp)
 	 ,.channel_width_p(payload_width_lp/2)
 	 ,.num_channels_p (1)
 	 ) asic_link_downstream
 	 (.core_clk_i       (asic_link_clk)
 	 ,.core_link_reset_i(asic_link_reset)
 	 ,.io_link_reset_i  (asic_link_io_reset)
 	 
 	 ,.core_data_o   (asic_link_core_data)
 	 ,.core_valid_o  (asic_link_core_valid)
 	 ,.core_yumi_i   (asic_link_core_yumi)

  	 ,.io_clk_i      (fpga_link_upstream_edge_clk)
  	 ,.io_data_i     (fpga_link_upstream_edge_data)
  	 ,.io_valid_i    (fpga_link_upstream_edge_valid)
  	 ,.core_token_r_o(asic_link_downstream_edge_token)
  	 );
	// ASIC SIDE LINKS END

	assign dmc_adapter_yumi = asic_link_core_valid & dmc_adapter_ready;

    bsg_fifo_1r1w_small 
   #(.width_p(payload_width_lp)
    ,.els_p(4)
    ) dmc_input_fifo
    (.clk_i  (asic_link_clk)
    ,.reset_i(asic_link_reset)

    ,.ready_o(dmc_input_fifo_ready)
    ,.data_i (asic_link_core_data)
    ,.v_i    (asic_link_core_valid)

    ,.v_o    (dmc_adapter_input_valid)
    ,.data_o (dmc_adapter_input_data)
    ,.yumi_i (dmc_adapter_yumi)
    );


	bsg_dmc_trace_adapter 
						#(	.data_width_p(data_width_p),
							.addr_width_p(addr_width_p),
							.cmd_width_p(cmd_width_p),
							.burst_width_p(burst_width_p)
						) trace_to_dmc_ui
						(	.core_clk_i(asic_link_clk),
							.core_reset_i(asic_link_reset),
							.trace_data_i(dmc_adapter_input_data),
						 	.trace_data_valid_i(dmc_adapter_input_valid),
						 	.adapter_ready_o(dmc_adapter_ready),
							.app_rdy_i(1'b1)
						 );

  	// Simulation of Clock
  	always #4 fpga_link_clk = ~fpga_link_clk;
  	always #4 asic_link_clk = ~asic_link_clk;
  	always #2 fpga_link_io_clk = ~fpga_link_io_clk;
  	always #2 asic_link_io_clk = ~asic_link_io_clk;
  	
  	
	// below sequence adapted from bsg_wormhole_network_tester.v	
  	initial begin

  	  	$display("Start Simulation\n");
  	
  	  	// Init
  	  	fpga_link_clk = 1;
  	  	asic_link_clk = 1;
  	  	fpga_link_io_clk     = 1;
  	  	asic_link_io_clk     = 1;
  	  	
  	  	fpga_link_io_reset = 1;
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
  	  	
  	  	@(posedge fpga_link_io_clk); #1;
  	  	fpga_link_io_reset = 0;

  	  	@(posedge fpga_link_upstream_edge_clk); #1;
  	  	asic_link_io_reset = 1;
  	  	  
  	  	#1000;
  	  	
  	  	@(posedge asic_link_io_clk); #1;
  	  	asic_link_io_reset = 0;
  	  	
  	  	#1000;
  	  	
  	  	// core link reset
  	  	@(posedge fpga_link_clk); #1;
  	  	fpga_link_reset = 0;
  	  	@(posedge asic_link_clk); #1;
  	  	asic_link_reset = 0;

		@(posedge tr_done_lo); #1000;
		$finish();
	end
endmodule 
