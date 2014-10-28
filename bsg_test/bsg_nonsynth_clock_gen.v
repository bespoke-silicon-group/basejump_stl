module test_bsg_clock_gen #(parameter cycle_time_p="inv")
   (output logic o);

   initial o = 0;

   initial
     $display("%m with cycle_time_p ",cycle_time_p);

   initial
     assert(cycle_time_p >= 2)
       else $error("cannot simulate cycle time less than 2");

   always #(cycle_time_p/2)
     o = ~o;

endmodule

