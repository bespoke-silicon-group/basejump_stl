// calculates integer modulo, in an unrolled fashion
// allows you to specify a maximum and minimum width
// for the denominator, which reduces the number of stages
// and the amount of storage required.

module bsg_imod_range #(parameter numer_width_p
			,parameter denom_max_width_p
			,parameter denom_min_width_p
			// TODO: these are a bit vector that indicate where we want pipeline stages
			// you can separately choose whether to pipeline the denominator, in some
			// cases it maybe unchanging.
			,parameter pipeline_p=0
			,parameter pipeline_denom_p=pipeline_p
			)
   (input   [numer_width_p-1:0]      numer_i
    ,input  [denom_max_width_p-1:0] denom_i
    ,output [denom_max_width_p-1:0] o
    );
   
   localparam iters_p = numer_width_p-denom_min_width_p+1;
   
   // need an extra bit so we can exceed the devisor by 1 extra bit
   logic [iters_p:0][denom_max_width_p-1+1:0] remainder;

   if (denom_min_width_p > 0)
     assign remainder[0][denom_min_width_p-1:0]                 = numer_i[numer_width_p-1:numer_width_p-denom_min_width_p];

   if (denom_max_width_p > denom_min_width_p)
     assign remainder[0][denom_max_width_p-1:denom_min_width_p] = '0;

   assign remainder[0][denom_max_width_p] = '0;

   logic [iters_p-1:0] 			      too_small;

   logic [iters_p-1:0] [denom_max_width_p:0]  difference;   
generate
   genvar i;

   for (i = 0; i < iters_p; i++)
     begin: stage

	assign difference[i] = remainder[i] - denom_i;

	// if we have a carry bit coming out, we have underflow
	assign too_small[i] = difference[i][denom_max_width_p];

	if (i != iters_p-1)
	  begin
	     assign remainder[i+1][0] = numer_i[iters_p-i-1-1];
	     assign remainder[i+1][denom_max_width_p:1] = too_small[i] ? remainder[i][denom_max_width_p-1:0] : difference[i][denom_max_width_p-1:0];
	  end
	else
	  assign remainder[i+1][denom_max_width_p-1:0] = too_small[i] ?  remainder[i][denom_max_width_p-1:0] : difference[i][denom_max_width_p-1:0];
     end

   assign o = remainder[iters_p][denom_max_width_p-1:0];
   
endgenerate

endmodule
