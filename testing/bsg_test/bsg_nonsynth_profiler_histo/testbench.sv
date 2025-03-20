

// NOTE: it is very important to do a separate vcs/simv run
// and to run simv with -xlrm hier_inst_seed in order for each instance of
// rando to get a different value

module rando (input clk_i);
   logic [3:0] val;
   
   always @(posedge clk_i)
     begin
	val <= 4 ' ( $urandom() & 4'hF );
     end
endmodule


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

   for (geny = 0; geny < 2; geny++)
     begin: ctr
	rando bla(.clk_i(clk));
     end

   
   bind rando bsg_nonsynth_profiler_client_histo      #(.suffix_p("_suff"),.start_p(0),.end_p(32'hF)) u_bind
   (.clk_i(clk_i)
    ,.v_i(1'b1)
    ,.val_i(val)
    );

   bsg_nonsynth_profiler_master #(.max_counters_p(2*(1<<8))) profiler ();

   int foo,bar;
   string path;
   initial
     begin
	for (bar = 0; bar < 16; bar++)
	  begin
	     for (foo = 0; foo < 100; foo++)
	       @(posedge clk);
	     
	     begin
		profiler.dump();
		profiler.clear();
	     end
	  end
	@(posedge clk);
	$finish;
     end
endmodule  
