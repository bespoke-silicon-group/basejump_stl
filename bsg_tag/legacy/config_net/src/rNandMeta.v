// The nand gate array that performs nand operation on corresponding input bits.
`include "bsg_defines.v"

module rNandMeta
  #(parameter width_p = -1)
   (input  [width_p - 1 : 0] data_a_i,
    input  [width_p - 1 : 0] data_b_i,

    output [width_p - 1 : 0] nand_o
   );

  genvar i;
  generate
    for(i = 0; i < width_p; i++) begin
      GTECH_NAND2 rNandMeta_U (.A(data_a_i[i]), .B(data_b_i[i]), .Z(nand_o[i]));
    end
  endgenerate

endmodule
