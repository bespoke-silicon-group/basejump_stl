`include "bsg_defines.v"

module bsg_clkbuf #(parameter width_p=1
		    , parameter strength_p=8
                    , parameter harden_p=1
                    )
   (input    [width_p-1:0] i
    , output [width_p-1:0] o
    );
   
   assign o = i;

endmodule
