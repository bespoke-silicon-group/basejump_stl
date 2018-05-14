`define bsg_mul_comp42_gen_macro(blocks) \
if (   blocks == blocks_p )                                                       \
  begin : macro                                                                   \
     bsg_rp_tsmc_40_comp42_block_b``blocks c42 (.*);                             \
  end


module bsg_mul_comp42_rep #(parameter blocks_p="inv")
   (input [3:0][blocks_p-1:0] i
    ,input cr_i
    ,output cl_o
    ,output [blocks_p-1:0] c_o
    ,output [blocks_p-1:0] s_o
    );

   `bsg_mul_comp42_gen_macro(5)
else `bsg_mul_comp42_gen_macro(6)
else `bsg_mul_comp42_gen_macro(7)
else `bsg_mul_comp42_gen_macro(8)
else
  initial assert(blocks_p==-1) else $error("all case should be handled by this module %m");

endmodule
