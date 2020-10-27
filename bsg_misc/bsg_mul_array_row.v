/**
 *  bsg_mul_array_row.v
 *
 *  @author Tommy Jung
 */

`include "bsg_defines.v"

module bsg_mul_array_row #(parameter width_p="inv"
                          , parameter row_idx_p="inv"
                          , parameter pipeline_p="inv")
  ( 
    input clk_i
    , input rst_i
    , input v_i
    , input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , input [width_p-1:0] s_i
    , input c_i
    , input [row_idx_p:0] prod_accum_i
    , output logic [width_p-1:0] a_o
    , output logic [width_p-1:0] b_o
    , output logic [width_p-1:0] s_o
    , output logic c_o
    , output logic [row_idx_p+1:0] prod_accum_o 
  );

  // partial product
  logic [width_p-1:0] pp;
  logic [width_p-1:0] ps;
  logic pc;
  bsg_and #(.width_p(width_p)) and0 (
    .a_i(a_i)
    ,.b_i({width_p{b_i[row_idx_p+1]}})
    ,.o(pp)
    );
  
  bsg_adder_ripple_carry #(.width_p(width_p)) adder0 (
    .a_i(pp)
    ,.b_i({c_i, s_i[width_p-1:1]})
    ,.s_o(ps)
    ,.c_o(pc)
    );

  // pipeline registers
  logic [width_p-1:0] a_r;
  logic [width_p-1:0] b_r;
  logic [width_p-1:0] s_r;
  logic c_r;
  logic [row_idx_p+1:0] prod_accum_r;
  
  
  // pipeline next values
  logic [width_p-1:0] a_n;
  logic [width_p-1:0] b_n;
  logic [width_p-1:0] s_n;
  logic c_n;
  logic [row_idx_p+1:0] prod_accum_n;

  if (pipeline_p) begin
    always_ff @ (posedge clk_i) begin
      if (rst_i) begin
        a_r <= 0;
        b_r <= 0;
        s_r <= 0;
        c_r <= 0;
        prod_accum_r <= 0;
      end
      else begin
        a_r <= a_n;
        b_r <= b_n;
        s_r <= s_n;
        c_r <= c_n;
        prod_accum_r <= prod_accum_n;
      end
    end

    always_comb begin
      if (v_i) begin
        a_n = a_i;
        b_n = b_i;
        s_n = ps;
        c_n = pc;
        prod_accum_n = {ps[0], prod_accum_i};
      end
      else begin
        a_n = a_r;
        b_n = b_r;
        s_n = s_r;
        c_n = c_r;
        prod_accum_n = prod_accum_r;
      end

      a_o = a_r;
      b_o = b_r;
      s_o = s_r;
      c_o = c_r;
      prod_accum_o = prod_accum_r;
    end
  end
  else begin
    always_comb begin
      a_o = a_i;
      b_o = b_i;
      s_o = ps;
      c_o = pc;
      prod_accum_o = {ps[0], prod_accum_i};
    end
  end
  
endmodule
