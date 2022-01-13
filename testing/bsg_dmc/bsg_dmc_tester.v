///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_dmc_tester
//  DESCRIPTION: Tester design for bringing up on-chip DRAM controller
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/04/22
///////////////////////////////////////////////////////////////////////////////////////////////////

module bsg_dmc_tester
	  	import bsg_dmc_pkg::*;
		#(	parameter data_width_p=32,
		  	parameter addr_width_p = 28,
			parameter cmd_width_p = 4,
			parameter burst_width_p = 2,

  			localparam mask_width_lp   = data_width_p >> 3,
			localparam rom_addr_width_lp=32,
			localparam cmd_plus_address_width_lp = addr_width_p + cmd_width_p,
			localparam data_mask_width_lp = data_width_p>>3,
			localparam payload_width_lp = addr_width_p + cmd_width_p + burst_width_p*(data_width_p + data_mask_width_lp)
		 )
		(	input 							fpga_link_clk_i,
			input 							fpga_link_io_clk_i,
			input 							fpga_link_reset_i,
			input 							fpga_link_io_reset_i,
			input 							fpga_link_token_reset_i,

			input							en_trace_reading_i,

			output							fpga_link_upstream_edge_clk_o,
			input							asic_link_downstream_edge_token_i,
			output [payload_width_lp/2-1:0] fpga_link_upstream_edge_data_o,
			output 							fpga_link_upstream_edge_valid_o
		);


  
  	//  trace replay
  	//
  	//  send trace: {opcode(5), addr, data}
  	//  recv trace: {filler(5+32), data}
  	logic trace_valid_lo;
  	logic [payload_width_lp-1:0] trace_data_lo;
  	logic trace_yumi_li;

  	logic [rom_addr_width_lp-1:0] trace_rom_addr_lo;
  	logic [payload_width_lp +4 - 1:0] trace_rom_data_lo;

  	logic trace_reading_done_lo;

	// FPGA SIDE LINK EDGE SIGNALS
	logic fpga_link_upstream_edge_token;
	logic fpga_link_upstream_edge_clk;
	logic fpga_link_upstream_core_ready_lo;

	bsg_trace_replay
  	#(  .payload_width_p(payload_width_lp),
  	  	.rom_addr_width_p(6)
  	  ) trace_replay
    	(.clk_i(fpga_link_clk_i),
    	.reset_i(fpga_link_reset_i),
    	.en_i(en_trace_reading_i),

    	.v_i(1'b0),
    	.data_i('0),
    	.ready_o(),

    	.v_o(trace_valid_lo),
    	.data_o(trace_data_lo),
    	.yumi_i(trace_yumi_li),

    	.rom_addr_o(trace_rom_addr_lo),
    	.rom_data_i(trace_rom_data_lo),

    	.done_o(trace_reading_done_lo),
    	.error_o()
  		);

    bsg_dmc_trace_rom #(
      .addr_width_p(rom_addr_width_lp)
      ,.width_p(payload_width_lp+4)
    ) trace_rom (
      .addr_i(trace_rom_addr_lo)
      ,.data_o(trace_rom_data_lo)
    );

	assign trace_yumi_li = fpga_link_upstream_core_ready_lo ;
	assign fpga_link_upstream_edge_clk_o = fpga_link_upstream_edge_clk;

	// FPGA SIDE LINKS START
	bsg_link_ddr_upstream
 	#(.width_p        (payload_width_lp)
 	 ,.channel_width_p(payload_width_lp/2)
 	 ,.num_channels_p (1)
 	 ) fpga_link_upstream
 	 (.core_clk_i         (fpga_link_clk_i)
 	 ,.io_clk_i           (fpga_link_io_clk_i)
 	 ,.core_link_reset_i  (fpga_link_reset_i)
 	 ,.io_link_reset_i    (fpga_link_io_reset_i)
 	 ,.async_token_reset_i(fpga_link_token_reset_i)
 	 
 	 ,.core_data_i (trace_data_lo)
 	 ,.core_valid_i(trace_valid_lo)
 	 ,.core_ready_o(fpga_link_upstream_core_ready_lo)

 	 ,.io_clk_r_o  (fpga_link_upstream_edge_clk)
 	 ,.io_data_r_o (fpga_link_upstream_edge_data_o)
 	 ,.io_valid_r_o(fpga_link_upstream_edge_valid_o)
 	 ,.token_clk_i (asic_link_downstream_edge_token_i)
 	 );
	// FPGA SIDE LINKS END
	
  	// Simulation of Clock
  	//always #4 fpga_link_clk = ~fpga_link_clk;
  	//always #4 asic_link_clk = ~asic_link_clk;
  	//always #2 fpga_link_io_clk = ~fpga_link_io_clk;
  	//always #2 asic_link_io_clk = ~asic_link_io_clk;
  	//
  	//
	//// below sequence adapted from bsg_wormhole_network_tester.v	
  	//initial begin

  	//  	$display("Start Simulation\n");
  	//
  	//  	// Init
  	//  	fpga_link_clk = 1;
  	//  	asic_link_clk = 1;
  	//  	fpga_link_io_clk     = 1;
  	//  	asic_link_io_clk     = 1;
  	//  	
  	//  	fpga_link_io_reset = 1;
  	//  	fpga_link_token_reset = 0;
  	//  	asic_link_token_reset = 0;
  	//  	
  	//  	fpga_link_reset = 1;
  	//  	asic_link_reset = 1;
  	//  	
  	//  	#1000;
  	//  	
  	//  	// token async reset
  	//  	fpga_link_token_reset = 1;
  	//  	asic_link_token_reset = 1;
  	//  	
  	//  	#1000;
  	//  	
  	//  	fpga_link_token_reset = 0;
  	//  	asic_link_token_reset = 0;
  	//  	
  	//  	#1000;
  	//  	
  	//  	@(posedge fpga_link_io_clk); #1;
  	//  	fpga_link_io_reset = 0;

  	//  	@(posedge fpga_link_upstream_edge_clk); #1;
  	//  	asic_link_io_reset = 1;
  	//  	  
  	//  	#1000;
  	//  	
  	//  	@(posedge asic_link_io_clk); #1;
  	//  	asic_link_io_reset = 0;
  	//  	
  	//  	#1000;
  	//  	
  	//  	// core link reset
  	//  	@(posedge fpga_link_clk); #1;
  	//  	fpga_link_reset = 0;
  	//  	@(posedge asic_link_clk); #1;
  	//  	asic_link_reset = 0;

	//	@(posedge trace_reading_done_lo); #1000;
	//	$finish();
	//end
endmodule 
