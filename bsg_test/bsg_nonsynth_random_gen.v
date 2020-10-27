/************************** DESIGN RATIONALE ***************************

This module generates a stream of random numbers with seed specified 
as a parameter. Since the value of the seed is provided as a parameter, 
each instantiation of this module produces a pre-determined stream making 
it easy to reproduce the sequence.

Next random number is generated after every clock cycle if yumi_i is
asserted. Otherwise, the previous value is retained. Also, after
every reset signal the stream of random numbers is restarted.

***********************************************************************/

`include "bsg_defines.v"

module bsg_nonsynth_random_gen 
   #(  parameter width_p = 3
     , parameter seed_p  = 100
    )
    (  input  clk_i
     , input  reset_i
     , input  yumi_i
     , output logic[width_p-1:0] data_o
    );

    
  always_ff @(posedge clk_i)
  begin
    if(reset_i)
      data_o <= $random(seed_p);
    else
      if(yumi_i)
        data_o <= $random();
  end

endmodule

