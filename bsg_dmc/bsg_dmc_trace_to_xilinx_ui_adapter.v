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

		localparam payload_width_lp = data_width_p + (data_width_p>>3) + 4,
		localparam mask_width_lp = data_width_p>>3
	)
	( 	input 									core_clk_i,
		input									core_reset_i,

        // Trace data from producer
		output      							ready_o,
		input [payload_width_lp -1 :0] 			data_i,
		input 									v_i,

        // Read data to consumer
		output logic [payload_width_lp -1 :0]	data_o,
		output logic							v_o,

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

    localparam cmd_trace_zero_padding_width_lp = data_width_p + mask_width_lp - cmd_width_p - addr_width_p;
	`declare_dmc_cmd_trace_entry_s(addr_width_p, cmd_trace_zero_padding_width_lp)

	// counter to load one packet per burst per cycle onto app_wdata and app_wmask
	logic [`BSG_SAFE_CLOG2(burst_width_p) - 1:0] write_count;

	logic transaction_in_progress;

	logic burst_done;

	dmc_trace_entry_s trace_data;

	assign trace_data = data_i;

	assign ready_o =  ~transaction_in_progress & app_rdy_i ;

	assign burst_done =  (write_count == burst_width_p  - 1);

	assign is_write = (v_i && trace_data.cmd_wdata_n) ? ((trace_data.cmd == WP) || (trace_data.cmd == WR) )  : 0;

    /*
    This module is at a level above the dmc_controller where we stall transactions. So this module issues transactions to the dmc_controller which decides whether to forward it to DRAM or not.
    So this transaction_in_progress is between the adapter and dmc_controller.
    For the case of clock change happening right when a read is in progress, the time for tag value to reflect on the chip side will sufficient to cover the previous read/write transaction.
    */
	assign transaction_in_progress = app_wdf_wren_o | app_rd_data_valid_i; 

	assign app_wdf_end_o = burst_done & app_wdf_wren_o;

	assign {feed_to_app_wdata, feed_to_app_wmask} = data_i;
	
	// counting write_count per burst
	bsg_counter_clear_up
					#(.max_val_p(burst_width_p - 1)
					,.init_val_p(0)
                    ,.disable_overflow_warning_p(1))
					write_counter
					(.clk_i(core_clk_i)
					,.reset_i(core_reset_i)
					,.clear_i(1'b0)                        
					,.up_i(app_wdf_wren_o & app_wdf_rdy_i )
					,.count_o(write_count)
					);
	
	// Convert UI command and addr
    always_comb begin
        if(v_i &&   app_rdy_i && trace_data.cmd_wdata_n ) begin
            if((trace_data.cmd == WR) || (trace_data.cmd == WP) && app_wdf_rdy_i) begin
                app_en_o = 1;
            end
            else if((trace_data.cmd == RD) || (trace_data.cmd == RP)) begin
                app_en_o = 1;
            end
        end
        else begin
            app_en_o = 0;
        end
    end

	assign app_cmd_o = trace_data.cmd;
	assign app_addr_o = trace_data.addr;

    always @(posedge core_clk_i) begin
        if(core_reset_i) begin
            app_wdf_wren_o <= 0;
        end
        else if(is_write && app_wdf_rdy_i & v_i) begin
            app_wdf_wren_o <= 1;
        end
        else if(burst_done) begin
            app_wdf_wren_o <= 0;
        end
    end

    assign app_wdf_data_o = data_i[35:4];
    assign app_wdf_mask_o = data_i[3:0];

    bsg_fifo_1r1w_small 
    				#(.width_p(payload_width_lp)
    				,.els_p(10)
    				) dmc_output_fifo
    				(.clk_i  (ui_clk)
    				,.reset_i(asic_link_reset_li)
    				
    				,.ready_o(dmc_input_fifo_ready_lo)
    				,.data_i (asic_link_downstream_core_data_lo)
    				,.v_i    (asic_link_downstream_core_valid_lo)
    				
    				,.v_o    (dmc_adapter_input_valid_lo)
    				,.data_o (dmc_adapter_input_data_lo)
    				,.yumi_i (dmc_adapter_yumi_lo)
    				);

	assign data_o =  app_rd_data_i;
	assign v_o = app_rd_data_valid_i ? 1 : 0;
endmodule
