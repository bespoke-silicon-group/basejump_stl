// we use bit for the output so that it starts at 0
// this helps with x prop mode in VCS
`include "bsg_defines.v"

`timescale 1ps/1ps

module bsg_nonsynth_clock_gen
  #(parameter cycle_time_p="inv")
   (output bit o);

`ifndef VERILATOR
  initial begin
    $display("%m with cycle_time_p ",cycle_time_p);
    assert(cycle_time_p >= 2)
       else $error("cannot simulate cycle time less than 2");
  end
  
  always #(cycle_time_p/2.0) begin
    o = ~o;
  end
`else
  initial begin
    $error("bsg_nonsynth_clock_gen is not supported in Verilator due to delay statement (#)");
  end
`endif

endmodule

