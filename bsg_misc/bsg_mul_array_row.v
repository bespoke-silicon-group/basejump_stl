/**
 *  bsg_mul_array_row.v
 *
 *  @author Tommy Jung
 */

module bsg_mul_array_row #(parameter width_p="inv"
                          , parameter row_idx_p="inv")
  ( input [width_p-1:0] a_i
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

  assign a_o = a_i;
  assign b_o = b_i;
  assign s_o = ps;
  assign c_o = pc;
  assign prod_accum_o = {ps[0], prod_accum_i};
  
endmodule
