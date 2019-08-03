// This module is used for PPA comparison
module mul(
  input [31:0] a_i
  ,input [31:0] b_i 
  ,output [63:0] o
);
  assign o = a_i * b_i;
endmodule
