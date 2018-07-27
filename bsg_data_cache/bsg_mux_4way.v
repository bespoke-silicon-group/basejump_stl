module bsg_mux_4way (
  input [31:0] el0_i
  ,input [31:0] el1_i
  ,input [3:0] sel_i
  ,output logic [31:0] o
);

  assign o[7:0] = sel_i[0] ? el1_i[7:0] : el0_i[7:0];
  assign o[15:8] = sel_i[1] ? el1_i[15:8] : el0_i[15:8];
  assign o[23:16] = sel_i[2] ? el1_i[23:16] : el0_i[23:16];
  assign o[31:24] = sel_i[3] ? el1_i[31:24] : el0_i[31:24];

endmodule
  
