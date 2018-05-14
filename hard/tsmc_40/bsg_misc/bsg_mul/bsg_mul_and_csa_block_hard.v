`define bsg_mul_and_csa_gen_macro(blocks)                                              \
if (   blocks == blocks_p )             \
  begin : macro                                                                    \
     bsg_rp_tsmc_40_and_csa_block_b``blocks b4b (.*);                             \
  end

module bsg_mul_and_csa_block_hard #(parameter [31:0] blocks_p=1
                                )
   ( input [blocks_p-1:0] x_i
     , input [blocks_p-1:0] y_i
     , input [blocks_p-1:0] z_and1_i
     , input [blocks_p-1:0] z_and2_i
     , output [blocks_p-1:0] c_o
     , output [blocks_p-1:0] s_o
     );

   `bsg_mul_and_csa_gen_macro(5)
else `bsg_mul_and_csa_gen_macro(6)
else `bsg_mul_and_csa_gen_macro(7)
else `bsg_mul_and_csa_gen_macro(8)
   else initial assert(blocks_p==-1) else $error("unhandled case %m");
endmodule
