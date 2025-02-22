module testbench();

  parameter els_p = 32;
  parameter lg_els_lp = `BSG_SAFE_CLOG2(els_p);

  bit clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg0 (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(8)
  ) rg0 (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

   genvar geny;

   for (geny = 0; geny < 100; geny++)
     begin: ctr
	bsg_cycle_counter #(.width_p(32)
			    ) ctr
	       (.clk_i(clk)
		,.reset_i(reset)
		,.ctr_r_o()
		);
     end
   
   bind bsg_cycle_counter bsg_nonsynth_profile_client      #(.suffix_p("_suff")) u_bind
   (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.countme_i(ctr_r_o[0] ^ ctr_r_o[1])
    );

   bsg_nonsynth_profile_master #(.max_counters_p(1000)) profiler (.clk_i(clk),.reset_i(reset));

   int foo;
   string path;
   initial
     begin
	@(negedge reset);
	@(posedge clk);
	@(posedge clk);	
	@(posedge clk);
	@(posedge clk);
	@(posedge clk);	
	@(posedge clk);
	$finish;
     end
endmodule  
