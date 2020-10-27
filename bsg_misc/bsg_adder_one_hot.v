// bsg_adder_one_hot
//
// adder whose inputs and outputs are all one hot signals
//
// the adder is by default a modulo adder, so it will wrap around
// if there is a carry out.
//
// if you don't want modulo, then make the output signal wide enough; i.e. set output_width_p>=2*width_p-1
//

`include "bsg_defines.v"

module bsg_adder_one_hot #(parameter width_p=-1, parameter output_width_p=width_p)
   (input    [width_p-1:0] a_i
    , input  [width_p-1:0] b_i
    , output [output_width_p-1:0] o
    );

   genvar i,j;

   initial assert (output_width_p >= width_p)
     else begin $error("%m: unsupported output_width_p < width_p");
	$finish();
     end

   for (i=0; i < output_width_p; i++) // for each output wire
     begin: rof
	wire [width_p-1:0] aggregate;

	// for each input a_i
	// compute what bit is necessary to make it total to i
	// including wrap around in the modulo case
	
	for (j=0; j < width_p; j=j+1)
	  begin: rof2
	     if (i < j)
	       begin: rof3
		  if (output_width_p+i-j < width_p)
		    assign aggregate[j] = a_i[j] & b_i[output_width_p+i-j];
		  else
		    assign aggregate[j] = 1'b0;
	       end
	     else
	       if (i-j < width_p)
		 assign aggregate[j] = a_i[j] & b_i[i-j];
	       else
		 assign aggregate[j] = 1'b0;
	  end // block: rof2

	assign o[i] = | aggregate;

     end // block: rof

endmodule
