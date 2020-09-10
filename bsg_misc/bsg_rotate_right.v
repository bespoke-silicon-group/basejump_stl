`include "bsg_defines.v"

module bsg_rotate_right #(width_p=-1)
   (input [width_p-1:0] data_i
    , input [`BSG_SAFE_CLOG2(width_p)-1:0] rot_i
    , output [width_p-1:0] o
    );
   
   wire [width_p*2-1:0] temp = { 2 { data_i } } >> rot_i;
   assign o = temp[0+:width_p];
   
endmodule