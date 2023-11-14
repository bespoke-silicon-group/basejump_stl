`define bsg_mul_booth_gen_macro(name,blocks,S_above,dot_bar,b_vec,one_vec)                  \
if (   blocks == blocks_p      && S_above == S_above_vec_p                         \
    && dot_bar == dot_bar_vec_p && b_vec == B_vec_p       && one_vec == one_vec_p) \
  begin : macro                                                                    \
     name``_b``blocks b4b (.*);                             \
  end

module bsg_mul_booth_4_block_rep  #(parameter [31:0] blocks_p=1
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

   genvar i;

   wire [blocks_p:0] ci_local;

   `bsg_mul_booth_gen_macro(bsg_rp_tsmc_250_booth_4_block,5,0,0,0,0)
else `bsg_mul_booth_gen_macro(bsg_rp_tsmc_250_booth_4_block,6,0,0,0,0)
else `bsg_mul_booth_gen_macro(bsg_rp_tsmc_250_booth_4_block,7,0,0,0,0)
else `bsg_mul_booth_gen_macro(bsg_rp_tsmc_250_booth_4_block,8,0,0,0,0)
else `bsg_mul_booth_gen_macro(bsg_rp_tsmc_250_booth_4_block_cornice,8,32'b0000_1000_0000_0100_0000_0010_0000_0001,32'b0000_0000_0000_0000_0000_0000_0000_0000,32'b1000_0000_1100_1000_1110_1100_1111_1110,32'b0000_0000_0000_0000_0000_0000_0000_0000)
else `bsg_mul_booth_gen_macro(bsg_rp_tsmc_250_booth_4_block_cornice,6,24'b0000_1000_0000_0100_0000_0010,24'b0000_0000_0000_0000_0000_0000,24'b1000_0000_1100_1000_1110_1100,24'b0000_0000_0000_0000_0000_0000)
else `bsg_mul_booth_gen_macro(bsg_rp_tsmc_250_booth_4_block_end_cornice,7,28'b0000_0000_0000_0000_0000_0000_0000,28'b1000_0000_0100_0000_0010_0000_0001,28'b0111_0011_0011_0001_0001_0000_0000,28'b0000_0100_0000_0010_0000_0001_0000)
else `bsg_mul_booth_gen_macro(bsg_rp_tsmc_250_booth_4_block_end_cornice,8,32'b0000_0000_0000_0000_0000_0000_0000_0000,32'b0000_1000_0000_0100_0000_0010_0000_0001,32'b0111_0111_0011_0011_0001_0001_0000_0000,32'b1000_0000_0100_0000_0010_0000_0001_0000)
else
  // some cases are too complex to spend time on handling;
  // so we fall back to some default code.
  // warning: this code has some replication with
  // the main line bsg_mul code.
  begin: notmacro
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
   
  end


endmodule
