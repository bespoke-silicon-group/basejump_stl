/**
 *    bsg_latch.v
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

  assign data_o = data_r;
  
endmodule
