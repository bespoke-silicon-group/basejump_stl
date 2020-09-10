`include "bsg_defines.v"

module bsg_transpose #(width_p="inv"
		       ,els_p="inv"
		       ) (input    [els_p-1:0  ][width_p-1:0] i
			  , output [width_p-1:0][els_p-1:0]   o
			  );
   genvar x, y;

   for (x = 0; x < els_p; x++)
     begin: rof
	for (y = 0; y < width_p; y++)
	  begin: rof2
	     assign o[y][x] = i[x][y];
	  end
     end
    
endmodule
