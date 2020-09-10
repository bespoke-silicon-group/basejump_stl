
// PP_i[210] = { S D N }
`include "bsg_defines.v"

module bsg_mul_booth_4_block #(
                        S_above_vec_p  = 4'b0000
                       , dot_bar_vec_p = 4'b0000
                       , B_vec_p       = 4'b0000
                       , one_vec_p     = 4'b0000)
   ( input [4:0][2:0] SDN_i // SDN_i[0] is the SDN before this row. used for S_above_vec_p.
     , input cr_i
     , input [3:0][1:0] y_i
     , output cl_o
     , output c_o
     , output s_o
     );

   wire [3:0] dot_vals;

   genvar     i;

   for (i = 0; i < 4; i=i+1)
     begin: rof
          if (S_above_vec_p[i])
            assign dot_vals[i] = SDN_i[i][0];
          else
          if (dot_bar_vec_p[i])
            assign dot_vals[i] = ~bsg_mul_booth_dot(SDN_i[i+1],y_i[i][1],y_i[i][0]);
          else
            if (B_vec_p[i])
              assign dot_vals[i] = 1'b0;
            else
              if (one_vec_p[i])
                assign dot_vals[i] = 1'b1;
              else
                assign dot_vals[i] = bsg_mul_booth_dot(SDN_i[i+1],y_i[i][1],y_i[i][0]);

     end // block: rof

   bsg_mul_comp42 c (.i(dot_vals), .cr_i(cr_i), .cl_o(cl_o), .c_o(c_o), .s_o(s_o));

endmodule // bsg_mul_booth_4_block
