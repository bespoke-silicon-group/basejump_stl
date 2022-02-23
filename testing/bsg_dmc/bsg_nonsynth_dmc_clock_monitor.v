///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: bsg_nonsynth_dmc_clock_monitor
//  DESCRIPTION: Monitors DDR clock frequency with respect to the FPGA clock frequency.
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/23/22
///////////////////////////////////////////////////////////////////////////////////////////////////
module bsg_nonsynth_dmc_clock_monitor
				#(  parameter counter_width_p = 1024
					,parameter sampling_period_ns_p = 100
					,`BSG_INV_PARAM(max_fpga_count)
					,`BSG_INV_PARAM(expected_ddr_period_ns_p)
					,`BSG_INV_PARAM(fpga_clk_period_ns_p)
				)
			   		//parameter period_tolerance_p = 0	)
				(input fpga_clk,
				 input fpga_reset,
				 input ddr_clk_i,
				 output logic frequency_mismatch_o
				);

	logic [$clog2(counter_width_p) - 1 : 0] fpga_counter_lo;
	bit fpga_counter_clear_li, ddr_counter_clear_li, tally_freq;
	logic [$clog2(counter_width_p) - 1 : 0] ddr_clock_gray_count_lo;
	logic [$clog2(counter_width_p) - 1 : 0] ddr_clock_binary_count_lo, prev_ddr_binary_count;

	logic reset_async_gray_counter;

	real ddr_count_start_time, ddr_cycle_time, fpga_count_start_time, fpga_cycle_time ;

	// counter to clock 100 ns on fpga clock
	bsg_counter_clear_up 
				#(.max_val_p(counter_width_p-1),
				  .init_val_p(0))
				fpga_clock_counter
				(.clk_i(fpga_clk),
				 .reset_i(fpga_reset),
				 .clear_i(fpga_counter_clear_li),
				 .up_i(1'b1),
				 .count_o(fpga_counter_lo)
				);

	// gray counter to count ddr clock ticks and read it in the fpga clock domain
	logic async_ptr_increment;

	bsg_async_ptr_gray
				#(.lg_size_p($clog2(counter_width_p)))
				ddr_clk_async_gray_counter
			    (.w_clk_i(ddr_clk_i),
				 .w_reset_i(fpga_counter_clear_li | fpga_reset),
				 .w_inc_i(1'b1),
				 .r_clk_i(fpga_clk),
                 .w_ptr_binary_r_o(),
                 .w_ptr_gray_r_o(),
				 .w_ptr_gray_r_rsync_o(ddr_clock_gray_count_lo)
				);

	// convert gray counter value received above to binary for correlating with fpga clock ticks and finding the time period
	bsg_gray_to_binary
				#(.width_p($clog2(counter_width_p)))
				ddr_clock_tick_gray_to_binary
				(.gray_i(ddr_clock_gray_count_lo),
				 .binary_o(ddr_clock_binary_count_lo)
				);
	
	// non-synthesisable for now
	always_comb begin
		frequency_mismatch_o = 0;
		if(ddr_clock_binary_count_lo == 0) begin
			ddr_cycle_time = $realtime - ddr_count_start_time;			
			ddr_count_start_time = $time;

			//$display("fpga time: %d ddr time: %d previous binary count: %d",fpga_cycle_time , ddr_cycle_time, prev_ddr_binary_count);
			if(prev_ddr_binary_count >= ((max_fpga_count-1)*fpga_clk_period_ns_p/expected_ddr_period_ns_p)) begin
				//$display("success");
				frequency_mismatch_o = 1;
			end

		end
		prev_ddr_binary_count = ddr_clock_binary_count_lo;
		if((ddr_clock_binary_count_lo >= ((max_fpga_count )*fpga_clk_period_ns_p/expected_ddr_period_ns_p)) && (!ddr_counter_clear_li) ) begin
			ddr_counter_clear_li = 1;
		end
		else begin
			ddr_counter_clear_li = 0;
		end
	end

	always_comb begin
		if(fpga_counter_lo == 1) begin
			fpga_cycle_time = $realtime - fpga_count_start_time;																
			fpga_count_start_time = $realtime;
		end
		if(fpga_counter_lo >= max_fpga_count ) begin
			fpga_counter_clear_li = 1;
		end
		else begin
			fpga_counter_clear_li = 0;
		end
	end
	
endmodule

module ddr_clock_monitor_tb;

	logic fpga_clk;
	logic fpga_reset;
	logic ddr_clk;
	logic frequency_mismatch;

	bsg_nonsynth_dmc_clock_monitor
   					#(.max_fpga_count(20)
					  ,.expected_ddr_period_ns_p(2.5)
					  ,.fpga_clk_period_ns_p(5)
					)	
					ddr_clock_mon
					(	.fpga_clk(fpga_clk)
						,.fpga_reset(fpga_reset)
						,.ddr_clk_i(ddr_clk)
						,.frequency_mismatch_o(frequency_mismatch)
					);

	initial begin
		fpga_clk = 0;
		ddr_clk = 0;
		fpga_reset = 1;
		#100;
		fpga_reset = 0;
	end

	always #2.5ns fpga_clk = ~fpga_clk;
	always #1.25ns ddr_clk = ~ddr_clk;

endmodule
