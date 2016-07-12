module bsg_decode #(num_out_p=-1)
   (

    input [`BSG_SAFE_CLOG2(num_out_p)-1:0] i
    ,output [num_out_p-1:0] o

    );

   if (num_out_p == 1)
     assign o = 1'b1;
   else
     assign o = (num_out_p) ' (1'b1 << i);

endmodule
