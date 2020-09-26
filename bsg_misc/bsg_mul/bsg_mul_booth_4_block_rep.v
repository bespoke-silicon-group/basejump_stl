`include "bsg_defines.v"

module bsg_mul_booth_4_block_rep #(parameter [31:0] blocks_p=1
                                   ,parameter S_above_vec_p=0
                                   ,parameter dot_bar_vec_p=0
                                   ,parameter B_vec_p=0
                                   ,parameter one_vec_p=0
                                   )
   ( input [4:0][2:0] SDN_i
     , input                 cr_i
     , input [blocks_p-1:0][3:0][1:0]  y_vec_i
     , output                cl_o
     , output [blocks_p-1:0] c_o
     , output [blocks_p-1:0] s_o
     );

   wire [blocks_p:0] ci_local;

   genvar i;

        for (i = 0; i < blocks_p; i=i+1)
          begin: rof
             localparam S_above_vec_tmp   = (S_above_vec_p >> (i << 2)) & 4'hf;
             localparam S_dot_bar_vec_tmp = (dot_bar_vec_p >> (i << 2)) & 4'hf;
             localparam B_vec_tmp         = (B_vec_p       >> (i << 2)) & 4'hf;
             localparam one_vec_tmp       = (one_vec_p     >> (i << 2)) & 4'hf;

             bsg_mul_booth_4_block #(
                             .S_above_vec_p(S_above_vec_tmp)
                             ,.dot_bar_vec_p(S_dot_bar_vec_tmp)
                             ,.B_vec_p(B_vec_tmp)
                             ,.one_vec_p(one_vec_tmp)
                             )
             b4b (.SDN_i(SDN_i), .y_i (y_vec_i[i])
                  , .cr_i(ci_local[i]), .cl_o(ci_local[i+1]), .c_o (c_o[i]), .s_o (s_o[i]));
          end // block: rof


   assign ci_local[0] = cr_i;
   assign cl_o = ci_local[blocks_p];

endmodule // bsg_mul_booth_4_block_rep

