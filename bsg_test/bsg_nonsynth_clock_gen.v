// we use bit for the output so that it starts at 0
// this helps with x prop mode in VCS

module bsg_nonsynth_clock_gen #(parameter cycle_time_p="inv")
   (output bit o);

   initial
     $display("%m with cycle_time_p ",cycle_time_p);

   initial
     assert(cycle_time_p >= 2)
       else $error("cannot simulate cycle time less than 2");

   always #(cycle_time_p/2.0)
     o = ~o;

endmodule

