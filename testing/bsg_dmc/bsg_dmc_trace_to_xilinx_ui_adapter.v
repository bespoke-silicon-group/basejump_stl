///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_dmc_trace_to_xilinx_ui_adapter
//  DESCRIPTION: Takes the DMC cmd, addr, wdata, wmask trace packet and converts into XILINX UI interface to feed to DMC
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/07/22
///////////////////////////////////////////////////////////////////////////////////////////////////

module bsg_dmc_trace_to_xilinx_ui_adapter
	import bsg_dmc_pkg::*;
	#(	parameter data_width_p = 32,
		parameter addr_width_p = 28,
		parameter cmd_width_p = 4,
	    parameter burst_width_p = 2,
		localparam payload_width_lp = burst_width_p*(data_width_p + (data_width_p>>3)) + addr_width_p + cmd_width_p,
		localparam data_and_mask_width_lp = burst_width_p*(data_width_p + data_width_p>>3)	
	)
	( 	input 									core_clk_i,
		input									core_reset_i,
		input [payload_width_lp -1 :0] 			trace_data_i,
		input 									trace_data_valid_i,
		output logic							adapter_ready_o,
   		// xilinx user interface
   		output logic [addr_width_p-1:0]        	app_addr_o,
   		output app_cmd_e				    	app_cmd_o,
   		output logic                       		app_en_o,
   		input                              		app_rdy_i,
   		output logic                       		app_wdf_wren_o,
   		output logic [data_width_p-1:0]			app_wdf_data_o,
   		output logic [(data_width_p>>3)-1:0] 	app_wdf_mask_o,
   		output logic                   			app_wdf_end_o,
   		input                              		app_wdf_rdy_i,
   		input                              		app_rd_data_valid_i,
   		input [data_width_p-1:0] 		      	app_rd_data_i,
   		input                              		app_rd_data_end_i
	);

	import bsg_dmc_pkg::*;

	typedef struct packed {
	  	app_cmd_e cmd;
	  	logic [addr_width_p - 1:0] addr;
		logic [burst_width_p*data_width_p -1 :0] data;
		logic [(burst_width_p*data_width_p>>3) - 1 :0] mask;
	} dmc_trace_entry_s;


	// counter to load one packet per burst per cycle onto app_wdata and app_wmask
	logic [$clog2(burst_width_p)-1:0] write_count;

	logic transaction_in_progress;
	logic [data_width_p*burst_width_p - 1:0] feed_to_app_wdata;
	logic [(data_width_p>>3)*burst_width_p - 1:0] feed_to_app_wmask;	

	logic burst_done;
	logic transaction_in_progress;

	dmc_trace_entry_s trace_data;

	assign trace_data = trace_data_i;

	assign adapter_ready_o =  ~transaction_in_progress & app_rdy_i ;

	assign burst_done =  (write_count == burst_width_p - 1);

	assign is_write = trace_data_valid_i ? ((trace_data.cmd == WP || trace_data.cmd == WR) )  : 0;

	assign transaction_in_progress = app_wdf_wren_o; 

	assign app_wdf_end_o = burst_done & app_wdf_wren_o;
	assign app_wdf_data_o = feed_to_app_wdata[write_count*data_width_p+:32];
	assign app_wdf_mask_o = feed_to_app_wmask[(write_count*data_width_p >> 3)+:4];

	// counting write_count per burst
	always_ff @(posedge core_clk_i) begin
		if(core_reset_i) begin
			app_en_o <= 0;
		end
		else if(adapter_ready_o & trace_data_valid_i) begin
			app_cmd_o <= trace_data.cmd;
			app_addr_o <= trace_data.addr;
			app_en_o <= 1;
			{feed_to_app_wdata, feed_to_app_wmask} <= trace_data_i;
		end
		else begin
			app_en_o <= 0;
		end
	end

	//always_ff @(posedge core_clk_i) begin
	//	if(core_reset_i) begin
	//		{feed_to_app_wdata, feed_to_app_wmask} <= '0;
	//	end

	always_ff @(posedge core_clk_i) begin
		if(core_reset_i) begin
			app_wdf_wren_o <= 0;
		end
		else if(is_write & app_rdy_i) begin
			app_wdf_wren_o <= 1;
		end
		else if (burst_done ) begin
			app_wdf_wren_o <= 0;
		end
	end
	
	always_ff @(posedge core_clk_i) begin
		if (is_write || burst_done) begin
			write_count <= 0;
		end
		else begin
			write_count <= write_count + 1;
		end
	end
endmodule: bsg_dmc_trace_to_xilinx_ui_adapter
