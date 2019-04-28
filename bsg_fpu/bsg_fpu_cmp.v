/**
 *  bsg_fpu_cmp.v
 *
 *  @author Tommy Jung
 */

module bsg_fpu_cmp
  #(parameter width_p="inv")
  ( 
    input [width_p-1:0] a_i
    , input [width_p-1:0] b_i
    , output logic invalid_o
  );

  if (width_p == 32) begin: cmp32
    bsg_fpu_cmp #(
      
    ) cmp (
      .a_i(a_i)
      ,.b_i(b_i)
      ,.invalid_o(invalid_o)
    );
  end
  else begin
    initial begin
      assert ("width" == "unhandled") else $error("unhandled case for %m");
    end
  end

endmodule
