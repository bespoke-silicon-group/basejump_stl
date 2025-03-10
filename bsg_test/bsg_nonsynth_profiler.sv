// bsg_nonsynth_profiler

// This module is a easy-to-use generalized event counting profiling infrastructure.

// There are two modules, a master module (bsg_nonsynth_profiler_master) and a client module (bsg_nonsynth_profiler_client).
//
// The master module contains all of the counters.
// The user's testbench will bind the client modules to the target instances or modules.
//
// At initialization time, the client module will register itself with the master module and allocate a counter.
// At CLOCK NEGEDGE, the client bound module (bsg_nonsynth_profiler_client) will use its input signal to conditionally increment the counter.
//
// The user's testbench is responsible for calling into the master module for periodically dumping and clearing the counters on the CLOCK POSEDGE of the clock.
//
// The master module will write out the files when the simulator calls $finish.
//
// The generated files are profile.name and profile.dat.
//
//
// The user can generate one or more profile.schema files that tells the post-processor program how to format the data for display.
// For this purpose, the user can use the program bsg_nonsynth_profiler_analyzer.py
//
// See the example in testing/bsg_test/bsg_nonsynth_profiler, including the profile.schema file that was used.

// set this macro to define the name of the top-level module
`ifndef BSG_NONSYNTH_PROFILER_CLIENT_TOP
`define BSG_NONSYNTH_PROFILER_CLIENT_TOP testbench
`endif

module bsg_nonsynth_profiler_client_inc #(string suffix_p="")
   (input clk_i
    ,input countme_i
    );
   
   string path;

   int 	  counter;
   
   initial
     begin
	$sformat(path,"%m%s",suffix_p);
	$root.`BSG_NONSYNTH_PROFILER_CLIENT_TOP.profiler.allocate_counter(path,counter);
     end

   always @(negedge clk_i)
     begin
	if (countme_i)
	  $root.`BSG_NONSYNTH_PROFILER_CLIENT_TOP.profiler.increment_counter(counter);
     end

endmodule

module bsg_nonsynth_profiler_client_add #(string suffix_p="")
   (input clk_i
    ,input [31:0] countme_i
    );
   
   string path;

   int 	  counter;
   
   initial
     begin
	$sformat(path,"%m%s",suffix_p);
	$root.`BSG_NONSYNTH_PROFILER_CLIENT_TOP.profiler.allocate_counter(path,counter);
     end

   always @(negedge clk_i)
     begin
	$root.`BSG_NONSYNTH_PROFILER_CLIENT_TOP.profiler.add_counter(counter,countme_i);
     end

endmodule


module bsg_nonsynth_profiler_master #(parameter max_counters_p=0)
   ();

   semaphore sem = new(1);

   int   fd = 0;
   int counter_limit = 0;
   int counters [max_counters_p-1:0];
   
   string counter_name[] = new[max_counters_p];	

   int counter;

   task increment_counter(int counter);
     counters[counter] = counters[counter]+1;
   endtask

   task add_counter(int counter, int val);
     counters[counter] = counters[counter]+val;
   endtask

   
   task allocate_counter(string name, output int counter);
     begin
	sem.get(1);
	if (counter_limit < max_counters_p)
	  begin
	     counter = counter_limit;
	     counters[counter_limit] = 0;
	     counter_name[counter_limit] = name;
	     counter_limit = counter_limit + 1;
	     sem.put(1);
	     return;
	  end
	else
	  begin
	     $error("(%m): not enough counters allocated");
	     counter = 0;
	     sem.put(1);
	     return;
	  end
     end
   endtask

   initial
     begin
	fd=$fopen("profile.dat","w");
     end

   // other modules can use this to dump the stats	
   task dump();
      begin
	 for (int i = 0; i < counter_limit; i++)
	   begin
	      $fwrite(fd,"%u",counters[i]);
	   end
     end
   endtask

// other modules can use this to clear the stats (often after a dump)		
   task clear();
    begin
       for (int i = 0; i < counter_limit; i++)
	 counters[i]=0;
    end
  endtask
   
   final
     begin
	dump();
	if (fd != 0)
	  $fclose(fd);
	fd = $fopen("profile.name","w");
	for (int i = 0; i < counter_limit; i++)
	  $fwrite(fd,"%d %s\n",i,counter_name[i]);
	$fclose(fd);
     end
   
endmodule
