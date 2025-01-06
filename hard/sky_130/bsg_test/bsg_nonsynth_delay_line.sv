`include "bsg_defines.sv"

module bsg_nonsynth_delay_line # (parameter width_p=1
				  ,parameter delay_p = 1)

   (input  [width_p-1:0]   i
    , output logic [width_p-1:0] o
    );

   always @(i)
     o <=  #(delay_p) i;

endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_delay_line)
