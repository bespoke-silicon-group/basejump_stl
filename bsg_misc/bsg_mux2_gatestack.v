module bsg_mux2_gatestack #(width_p="inv", harden=1)
   (input [width_p-1:0] i0
    , input [width_p-1:0] i1
    , input [width_p-1:0] i2
    , output [width_p-1:0] o
    );

   genvar j;

   for (j = 0; j < width_p; j=j+1)
     begin
	assign o[j] = i2[j] ? i1[j] : i0[j];
     end

endmodule
