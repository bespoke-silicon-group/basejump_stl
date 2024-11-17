///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_dmc_xilinx_ui_trace_replay
//  DESCRIPTION: Takes the DMC cmd, addr, wdata, wmask trace packet and converts into XILINX UI interface to feed to DMC;
//  			 And converts UI read interface signals to trace packet to forward to FPGA
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/07/22
///////////////////////////////////////////////////////////////////////////////////////////////////

`include "bsg_defines.sv"

module bsg_dmc_xilinx_ui_trace_replay
	import bsg_dmc_pkg::*;
	#(	parameter `BSG_INV_PARAM( data_width_p),
		parameter `BSG_INV_PARAM( addr_width_p),
		parameter `BSG_INV_PARAM( burst_len_p),
        parameter `BSG_INV_PARAM( tfifo_depth_p),
        parameter `BSG_INV_PARAM( rfifo_depth_p),

		localparam trace_data_width_lp = `bsg_dmc_trace_entry_width(data_width_p, addr_width_p)
	)
	( 	input 									clk_i,
		input									reset_i,

        // Trace data from producer
		output logic     					    ready_and_o,
		input [trace_data_width_lp -1 :0] 		data_i,
		input 									v_i,

        // Read data to consumer
		output logic [data_width_p -1 :0]	    data_o,
		output logic							v_o,
        input                                   yumi_i,

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

    enum {e_fill, e_drain} state_n, state_r;
    wire is_fill = (state_r == e_fill);
    wire is_drain = (state_r == e_drain);

    `declare_bsg_dmc_trace_entry_s(data_width_p, addr_width_p);

    // Only enqueue onto fifo if it's an app_cmd
    bsg_dmc_trace_entry_s trace_data_li;
    logic trace_ready_and_lo, trace_v_li;
    bsg_dmc_trace_entry_s trace_data_lo;
    logic trace_v_lo, trace_yumi_li;
	assign trace_data_li = data_i;
    bsg_fifo_1r1w_small
    				#(.width_p($bits(bsg_dmc_trace_entry_s))
    				,.els_p(tfifo_depth_p)
                    ,.harden_p(1)
    				) trace_fifo
    				(.clk_i  (clk_i)
    				,.reset_i(reset_i)
    				
    				,.data_i (trace_data_li)
    				,.v_i    (trace_v_li)
    				,.ready_param_o(trace_ready_and_lo)
    				
    				,.v_o    (trace_v_lo)
    				,.data_o (trace_data_lo)
    				,.yumi_i (trace_yumi_li)
    				);

    logic read_data_credit;
    bsg_fifo_1r1w_small_credit_on_input
                    #(.width_p(data_width_p)
                    ,.els_p(rfifo_depth_p)
                    ,.harden_p(1)
                    ) read_data_fifo
                    (.clk_i  (clk_i)
                    ,.reset_i(reset_i)

                    ,.data_i (app_rd_data_i)
                    ,.v_i    (app_rd_data_valid_i)
                    ,.credit_o(read_data_credit)

                    ,.v_o    (v_o)
                    ,.data_o (data_o)
                    ,.yumi_i (yumi_i)
                    );

    logic [`BSG_WIDTH(rfifo_depth_p)-1:0] read_credit;

    wire read_avail = (read_credit >= burst_len_p);

    wire trace_is_write = trace_data_lo.app_cmd inside {WP, WR};
    wire trace_is_wdata = trace_data_lo.app_cmd inside {TWD, TWT};
    wire trace_is_wdone = trace_data_lo.app_cmd inside {TWT};
    wire trace_is_read = trace_data_lo.app_cmd inside {RP, RD};
    wire trace_is_nop = trace_data_lo.app_cmd inside {TNP};

    // Count down when sending out read command to precent rfifo from overflowing
    // Assume all reads are burst reads
    bsg_counter_up_down #( .max_val_p(rfifo_depth_p)
                         , .init_val_p(rfifo_depth_p)
                         , .max_step_p(burst_len_p)
                         ) counter

        ( .clk_i(clk_i)
        , .reset_i(reset_i)

        , .up_i(`BSG_WIDTH(burst_len_p)'(read_data_credit))
        , .down_i(`BSG_WIDTH(burst_len_p)'((app_en_o & app_rdy_i & trace_is_read)*burst_len_p))

        , .count_o(read_credit)
        );

    always_comb begin
      state_n = state_r;

      ready_and_o = '0;

      app_en_o = '0;
      app_cmd_o = trace_data_lo.app_cmd;
      app_addr_o = trace_data_lo.payload.cmd.addr;
      app_wdf_data_o = trace_data_lo.payload.wdata.data;
      app_wdf_mask_o = trace_data_lo.payload.wdata.mask;
      app_wdf_wren_o = '0;
      app_wdf_end_o = '0;

      trace_v_li = '0;
      trace_yumi_li = '0;

      // If trace fifo is full and there is an incoming command,
      // jump to e_drain state automatically to prevent getting stuck
      case(state_r)
        e_fill: begin
          ready_and_o = trace_ready_and_lo;
          trace_v_li = v_i & (trace_data_li.app_cmd != TEX);

          state_n = (v_i & (trace_data_li.app_cmd == TEX || ready_and_o == '0)) ? e_drain : e_fill;
        end
        e_drain: begin
          app_en_o = trace_v_lo & (trace_is_write | (trace_is_read & read_avail));

          app_wdf_wren_o = trace_v_lo & trace_is_wdata;
          app_wdf_end_o = trace_v_lo & trace_is_wdone;

          trace_yumi_li = trace_v_lo & ((app_rdy_i & app_en_o) || (app_wdf_wren_o & app_wdf_rdy_i) || (trace_is_nop));

          // Transition to fill once the fifo is empty
          state_n = (trace_v_lo == '0) ? e_fill : e_drain;
        end
        default: begin end
      endcase
    end

    // synopsys sync_set_reset "reset_i"
    always_ff @(posedge clk_i) begin
      if (reset_i)
        state_r <= e_fill;
      else
        state_r <= state_n;
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_dmc_xilinx_ui_trace_replay)

