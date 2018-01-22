module bsg_muxi2_gatestack #(width_p="inv", harden_p=1)
   (input [width_p-1:0] i0
    , input [width_p-1:0] i1
    , input [width_p-1:0] i2
    , output [width_p-1:0] o
    );

   initial $display("%m: warning module not actually hardened.");

   genvar j;

   for (j = 0; j < width_p; j=j+1)
     begin
	assign o[j] = ~(i2[j] ? i1[j] : i0[j]);
     end

endmodule
