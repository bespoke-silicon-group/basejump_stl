

// NOTE: it is very important to do a separate vcs/simv run
// and to run simv with -xlrm hier_inst_seed in order for each instance of
// rando to get a different value

module rando (input clk_i);
   logic [31:0] val;
   
   always @(posedge clk_i)
     begin
	val <= $urandom() & 32'h0000_FFFF;
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

   for (geny = 0; geny < 100; geny++)
     begin: ctr
	rando bla(.clk_i(clk));
     end

   
   bind rando bsg_nonsynth_profiler_client_add      #(.suffix_p("_suff")) u_bind
   (.clk_i(clk_i)
    ,.countme_i(val)
    );

   bsg_nonsynth_profiler_master #(.max_counters_p(1000)) profiler ();

   int foo;
   string path;
   initial
     begin
	for (foo = 0; foo < 1000; foo++)
	  begin
	     @(posedge clk);
	     profiler.dump();
	     profiler.clear();
	  end
	@(posedge clk);
	$finish;
     end
endmodule  
