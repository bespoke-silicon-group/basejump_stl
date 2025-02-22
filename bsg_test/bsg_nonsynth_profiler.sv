// bsg_nonsynth_profiler

// This module is a easy-to-use generalized event counting profiling infrastructure

// There are two modules, a master module and a client module.
// The master module contains all of the counters.
// At initialization time, the client module will register itself with the master module and allocate a counter.
// The client module will monitor a signal in the master module that says when to start and stop profiling
// The master module has logic for periodically dumping and reseting the counters
// The master module has a single that will cause it to dump the remaining data, and dump the directory of counters

module bsg_nonsynth_profile_client #(string suffix_p="")
   (input clk_i
    ,input reset_i
    ,input countme_i
    );
   
   string path;

   int 	  counter;
   
   initial
     begin
	@(posedge clk_i);
	@(negedge reset_i);
	$sformat(path,"%m%s",suffix_p);
	$root.testbench.profiler.allocate_counter(path,counter);
     end

   always @(negedge clk_i)
     begin
	if ((reset_i===0) && countme_i)
	  $root.testbench.profiler.increment_counter(counter);
     end

endmodule

module bsg_nonsynth_profile_master #(parameter max_counters_p=0)

  (input clk_i
   ,input reset_i
   );

   semaphore sem = new(1);

   int   fd = 0;
   int counter_limit = 0;
   int counters [max_counters_p-1:0];
   
   string counter_name[];   

   int counter;

   task increment_counter(int counter);
     counters[counter] = counters[counter]+1;
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
	int counter;
	
	fd=$fopen("profile.dat","w");
	counter_name = new[max_counters_p];	
	allocate_counter("invalid", counter);
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
