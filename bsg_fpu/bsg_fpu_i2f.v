/**
 *  bsg_fpu_i2f.v
 *
 *  @author Tommy Jung
 */

module bsg_fpu_i2f #( parameter width_p="inv" ) (
  input [width_p-1:0] a_i
  ,output logic [width_p-1:0] o
);

  if (width_p == 32) begin
    bsg_fpu_i2f_32 i2f_32 (
      .a_i(a_i)
      ,.o(o)
    );
  end
  else begin
    initial assert ("width" == "unhandled") else $error("unhandled case for %m");
  end

endmodule
