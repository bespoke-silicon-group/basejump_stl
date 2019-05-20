/*
======================
bsg_div_srt.v
04/16/2019 sqlin16@fudan.edu.cn
=====================
A radix-4 SRT divider using carry save addition to store intermittent remainder.
Design doc: https://docs.google.com/document/d/10YhNfc81pXje2fKQs5IgFZxHONHRqtQdeLGdTJkAAZU/edit?usp=sharing

Latency = 8 + (width_p / 2) (cycle)
Throughput = 1 / (9 + (width_p / 2)) (cycle^-1)

*/

module bsg_div_srt #(
  parameter integer width_p = "inv"
  ,parameter bit debug_p = 0
)(

  input clk_i
  ,input reset_i
  
  //handshake signal
  ,output ready_o
  ,input v_i

  ,input [2*width_p-1:0] dividend_i
  ,input [width_p-1:0] divisor_i
  ,input signed_i

  ,output [width_p-1:0] quotient_o
  ,output [width_p-1:0] remainder_o

  ,output v_o

  ,output error_o
  ,output error_type_o // 0: divisor is zero, 1: result is overflow

  ,input yumi_i       // accept result.
  ,input yumi_error_i // accept error.
);

typedef enum [2:0] {eIDLE, eALIGN, eSHIFT, eDONE, eERROR} state_e;


endmodule

