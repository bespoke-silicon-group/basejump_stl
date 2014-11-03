// MBT 10-29-14
//
// implements a shift register of fixed latency
//
//

module bsg_shift_reg #(parameter width_p = "inv"
                       , parameter stages_p = "inv"
                       )
   (input clk
    , input reset_i
    , input valid_i
    , input [width_p-1:0] data_i
    , output valid_o
    , output [width_p-1:0] data_o
    );

   logic [stages_p-1:0][width_p+1-1:0] shift_r;

   always_ff @(posedge clk)
     if (reset_i)
       shift_r <= '0;
     else
       begin
	  shift_r[stages_p-1:1] <= shift_r[stages_p-2:0];
	  shift_r[0] <= { valid_i, data_i };
       end
   assign { valid_o, data_o } = shift_r[stages_p-1];

endmodule
