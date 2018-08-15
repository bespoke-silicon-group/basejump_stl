/**
 *  bsg_decode_with_v.v
 */

module bsg_decode_with_v #(parameter num_out_p="inv")
(
  input [`BSG_SAFE_CLOG2(num_out_p)-1:0] i
  ,input v_i
  ,output logic [num_out_p-1:0] o
);

  logic [num_out_p-1:0] lo;

  bsg_decode #(
    .num_out_p(num_out_p)
  ) decoder (
    .i(i)
    ,.o(lo)
  );

  assign o = {(num_out_p){v}} & lo;

endmodule
