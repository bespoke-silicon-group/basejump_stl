/**
 *  bsg_fpu_cmp.v
 *
 *  @author Tommy Jung
 */

module bsg_fpu_cmp #(parameter width_p="inv")
  ( input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , input [1:0] subop_i
    , output logic o
    , output logic invalid_o
    );

  if (width_p == 32)
    begin
      bsg_fpu_cmp_32 cmp32 (
        .a_i(a_i)
        ,.b_i(b_i)
        ,.subop_i(subop_i)
        ,.o(o)
        ,.invalid_o(invalid_o)
        );
    end
  else initial assert ("width" == "unhandled") else $error("unhandled case for %m");

endmodule
