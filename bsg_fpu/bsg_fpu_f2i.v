/**
 *  bsg_fpu_f2i.v
 *
 *  @author Tommy Jung
 */

module bsg_fpu_f2i #( parameter width_p="inv" )
(
  input [width_p-1:0] a_i
  ,input rm_i
  ,output logic [width_p-1:0] o 
); 

  if (width_p == 32) begin
    bsg_fpu_f2i_32 f2i_32 (
      .a_i(a_i)
      ,.rm_i(rm_i)
      ,.o(o)
    );
  end
  else begin
    initial assert ("width" == "unhandled") else $error("unhandled case for %m");
  end

endmodule
