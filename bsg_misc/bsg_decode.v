/**
 *  bsg_decode.v
 *
 *  https://www.youtube.com/watch?v=RvnkAtWcKYg
 */

module bsg_decode #(parameter num_out_p="inv")
(
  input [`BSG_SAFE_CLOG2(num_out_p)-1:0] i
  ,output logic [num_out_p-1:0] o
);

  if (num_out_p == 1) begin
    // suppress unused signal warning
    wire unused = i;
    assign o = 1'b1;
  end
  else begin
    assign o = (num_out_p) ' (1'b1 << i);
  end

endmodule
