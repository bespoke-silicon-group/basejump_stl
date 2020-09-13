// Hypotenuse
//
// Computes sqrt(x^2+y^2) using fixed point arithmetic.
//
// It is pipelined to do one iteration per cycle,
// and the final multiply is done in one cycle.
// fixme: allow configuration of pipelining.
// clearly this is fairly unbalanced.
//
// Roger Huang (UCSD)
// Michael Taylor
//
// 10/29/14
//

`include "bsg_defines.v"

module cordic_stage #(parameter   stage_p = 1
                      , parameter width_p = 12)
   (
    input clk
    ,input  [width_p+7:0] x
    ,input  [width_p+7:0] y
    ,output [width_p+7:0] x_n
    ,output [width_p+7:0] y_n
    );

   wire [width_p+7:0] x_shift = x          >>> stage_p;
   wire [width_p+7:0] y_shift = $signed(y) >>> stage_p;

   assign x_n = (y[width_p+7]) ? (x - y_shift) : (x +  y_shift);
   assign y_n = (y[width_p+7]) ? (y + x_shift) : (y -  x_shift);

endmodule

module bsg_hypotenuse #(parameter width_p = 12)
   (
    input clk
    ,input [width_p-1:0] x_i
    ,input [width_p-1:0] y_i
    ,output [width_p:0] o
    );

   logic [width_p-1:0] x_set, y_set;
   logic [width_p+7:0] ans_next;
   logic [width_p+7:0] x [width_p+1:0];
   logic [width_p+7:0] y [width_p+1:0];
   logic [width_p+7:0] x_ans [width_p:0];
   logic [width_p+7:0] y_ans [width_p:0];

   initial assert (width_p == 12)
     else $error("warning this module has not been tested for width_p != 12");

   // final_addition = 19 bit representation of 6'b100001
   localparam final_add_lp = 19'b100001;

   wire switch = (x_i < y_i);

   assign x_set = ( switch ) ? y_i : x_i;
   assign y_set = ( switch ) ? x_i : y_i;

   always_ff @(posedge clk) begin
      x[0] <= {1'd0, x_set, 6'd0};
      y[0] <= {1'd0, y_set, 6'd0};
   end

   genvar i;
   generate
      for(i = 0; i <= width_p ; i=i+1)
        begin : stage
           cordic_stage #(.stage_p(i)) cs
              (.clk(clk)
               ,.x(x[i])
               ,.y(y[i])
               ,.x_n(x_ans[i])
               ,.y_n(y_ans[i])
               );

           always_ff @(posedge clk)
             begin
                x[i+1] <= x_ans[i];
                y[i+1] <= y_ans[i];
             end
        end

   endgenerate

   logic [width_p+18:0] scaling_ans_r, ans_n;

   // multiply by scaling factor scaling factor = 12'b100110110111

   always_ff @(posedge clk)
     scaling_ans_r <= x[13] * 12'b100110110111;

   assign ans_n = scaling_ans_r[30:12] + final_add_lp;

   logic [width_p:0]    ans_r;

   always_ff @(posedge clk)
     ans_r <= ans_n[18:6];

   assign o = ans_r;

endmodule

