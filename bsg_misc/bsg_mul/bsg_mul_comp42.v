

`include "bsg_defines.v"

module bsg_mul_comp42
   ( input [3:0] i  // 0-2: early; 3: middle
     , input cr_i   // middle
     , output cl_o  // middle
     , output c_o   // late
     , output s_o   // late
     );

   wire           tmp;

   bsg_mul_csa csa_1 (.x_i(i[0]), .y_i(i[1]), .z_i(i[2]), .c_o(cl_o), .s_o(tmp));
   bsg_mul_csa csa_2 (.x_i(i[3]), .y_i(tmp ), .z_i(cr_i), .c_o(c_o ), .s_o(s_o));

endmodule
