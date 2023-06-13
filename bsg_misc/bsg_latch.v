/**
 *    bsg_latch.sv
 *
 */

module bsg_latch
  (
    input clk_i
    , input data_i
    , output logic data_o
  );

  logic data_r;
  
  always_latch
    if (clk_i)
      data_r <= data_i;

  // Version 4.213 of Verilator doesn't detect latches
  //   for data_o merged with data_r
  assign data_o = data_r;
  
endmodule
