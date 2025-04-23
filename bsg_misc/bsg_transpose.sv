`include "bsg_defines.sv"

module bsg_transpose #(`BSG_INV_PARAM(width_p)
		       ,`BSG_INV_PARAM(els_p)
		       , type_width_p=1
		      ) (input    [els_p-1:0  ][width_p-1:0][type_width_p-1:0] i
			 , output [width_p-1:0][els_p-1:0][type_width_p-1:0]   o
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

`BSG_ABSTRACT_MODULE(bsg_transpose)
