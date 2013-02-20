// The nand gate array that performs nand operation on corresponding input bits.
module rNandMeta
  #(parameter width_p = -1)
   (input  [width_p - 1 : 0] data_a_i,
    input  [width_p - 1 : 0] data_b_i,

    output [width_p - 1 : 0] nand_o
   );

   assign nand_o = ~ (data_a_i & data_b_i);

endmodule
