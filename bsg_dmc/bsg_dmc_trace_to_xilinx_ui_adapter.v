///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_dmc_trace_to_xilinx_ui_adapter
//  DESCRIPTION: Takes the DMC cmd, addr, wdata, wmask trace packet and converts into XILINX UI interface to feed to DMC;
//  			 And converts UI read interface signals to trace packet to forward to FPGA
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/07/22
///////////////////////////////////////////////////////////////////////////////////////////////////

module bsg_dmc_trace_to_xilinx_ui_adapter
	import bsg_dmc_pkg::*;
	#(	parameter `BSG_INV_PARAM( data_width_p),
		parameter `BSG_INV_PARAM( addr_width_p),
		parameter `BSG_INV_PARAM( cmd_width_p),
		parameter `BSG_INV_PARAM( burst_width_p),

		localparam payload_width_lp = burst_width_p*(data_width_p + (data_width_p>>3)) + addr_width_p + cmd_width_p,
		localparam mask_width_lp = data_width_p>>3
	)
	( 	input 									core_clk_i,
		input									core_reset_i,

		input [payload_width_lp -1 :0] 			trace_data_i,
		input 									trace_data_valid_i,

		output logic [payload_width_lp -1 :0]	read_data_to_consumer_o,
		output logic							read_data_to_consumer_valid_o,

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

	`declare_dmc_trace_entry_s(addr_width_p, burst_width_p, data_width_p)

	// counter to load one packet per burst per cycle onto app_wdata and app_wmask
	logic [$clog2(burst_width_p)-1:0] write_count;

	logic transaction_in_progress;
	logic [data_width_p*burst_width_p - 1:0] feed_to_app_wdata;
	logic [(data_width_p>>3)*burst_width_p - 1:0] feed_to_app_wmask;	

	logic burst_done;

	dmc_trace_entry_s trace_data;

	assign trace_data = trace_data_i;

	assign adapter_ready_o =  ~transaction_in_progress & app_rdy_i ;

	assign burst_done =  (write_count == burst_width_p - 1);

	assign is_write = trace_data_valid_i ? ((trace_data.cmd == WP || trace_data.cmd == WR) )  : 0;

	assign transaction_in_progress = app_wdf_wren_o | app_rd_data_valid_i; 

	assign app_wdf_end_o = burst_done & app_wdf_wren_o;

	assign {feed_to_app_wdata, feed_to_app_wmask} = trace_data_i;
	
	// counting write_count per burst
	always_ff @(posedge core_clk_i) begin
		if(core_reset_i) begin
			write_count <= 0;
		end
		else if(app_wdf_wren_o) begin
			if(write_count == (burst_width_p -1)) begin
				write_count <= write_count + 1;
			end
			else begin
				write_count <= write_count + 1;
			end
		end
	end

	// Convert UI command and addr
	always_ff @(posedge core_clk_i) begin
		if(core_reset_i) begin
			app_en_o <= 0;
		end
		else if(adapter_ready_o & trace_data_valid_i) begin
			app_cmd_o <= trace_data.cmd;
			app_addr_o <= trace_data.addr;
			app_en_o <= 1;
		end
		else begin
			app_en_o <= 0;
		end
	end

	logic tx_data_piso_ready_lo, tx_mask_piso_ready_lo;

	logic piso_input_valid;
	assign piso_input_valid = ~burst_done & is_write;

	// Break down write data and mask from trace packet to propagate one packet per clock cycle over burst length number of cycles.
  	bsg_parallel_in_serial_out #
  	  (.width_p ( data_width_p      )
  	  ,.els_p   ( burst_width_p  )
	  )
  	tx_data_piso
  	  (.clk_i   ( core_clk_i             )
  	  ,.reset_i ( core_reset_i    )
  	  ,.valid_i ( piso_input_valid )
  	  ,.data_i  ( feed_to_app_wdata  )
  	  ,.ready_and_o ( tx_data_piso_ready_lo ) 
  	  ,.valid_o ( app_wdf_wren_o )
  	  ,.data_o  ( app_wdf_data_o  )
  	  ,.yumi_i  ( app_wdf_wren_o  )
	 );

  	bsg_parallel_in_serial_out #
  	  (.width_p ( data_width_p >>3)
  	  ,.els_p   ( burst_width_p   )
	  )
  	tx_mask_piso
  	  (.clk_i   ( core_clk_i             )
  	  ,.reset_i ( core_reset_i    )
  	  ,.valid_i ( piso_input_valid )
  	  ,.data_i  ( feed_to_app_wmask  )
  	  ,.ready_and_o ( tx_mask_piso_ready_lo ) 
  	  ,.valid_o (  )
  	  ,.data_o  ( app_wdf_mask_o )
	  ,.yumi_i  ( app_wdf_wren_o  )
	);


	logic read_data_sipo_ready_lo;
	logic [burst_width_p-1:0] read_data_sipo_valid_lo;
	logic [data_width_p*burst_width_p - 1: 0] read_data_sipo_data_lo;
	logic [$clog2(burst_width_p):0] read_data_sipo_yumi_cnt_li;

	assign read_data_sipo_yumi_cnt_li = ($clog2(burst_width_p)+1)'(&read_data_sipo_valid_lo? burst_width_p: 0);

	always_ff @(posedge core_clk_i) begin
		if(&read_data_sipo_valid_lo) begin
			read_data_to_consumer_o <= read_data_sipo_data_lo;
			read_data_to_consumer_valid_o <= 1;
		end
		else begin
			read_data_to_consumer_o <= 0;
			read_data_to_consumer_valid_o <= 0;
		end
	end

	logic read_data_sipo_input_valid;

	// Accumulate read data over burst length number of cycles and give out a composite to be sent to trace replay on FPGA
	bsg_serial_in_parallel_out #
	  (.width_p    ( data_width_p    )
	  ,.els_p      ( burst_width_p ))
	read_data_sipo
	  (.clk_i      ( core_clk_i        )
	  ,.reset_i    ( core_reset_i )
	  ,.valid_i    ( app_rd_data_valid_i )
	  ,.data_i     ( app_rd_data_i       )
	  ,.ready_o    ( read_data_sipo_ready_lo)
	  ,.valid_o    ( read_data_sipo_valid_lo     )
	  ,.data_o     ( read_data_sipo_data_lo      )
	  ,.yumi_cnt_i ( read_data_sipo_yumi_cnt_li  ));

endmodule: bsg_dmc_trace_to_xilinx_ui_adapter
