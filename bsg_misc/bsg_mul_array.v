/**
 *	bsg_mul_array.v
 *	pipelined unsigned array multiplier.
 *  @param width_p width of inputs
 *  @param pipeline_p binary vector that is (width_p-1) wide.
 *    There are width_p-1 rows of ripple carry adders.
 *    Having 1 in this binary vector means that that row is pipelined.
 *	@author Tommy Jung
 */

`include "bsg_defines.v"

module bsg_mul_array #(parameter width_p="inv", pipeline_p="inv")
  (
    input clk_i
    ,	input rst_i
    , input v_i
    , input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , output logic [(width_p*2)-1:0] o
  );

  // connections between rows
  logic [width_p-1:0] a_r [width_p-3:0];
  logic [width_p-1:0] b_r [width_p-3:0];
  logic [width_p-1:0] s_r [width_p-2:0];
  logic c_r [width_p-2:0];
  logic [width_p-1:0] prod_accum [width_p-2:0];

  // first partial product
  logic [width_p-1:0] pp0;
  bsg_and #(.width_p(width_p)) and0 (
    .a_i(a_i)
    , .b_i({width_p{b_i[0]}})
    , .o(pp0)
    );

  genvar i; 
  for (i = 0; i < width_p-1; i++) begin
    if (i == 0) begin
      bsg_mul_array_row #(.width_p(width_p), .row_idx_p(i), .pipeline_p(pipeline_p[i]))
        first_row (
        .clk_i(clk_i)
        ,.rst_i(rst_i)
        ,.v_i(v_i)
        ,.a_i(a_i)
        ,.b_i(b_i)
        ,.s_i(pp0)
        ,.c_i(1'b0)
        ,.prod_accum_i(pp0[0])
        ,.a_o(a_r[i])
        ,.b_o(b_r[i])
        ,.s_o(s_r[i])
        ,.c_o(c_r[i])
        ,.prod_accum_o(prod_accum[i][i+1:0])
      );
    end
    else if (i == width_p-2) begin
      bsg_mul_array_row #(.width_p(width_p), .row_idx_p(i), .pipeline_p(pipeline_p[i]))
        last_row (
        .clk_i(clk_i)
        ,.rst_i(rst_i)
        ,.v_i(v_i)
        ,.a_i(a_r[i-1])
        ,.b_i(b_r[i-1])
        ,.s_i(s_r[i-1])
        ,.c_i(c_r[i-1])
        ,.prod_accum_i(prod_accum[i-1][i:0])
        ,.a_o() // no need to connect
        ,.b_o() // no need to connect
        ,.s_o(s_r[i])
        ,.c_o(c_r[i])
        ,.prod_accum_o(prod_accum[i])
      );
    end
    else begin
      bsg_mul_array_row #(.width_p(width_p), .row_idx_p(i), .pipeline_p(pipeline_p[i]))
        mid_row (
        .clk_i(clk_i)
        ,.rst_i(rst_i)
        ,.v_i(v_i)
        ,.a_i(a_r[i-1])
        ,.b_i(b_r[i-1])
        ,.s_i(s_r[i-1])
        ,.c_i(c_r[i-1])
        ,.prod_accum_i(prod_accum[i-1][i:0])
        ,.a_o(a_r[i])
        ,.b_o(b_r[i])
        ,.s_o(s_r[i])
        ,.c_o(c_r[i])
        ,.prod_accum_o(prod_accum[i][i+1:0])
      );
    end
  end

  assign o[(2*width_p)-1] = c_r[width_p-2];
  assign o[(2*width_p)-2:width_p-1] = s_r[width_p-2];
  assign o[width_p-2:0] = prod_accum[width_p-2][width_p-2:0];

endmodule
