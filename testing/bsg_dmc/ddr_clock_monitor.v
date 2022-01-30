///////////////////////////////////////////////////////////////////////////////////////////////////
//    		BASEJUMP STL
//
//       MODULE: ddr_clock_monitor
//  DESCRIPTION: Monitors DDR clock frequency with respect to the FPGA clock frequency.
//    AUTHOR(S): Akash Suresh, akashs3@uw.edu
// ORGANIZATION: Bespoke Silicon Group, University of Washington
//      CREATED: 01/23/22
///////////////////////////////////////////////////////////////////////////////////////////////////

module ddr_clock_monitor 
				#(  parameter counter_width_p = 1024,
					parameter sampling_period_ns_p = 100,
					`BSG_INV_PARAM(max_fpga_count),
					`BSG_INV_PARAM(expected_ddr_period_p),
			   		parameter period_tolerance_p = 0	)
				(input fpga_clk,
				 input fpga_reset,
				 input ddr_clk_i,
				 output logic frequency_mismatch_o
				);

	localparam max_ddr_period_lp =  expected_ddr_period_p *( 1 + period_tolerance_p);
	localparam min_ddr_period_lp =  expected_ddr_period_p *( 1 - period_tolerance_p);

	logic [$clog2(counter_width_p) - 1 : 0] fpga_counter_lo;
	logic fpga_counter_clear_li;
	logic fpga_counter_up_li;
	logic [$clog2(counter_width_p) - 1 : 0] ddr_clock_gray_count_lo;
	logic [$clog2(counter_width_p) - 1 : 0] ddr_clock_binary_count_lo;

	logic reset_async_gray_counter;

	real count_start_time, cycle_time;
	int prev_count;

	// counter to clock 100 ns on fpga clock
	bsg_counter_clear_up 
				#(.max_val_p(counter_width_p),
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
				 .w_reset_i(fpga_counter_clear_li),
				 .w_inc_i(1'b1),
				 .r_clk_i(fpga_clk),
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
		fpga_counter_clear_li = 0;
		frequency_mismatch_o = 0;
		//
		if(ddr_clock_binary_count_lo ==0) begin
			count_start_time = $time;
		end

		if(ddr_clock_binary_count_lo == max_fpga_count*4) begin
			cycle_time = $realtime - count_start_time;
			//fpga_counter_clear_li = 1;
			$display("cycle period: %d", cycle_time);
		end

		if(fpga_counter_lo == max_fpga_count + 1) begin
			fpga_counter_clear_li = 1;
			
			if( ((ddr_clock_binary_count_lo * max_ddr_period_lp) >  sampling_period_ns_p ) && 
		   		((ddr_clock_binary_count_lo * min_ddr_period_lp) <  sampling_period_ns_p )	) begin
					$display("Time period seen %d within limits of %d and %d ns", (sampling_period_ns_p/ddr_clock_binary_count_lo), max_ddr_period_lp, min_ddr_period_lp);
			end
			//else begin
			//	$display("Time period seen %d exceeds limit of %d and %d ns", (sampling_period_ns_p/ddr_clock_binary_count_lo), max_ddr_period_lp, min_ddr_period_lp);
			//	frequency_mismatch_o = 1;
			//end
		end
			
	end

endmodule: ddr_clock_monitor

module ddr_clock_monitor_tb;

	logic fpga_clk;
	logic fpga_reset;
	logic ddr_clk;
	logic frequency_mismatch;

	ddr_clock_monitor
   					#(.max_fpga_count(25)
					  ,.expected_ddr_period_p(1)
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
	always #2ns fpga_clk = ~fpga_clk;
	always #0.5ns ddr_clk = ~ddr_clk;


endmodule: ddr_clock_monitor_tb
