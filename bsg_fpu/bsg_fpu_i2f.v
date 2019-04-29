/**
 *  bsg_fpu_i2f.v
 *
 *  @author Tommy Jung
 */

module bsg_fpu_i2f
  #(parameter width_p="inv")
  (
    input [width_p-1:0] a_i
    , input signed_i
    , output logic [width_p-1:0] z_o
  );

  if (width_p == 32) begin: i2f_32

    bsg_fpu_i2f_n #(
      .e_p(8)
      ,.m_p(23)
    ) i2f_32 (
      .a_i(a_i)
      ,.signed_i(signed_i)
      ,.z_o(z_o)
    );

  end
  else if (width_p == 64) begin: i2f_64

    bsg_fpu_i2f_n #(
      .e_p(11)
      ,.m_p(52)
    ) i2f_64 (
      .a_i(a_i)
      ,.signed_i(signed_i)
      ,.z_o(z_o)
    );

  end
  else begin
    // not tested
    initial begin
      assert ("width" == "unhandled") else $error("unhandled case for %m");
    end
  end

endmodule
