module bsg_dff_en_reset #(width_p=-1)
   (input   clock_i
    ,input  [width_p-1:0] data_i
    ,input  en_i
    ,input  reset_i
    ,output [width_p-1:0] data_o
    );

   reg [width_p-1:0] data_r;

   assign data_o = data_r;

   always @(posedge clock_i)
     begin
	if (reset_i)
	  data_r <= width_p'(0);
	else
	  if (en_i)
	    data_r <= data_i;
     end



endmodule
