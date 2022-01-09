///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_dmc_trace_adapter
//  DESCRIPTION: Takes the DMC cmd, addr, wdata, wmask trace packet and converts into XILINX UI interface to feed to DMC
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/07/22
///////////////////////////////////////////////////////////////////////////////////////////////////

module bsg_dmc_trace_adapter
	#(	parameter data_width_p = 32,
		parameter addr_width_p = 28,
		parameter cmd_width_p = 4,
	    parameter burst_width_p = 2,
		localparam payload_width_lp = burst_width_p*(data_width_p + (data_width_p>>3)) + addr_width_p + cmd_width_p )

	( 	input 									core_clk_i,
		input									core_reset_i,
		input [payload_width_lp -1 :0] 			trace_data_i,
		input 									trace_data_valid_i,
		output logic							adapter_ready_o,
   		// xilinx user interface
   		output logic [addr_width_p-1:0]         app_addr_o,
   		output logic [cmd_width_p-1:0]          app_cmd_o,
   		output                             		app_en_o,
   		input                              		app_rdy_i,
   		output                             		app_wdf_wren_o,
   		output logic [data_width_p-1:0]			app_wdf_data_o,
   		output logic [(data_width_p>>3)-1:0] 	app_wdf_mask_o,
   		output logic                       		app_wdf_end_o,
   		input                              		app_wdf_rdy_i,
   		input                              		app_rd_data_valid_i,
   		input [data_width_p-1:0]       			app_rd_data_i,
   		input                              		app_rd_data_end_i
	);

	import bsg_dmc_pkg::*;

	localparam data_and_mask_width_lp = burst_width_p*(data_width_p + data_width_p>>3);

	typedef struct packed {
	  	dfi_cmd_e cmd;
	  	logic [addr_width_p - 1:0] addr;
		logic [burst_width_p*data_width_p -1 :0] data;
		logic [(burst_width_p*data_width_p>>3) - 1 :0] mask;
	} dmc_trace_entry_s;



	// store 1d array of data mask into a 2d array of size burst_size * data_width 
	logic [burst_width_p - 1:0][data_width_p - 1:0] wdata_per_burst_2d_packed;
	logic [burst_width_p - 1:0][(data_width_p/8) - 1:0] wmask_per_burst_2d_packed;

	logic [data_width_p - 1:0] wdata_in_2d_unpacked [burst_width_p - 1:0];
	logic [(data_width_p>>3) - 1:0] wmask_in_2d_unpacked [burst_width_p - 1:0];

	// load one packet per burst per cycle onto app_wdata and app_wmask
	logic [$clog2(burst_width_p)-1:0] write_count;

	dmc_trace_entry_s trace_data;

	assign trace_data = trace_data_i;

	assign adapter_ready_o = app_rdy_i;

	assign app_cmd_o = trace_data.cmd;
	assign app_addr_o = trace_data.addr;
	assign app_en_o = trace_data_valid_i & adapter_ready_o ;

	assign app_wdf_wren_o = app_en_o & ~app_cmd_o[0];

	bsg_make_2D_array 
					#(.width_p(data_width_p),
					  .items_p(burst_width_p)
					) make_wdata_2D_array
					(.i(trace_data.data),
					 .o(wdata_in_2d_unpacked)
					);

	assign wdata_per_burst_2d_packed = {>>{wdata_in_2d_unpacked}};

	bsg_make_2D_array 
					#(.width_p(data_width_p>>3),
					  .items_p(burst_width_p)
					) make_wmask_2D_array
					(.i(trace_data.mask),
					 .o(wmask_in_2d_unpacked)
					);

	assign wmask_per_burst_2d_packed = {>>{wmask_in_2d_unpacked}};

	always_ff @(posedge core_clk_i) begin
		if(core_reset_i) begin
			write_count <= 0;
			app_wdf_end_o <= 0;
		end
		else if(app_wdf_wren_o && app_rdy_i) begin
			if(write_count == burst_width_p -1) begin
				write_count <= 0;
				app_wdf_end_o <= 1;
			end
			else begin
				write_count <= write_count + 1;
				app_wdf_end_o <= 0;				
			end
		end
	end

	bsg_mux 
		#(	.width_p(data_width_p),
			.els_p(burst_width_p)
		) app_wdata_mux
		(	.data_i(wdata_per_burst_2d_packed),
			.sel_i(write_count),
			.data_o(app_wdf_data_o)
		);
				  
	bsg_mux 
		#(	.width_p(data_width_p>>3),
			.els_p(burst_width_p)
		) app_wmask_mux
		(	.data_i(wmask_per_burst_2d_packed),
			.sel_i(write_count),
			.data_o(app_wdf_mask_o)
		);

endmodule: bsg_dmc_trace_adapter
